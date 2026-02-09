@IsTest
private class HOT_WageClaimServiceTest {
    
    @testSetup
    static void setup() {
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' OR Name = 'Standardbruker' LIMIT 1];

        User user = HOT_TestDataFactory.createUser('user1', profile);
        insert user;

        ServiceResource resource = HOT_TestDataFactory.createServiceResource(user.Id);
        resource.HOT_IsFreelanceInterpreter__c = true;
        insert resource;

        User user2 = HOT_TestDataFactory.createUser('user2', profile);
        insert user2;

        ServiceResource resource2 = HOT_TestDataFactory.createServiceResource(user2.Id);
        insert resource2;

        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;

        // Optimalisering: Hvis factory tillater det, sett status før insert for å spare en update
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        request.Status__c = 'Godkjent'; 
        insert request;
        // update request; <-- Fjernet denne hvis vi kan sette status ved opprettelse, ellers må den være der.

        Id serviceAppointmentId = [SELECT Id FROM ServiceAppointment LIMIT 1].Id;
        Id serviceResourceId = [SELECT Id FROM ServiceResource WHERE RelatedRecordId = :user.Id LIMIT 1].Id;

        // 1. Opprett AssignedResource FØR vi begynner å oppdatere SA
        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(
            serviceAppointmentId,
            serviceResourceId
        );
        insert assignedResource;

        // 2. SAMLE alle oppdateringer på ServiceAppointment i én operasjon
        // Dette sparer minst 1 hel kjøring av SA-triggerne
        Datetime startDt = System.now().addHours(24);
        Datetime endDt = startDt.addHours(2);

        ServiceAppointment saToUpdate = new ServiceAppointment(
            Id = serviceAppointmentId,
            SchedStartTime = startDt,
            SchedEndTime = endDt,
            Status = 'Dispatched' // Sett status samtidig som tider
        );
        update saToUpdate;
    }

    @IsTest
    static void getServiceAppointmentsTest() {
        AssignedResource assignedResource = [SELECT Id, ServiceAppointmentId FROM AssignedResource];
        
        // VIKTIG: Start testen før du gjør update som trigger logikk
        Test.startTest(); 
        update new ServiceAppointment(Id = assignedResource.ServiceAppointmentId, Status = 'None');
        Test.stopTest(); // stopTest tvinger asynkrone jobber til å kjøre ferdig

        HOT_WageClaim__c wageClaim = [SELECT Id, ServiceResource__c FROM HOT_WageClaim__c LIMIT 1];
        List<ServiceAppointment> serviceAppointments = HOT_WageClaimService.getServiceAppointments(wageClaim.Id);

        System.assertEquals(
            1,
            serviceAppointments.size(),
            'Could not get Service Appointments overlapping with Wage Claim'
        );
    }

    @IsTest
    static void SAWithARTimesChanged() {
        AssignedResource assignedResource = [SELECT Id, ServiceAppointmentId, ServiceResourceId FROM AssignedResource];

        ServiceAppointment serviceAppointment = [
            SELECT Id, SchedStartTime, SchedEndTime, ActualStartTime, ActualEndTime
            FROM ServiceAppointment
            WHERE Id = :assignedResource.ServiceAppointmentId
            LIMIT 1
        ];

        Test.startTest(); // Nullstiller SOQL-telleren til 0
        serviceAppointment.ActualStartTime = serviceAppointment.SchedStartTime.addMinutes(15);
        serviceAppointment.ActualEndTime = serviceAppointment.SchedEndTime.addMinutes(-15);
        serviceAppointment.Status = 'Completed';
        update serviceAppointment;
        Test.stopTest(); // Kjører ferdig evt. future/queueable metoder

        List<HOT_WageClaim__c> wageClaims = [SELECT Id, StartTime__c, EndTime__c FROM HOT_WageClaim__c];
        Boolean isWageClaimTimesCorrect = false;
        Boolean isWageClaimTimesCorrect2 = false;

        for (HOT_WageClaim__c wageClaim : wageClaims) {
            if (
                wageClaim.StartTime__c == serviceAppointment.SchedStartTime &&
                wageClaim.EndTime__c == serviceAppointment.ActualStartTime
            ) {
                isWageClaimTimesCorrect = true;
            }
            if (
                wageClaim.StartTime__c == serviceAppointment.ActualEndTime &&
                wageClaim.EndTime__c == serviceAppointment.SchedEndTime
            ) {
                isWageClaimTimesCorrect2 = true;
            }
        }

        System.assertEquals(
            true,
            isWageClaimTimesCorrect && isWageClaimTimesCorrect2,
            'WageClaim start and end times were not set correctly.'
        );
        System.assertEquals(2, wageClaims.size(), 'Could not create WageClaim when actual time on SA was updated.');
    }

    @IsTest
    static void SAWithARTimesChangedAndIsAgreement() {
        AssignedResource assignedResource = [SELECT Id, ServiceAppointmentId, ServiceResourceId FROM AssignedResource];
        
        // Disse oppdateringene er "dyre" (trigger flows/triggers). 
        // Hvis mulig, flytt disse inn i Test.startTest() eller optimaliser dem.
        update new ServiceResource(Id = assignedResource.ServiceResourceId, HOT_AgreementFreelance__c = true);

        HOT_Request__c request = [SELECT Id, ServiceResourceWithAgreement1__c FROM HOT_Request__c];
        request.ServiceResourceWithAgreement1__c = assignedResource.ServiceResourceId;
        update request;

        ServiceAppointment serviceAppointment = [
            SELECT Id, SchedStartTime, SchedEndTime, HOT_ServiceResource__c
            FROM ServiceAppointment
            WHERE Id = :assignedResource.ServiceAppointmentId
            LIMIT 1
        ];

        // NÅ starter vi testen, som gir oss nye 100 queries til selve testen
        Test.startTest();
        serviceAppointment.ActualStartTime = serviceAppointment.SchedStartTime.addMinutes(15);
        serviceAppointment.ActualEndTime = serviceAppointment.SchedEndTime.addMinutes(-15);
        serviceAppointment.Status = 'Completed';
        update serviceAppointment;
        Test.stopTest();

        List<HOT_WageClaim__c> wageClaims = [
            SELECT Id 
            FROM HOT_WageClaim__c 
            WHERE ServiceResource__c = :serviceAppointment.HOT_ServiceResource__c
        ];

        System.assertEquals(0, wageClaims.size(), 'Wage Claim was incorrectly created when SR is on agreement.');
    }

    @IsTest
    static void shouldNotCreateWageClaimWhenStartTimeIsMoreThan48HoursAway() {
        ServiceAppointment sa = [SELECT Id, SchedStartTime, SchedEndTime, Status FROM ServiceAppointment LIMIT 1];

        Datetime startDt = System.now().addHours(49);
        Datetime endDt = startDt.addHours(2);

        sa.SchedStartTime = startDt;
        sa.SchedEndTime = endDt;
        
        // Vi kan gjøre klargjøringen her
        update sa;

        Test.startTest();
        // Trigger logikken
        update new ServiceAppointment(Id = sa.Id, Status = 'Dispatched');
        Test.stopTest();

        Integer wageClaimCount = [SELECT COUNT() FROM HOT_WageClaim__c];
        System.assertEquals(
            0,
            wageClaimCount,
            'Wage Claim should NOT be created when Service Appointment starts more than 48 hours ahead.'
        );
    }
}