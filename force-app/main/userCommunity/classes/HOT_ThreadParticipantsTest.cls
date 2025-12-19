@isTest
private class HOT_ThreadParticipantsTest {
    @TestSetup
    private static void setup() {
        myTriggers.disable(UserPermissionSetAssignmentHandler.class);
        myTriggers.disable(UserProfileHandler.class);
        myTriggers.disable(UserRegionHandler.class);
        myTriggers.disable(UserRoleAssignmentHandler.class);

        // Opprett nødvendige setup-objekter
        UserRole testRole = new UserRole(Name = 'Test Rolle', DeveloperName = 'Test_Rolle');
        //insert testRole;
        System.runAs([SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1][0]) {
            insert testRole;
            User u = new User(Id = UserInfo.getUserId(), UserRoleId = testRole.Id);
            update u;
        }

        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Customer Community Plus User' LIMIT 1];
        PermissionSet psg = [SELECT Id FROM PermissionSet WHERE Name = 'HOT_Tolk_Frilans' LIMIT 1];

        Id personAccountRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get('PersonAccount')
            .getRecordTypeId();

        // Opprett Person__c
        List<Person__c> persons = new List<Person__c>();
        for (Integer i = 1; i <= 2; i++) {
            persons.add(
                new Person__c(
                    Name = String.valueOf(i),
                    INT_FirstName__c = 'Person',
                    INT_LastName__c = String.valueOf(i),
                    INT_Confidential__c = 'UGRADERT'
                )
            );
        }
        insert persons;

        List<Account> accounts = [
            SELECT Id, FirstName, LastName, PersonContactId
            FROM Account
            WHERE CRM_Person__c IN :new Map<Id, Person__c>(persons).keySet()
        ];
        // Opprett Users
        List<User> usersToInsert = new List<User>();
        for (Account acc : accounts) {
            if (acc.PersonContactId != null) {
                String email = acc.PersonContactId + '@nav.no';
                usersToInsert.add(
                    new User(
                        FirstName = acc.FirstName,
                        LastName = acc.LastName,
                        ContactId = acc.PersonContactId,
                        Alias = String.valueOf(acc.PersonContactId).substring(1, 6),
                        Username = email,
                        Email = email,
                        ProfileId = profile.Id,
                        EmailEncodingKey = 'UTF-8',
                        CommunityNickname = acc.LastName,
                        TimeZoneSidKey = 'Europe/Paris',
                        LocaleSidKey = 'no_NO',
                        LanguageLocaleKey = 'no'
                    )
                );
            }
        }

        insert usersToInsert;

        System.runAs([SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1][0]) {
            insert new PermissionSetAssignment(PermissionSetId = psg.Id, AssigneeId = usersToInsert[1].Id);
        }

        // Opprett annen testdata
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;

        HOT_Request__c request = HOT_TestDataFactory.createRequest('Test', workType);
        request.Account__c = accounts[0].Id;
        insert request;
        request.Status__c = 'Godkjent';
        update request;

        // Hent ServiceAppointment som ble opprettet av automasjon
        ServiceAppointment serviceAppointment = [SELECT Id FROM ServiceAppointment LIMIT 1];

        // Opprett ServiceResource
        User getUserToBeFreelanc = usersToInsert[1];
        OperatingHours operatingHours = HOT_TestDataFactory.createOperatingHours();
        insert operatingHours;
        ServiceTerritory serviceTerritory = HOT_TestDataFactory.createServiceTerritory(operatingHours);
        insert serviceTerritory;

        ServiceResource resource1 = HOT_TestDataFactory.createServiceResource(getUserToBeFreelanc.Id);
        resource1.HOT_ServiceTerritory__c = serviceTerritory.Id;
        resource1.HOT_IsFreelanceInterpreter__c = true;
        resource1.Name = 'Frilans';
        insert resource1;

        ServiceTerritoryMember stm = HOT_TestDataFactory.createServiceTerritoryMember(resource1, serviceTerritory);
        insert stm;

        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(
            serviceAppointment.Id,
            resource1.Id
        );
        insert assignedResource;
    }
    @IsTest
    private static void getParticipantByRelatedRequest() {
        HOT_Request__c request = [SELECT Id, Account__r.PersonContactId FROM HOT_Request__c LIMIT 1];
        User personUser = [
            SELECT Id, ContactId
            FROM User
            WHERE ContactId = :request.Account__r.PersonContactId
            LIMIT 1
        ];
        Thread__c thread = HOT_TestDataFactory.createThread('HOT_BRUKER-FORMIDLER');
        thread.CRM_Related_Object__c = request.Id;
        thread.HOT_Thread_read_by__c = personUser.Id + ';';
        insert thread;

        Test.startTest();
        Map<String, Map<Id, List<HOT_ThreadParticipants.Participant>>> threadMap = HOT_ThreadParticipants.getParticipantsByRelatedObjectAndThreadTypes(
            request.Id,
            new List<String>{ 'HOT_BRUKER-FORMIDLER' }
        );
        Test.stopTest();
        System.assert(
            threadMap.containsKey('HOT_BRUKER-FORMIDLER'),
            'Deltakere for trådtypen "HOT_BRUKER-FORMIDLER" mangler'
        );
        System.assert(threadMap.get('HOT_BRUKER-FORMIDLER').containsKey(thread.Id), 'Tråden mangler');

        List<HOT_ThreadParticipants.Participant> participants = threadMap.get('HOT_BRUKER-FORMIDLER').get(thread.Id);

        List<String> participantNames = new List<String>();
        for (HOT_ThreadParticipants.Participant p : participants) {
            participantNames.add(p.name);
        }

        System.assert(participantNames.contains('Person 1'), 'Mangler deltaker "Person 1"');
        System.assert(participantNames.contains('Formidler'), 'Mangler deltaker "Formidler"');
    }
    @IsTest
    private static void getParticipantByRelatedWorkOrder() {
        WorkOrder workOrder = [SELECT Id FROM WorkOrder LIMIT 1];
        Thread__c thread = HOT_TestDataFactory.createThread('HOT_BRUKER-TOLK');
        thread.CRM_Related_Object__c = workOrder.Id;
        insert thread;
        Test.startTest();
        Map<String, Map<Id, List<HOT_ThreadParticipants.Participant>>> threadMap = HOT_ThreadParticipants.getParticipantsByRelatedObjectAndThreadTypes(
            workOrder.Id,
            new List<String>{ 'HOT_BRUKER-TOLK' }
        );
        Test.stopTest();
        System.assert(threadMap.containsKey('HOT_BRUKER-TOLK'), 'Deltakere for trådtypen "HOT_BRUKER-TOLK" mangler');
        System.assert(threadMap.get('HOT_BRUKER-TOLK').containsKey(thread.Id), 'Tråden mangler');
    }
    @IsTest
    private static void getParticipantByRelatedServiceAppointment() {
        ServiceAppointment serviceAppointment = [SELECT Id FROM ServiceAppointment LIMIT 1];
        Thread__c thread = HOT_TestDataFactory.createThread('HOT_TOLK-FORMIDLER');
        thread.CRM_Related_Object__c = serviceAppointment.Id;
        insert thread;
        Test.startTest();
        Map<String, Map<Id, List<HOT_ThreadParticipants.Participant>>> threadMap = HOT_ThreadParticipants.getParticipantsByRelatedObjectAndThreadTypes(
            serviceAppointment.Id,
            new List<String>{ 'HOT_TOLK-FORMIDLER' }
        );
        Test.stopTest();
        System.assert(
            threadMap.containsKey('HOT_TOLK-FORMIDLER'),
            'Deltakere for trådtypen "HOT_TOLK-FORMIDLER" mangler'
        );
        System.assert(threadMap.get('HOT_TOLK-FORMIDLER').containsKey(thread.Id), 'Tråden mangler');
    }
    @IsTest
    private static void getRequestThreadParticipants() {
        HOT_Request__c request = [SELECT Id FROM HOT_Request__c LIMIT 1];
        Thread__c thread = HOT_TestDataFactory.createThread('HOT_BRUKER-FORMIDLER');
        thread.CRM_Related_Object__c = request.Id;
        insert thread;

        Test.startTest();
        List<HOT_ThreadParticipants.Participant> participants = HOT_ThreadParticipants.getParticipants(thread.Id);
        Test.stopTest();

        List<String> participantNames = new List<String>();
        for (HOT_ThreadParticipants.Participant p : participants) {
            participantNames.add(p.name);
        }

        System.assert(participantNames.contains('Person 1'), 'Mangler deltaker "Person 1"');
        System.assert(participantNames.contains('Formidler'), 'Mangler deltaker "Formidler"');
    }

    @IsTest
    private static void getWorkOrderThreadParticipants() {
        WorkOrder workOrder = [SELECT Id FROM WorkOrder LIMIT 1];
        Thread__c thread = HOT_TestDataFactory.createThread('HOT_BRUKER-TOLK');
        thread.CRM_Related_Object__c = workOrder.Id;
        insert thread;

        Test.startTest();
        List<HOT_ThreadParticipants.Participant> participants = HOT_ThreadParticipants.getParticipants(thread.Id);
        Test.stopTest();

        List<String> participantNames = new List<String>();
        for (HOT_ThreadParticipants.Participant p : participants) {
            participantNames.add(p.name);
        }

        System.assert(participantNames.contains('Person 1'), 'Mangler deltaker "Person 1"');
        System.assert(participantNames.contains('Frilans'), 'Mangler deltaker "Frilans"');
    }

    @IsTest
    private static void getWorkOrderThread2Participants() {
        WorkOrder workOrder = [SELECT Id FROM WorkOrder LIMIT 1];
        Thread__c thread = HOT_TestDataFactory.createThread('HOT_TOLK-TOLK');
        thread.CRM_Related_Object__c = workOrder.Id;
        insert thread;

        Test.startTest();
        List<HOT_ThreadParticipants.Participant> participants = HOT_ThreadParticipants.getParticipants(thread.Id);
        Test.stopTest();

        List<String> participantNames = new List<String>();
        for (HOT_ThreadParticipants.Participant p : participants) {
            participantNames.add(p.name);
        }

        System.assert(!participantNames.contains('Person 1'), '"Person 1" skulle ikke vært deltaker');
        System.assert(participantNames.contains('Frilans'), 'Mangler deltaker "Frilans"');
    }

    @IsTest
    private static void getInterestedResourceThreadParticipants() {
        HOT_InterestedResource__c interestedResource = [SELECT Id FROM HOT_InterestedResource__c LIMIT 1];
        Thread__c thread = HOT_TestDataFactory.createThread('HOT_TOLK-FORMIDLER');
        thread.CRM_Related_Object__c = interestedResource.Id;
        insert thread;

        Test.startTest();
        List<HOT_ThreadParticipants.Participant> participants = HOT_ThreadParticipants.getParticipants(thread.Id);
        Test.stopTest();

        List<String> participantNames = new List<String>();
        for (HOT_ThreadParticipants.Participant p : participants) {
            participantNames.add(p.name);
        }

        System.assert(participantNames.contains('Formidler'), 'Mangler deltaker "Formidler"');
        System.assert(participantNames.contains('Frilans'), 'Mangler deltaker "Frilans"');
    }

    @IsTest
    private static void getServiceAppointmentThreadParticipants() {
        ServiceAppointment serviceAppointment = [SELECT Id FROM ServiceAppointment LIMIT 1];
        Thread__c thread = HOT_TestDataFactory.createThread('HOT_TOLK-FORMIDLER');
        thread.CRM_Related_Object__c = serviceAppointment.Id;
        insert thread;

        Test.startTest();
        List<HOT_ThreadParticipants.Participant> participants = HOT_ThreadParticipants.getParticipants(thread.Id);
        Test.stopTest();

        List<String> participantNames = new List<String>();
        for (HOT_ThreadParticipants.Participant p : participants) {
            participantNames.add(p.name);
        }

        System.assert(participantNames.contains('Formidler'), 'Mangler deltaker "Formidler"');
        System.assert(participantNames.contains('Frilans'), 'Mangler deltaker "Frilans"');
    }
    @IsTest
    private static void getWageClaimThreadParticipants() {
        ServiceAppointment serviceAppointment = [SELECT Id FROM ServiceAppointment LIMIT 1];

        Test.startTest();
        Datetime startT = System.now().addHours(1);
        Datetime endT = startT.addHours(1);
        serviceAppointment.SchedStartTime = startT;
        serviceAppointment.SchedEndTime = endT;
        serviceAppointment.Status = 'Dispatched';
        update serviceAppointment;

        ServiceAppointment saAfterUpdate = [SELECT Id FROM ServiceAppointment WHERE Id = :serviceAppointment.Id];
        saAfterUpdate.Status = 'Canceled';
        update saAfterUpdate;

        HOT_WageClaim__c wageClaim = [SELECT Id FROM HOT_WageClaim__c LIMIT 1];

        Thread__c thread = HOT_TestDataFactory.createThread('HOT_TOLK-RESSURSKONTOR');
        thread.CRM_Related_Object__c = wageClaim.Id;
        insert thread;
        List<HOT_ThreadParticipants.Participant> participants = HOT_ThreadParticipants.getParticipants(thread.Id);

        Test.stopTest();

        List<String> participantNames = new List<String>();
        for (HOT_ThreadParticipants.Participant p : participants) {
            participantNames.add(p.name);
        }

        System.assert(
            participantNames.contains('Ressurskontor'),
            'Mangler deltaker med navn "Ressurskontor". Faktiske deltakere: ' + String.join(participantNames, ', ')
        );

        System.assert(
            participantNames.contains('Frilans'),
            'Mangler deltaker med navn "Frilans". Faktiske deltakere: ' + String.join(participantNames, ', ')
        );
    }
}
