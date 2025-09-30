@isTest
private class HOT_ThreadParticipantsTest {
    // Wrapper for å holde på opprettede testdata
    private class TestData {
        public List<Account> accounts;
        public List<User> users;
        public WorkType workType;
        public HOT_Request__c request;
        public ServiceAppointment serviceAppointment;
        public ServiceResource resource1;
    }

    private static TestData createTestData() {
        TestData data = new TestData();

        Id personAccountRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get('PersonAccount')
            .getRecordTypeId();

        // Steg 1: Lag 2 Person__c
        List<Person__c> persons = new List<Person__c>();
        for (Integer i = 1; i <= 2; i++) {
            persons.add(
                new Person__c(
                    Name = String.valueOf(i),
                    INT_LastName__c = String.valueOf(i),
                    INT_Confidential__c = 'UGRADERT'
                )
            );
        }
        insert persons;
        Profile adminProf = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User adminUser = HOT_TestDataFactory.createUser('rbadm', adminProf);
        insert adminUser;

        // Steg 2: Opprett 2 Person Accounts
        List<Account> accountsToInsert = new List<Account>();
        for (Integer i = 0; i < 2; i++) {
            accountsToInsert.add(
                new Account(
                    FirstName = 'Person',
                    LastName = String.valueOf(i + 1),
                    INT_PersonIdent__c = String.valueOf(i + 1),
                    CRM_Person__c = persons[i].Id,
                    RecordTypeId = personAccountRtId,
                    OwnerId = adminUser.Id
                )
            );
        }
        insert accountsToInsert;

        List<Account> accounts = [
            SELECT Id, FirstName, LastName, PersonContactId
            FROM Account
            WHERE Id IN :accountsToInsert
        ];
        data.accounts = accounts;

        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Customer Community Plus User' LIMIT 1];

        // Steg 3: Opprett Users koblet til hver PersonContact med runAs adminUser
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
        System.runAs(adminUser) {
            insert usersToInsert;
        }

        data.users = usersToInsert;

        // Opprett annen testdata
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        data.workType = workType;

        HOT_Request__c request = HOT_TestDataFactory.createRequest('Test', workType);
        request.Account__c = accounts[0].Id;
        insert request;
        request.Status__c = 'Godkjent';
        update request;
        data.request = request;

        ServiceAppointment serviceAppointment = [SELECT Id FROM ServiceAppointment LIMIT 1];
        data.serviceAppointment = serviceAppointment;

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
        data.resource1 = resource1;

        ServiceTerritoryMember serviceTerritoryMember = HOT_TestDataFactory.createServiceTerritoryMember(
            resource1,
            serviceTerritory
        );
        insert serviceTerritoryMember;

        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(
            serviceAppointment.Id,
            resource1.Id
        );
        insert assignedResource;

        return data;
    }

    @IsTest
    private static void getRequestThreadParticipants() {
        TestData data = createTestData();

        Test.startTest();
        HOT_Request__c request = data.request;

        Thread__c thread = HOT_TestDataFactory.createThread('HOT_BRUKER-FORMIDLER');
        thread.CRM_Related_Object__c = request.Id;
        insert thread;

        List<HOT_ThreadParticipants.Participant> participants = HOT_ThreadParticipants.getParticipants(thread.Id);
        Test.stopTest();

        List<String> participantNames = new List<String>();
        for (HOT_ThreadParticipants.Participant p : participants) {
            participantNames.add(p.name);
        }

        System.assert(
            participantNames.contains('Person 1'),
            'Mangler deltaker med navn "Person 1". Faktiske deltakere: ' + String.join(participantNames, ', ')
        );

        System.assert(
            participantNames.contains('Formidler'),
            'Mangler deltaker med navn "Formidler". Faktiske deltakere: ' + String.join(participantNames, ', ')
        );
    }

    @IsTest
    private static void getWorkOrderThreadParticipants() {
        TestData data = createTestData();

        Test.startTest();
        WorkOrder workOrder = [SELECT Id FROM WorkOrder LIMIT 1];
        Thread__c thread = HOT_TestDataFactory.createThread('HOT_BRUKER-TOLK');
        thread.CRM_Related_Object__c = workOrder.Id;
        insert thread;

        List<HOT_ThreadParticipants.Participant> participants = HOT_ThreadParticipants.getParticipants(thread.Id);
        Test.stopTest();

        List<String> participantNames = new List<String>();
        for (HOT_ThreadParticipants.Participant p : participants) {
            participantNames.add(p.name);
        }

        System.assert(
            participantNames.contains('Person 1'),
            'Mangler deltaker med navn "Person 1". Faktiske deltakere: ' + String.join(participantNames, ', ')
        );

        System.assert(
            participantNames.contains('Frilans'),
            'Mangler deltaker med navn "Frilans". Faktiske deltakere: ' + String.join(participantNames, ', ')
        );
    }

    // Gjør tilsvarende endringer for alle andre tester (kall createTestData i starten)

    @IsTest
    private static void getWorkOrderThread2Participants() {
        TestData data = createTestData();

        Test.startTest();
        WorkOrder workOrder = [SELECT Id FROM WorkOrder LIMIT 1];
        Thread__c thread = HOT_TestDataFactory.createThread('HOT_TOLK-TOLK');
        thread.CRM_Related_Object__c = workOrder.Id;
        insert thread;

        List<HOT_ThreadParticipants.Participant> participants = HOT_ThreadParticipants.getParticipants(thread.Id);
        Test.stopTest();

        List<String> participantNames = new List<String>();
        for (HOT_ThreadParticipants.Participant p : participants) {
            participantNames.add(p.name);
        }

        System.assert(
            !participantNames.contains('Person 1'),
            '"Person 1" skulle ikke vært deltaker av denne samtalen som kun er mellom tolker. Faktiske deltakere: ' +
            String.join(participantNames, ', ')
        );

        System.assert(
            participantNames.contains('Frilans'),
            'Mangler deltaker med navn "Frilans". Faktiske deltakere: ' + String.join(participantNames, ', ')
        );
    }

    @IsTest
    private static void getInterestedResourceThreadParticipants() {
        TestData data = createTestData();

        Test.startTest();
        HOT_InterestedResource__c interestedResource = [SELECT Id FROM HOT_InterestedResource__c LIMIT 1];
        Thread__c thread = HOT_TestDataFactory.createThread('HOT_TOLK-FORMIDLER');
        thread.CRM_Related_Object__c = interestedResource.Id;
        insert thread;

        List<HOT_ThreadParticipants.Participant> participants = HOT_ThreadParticipants.getParticipants(thread.Id);
        Test.stopTest();

        List<String> participantNames = new List<String>();
        for (HOT_ThreadParticipants.Participant p : participants) {
            participantNames.add(p.name);
        }

        System.assert(
            participantNames.contains('Formidler'),
            'Mangler deltaker med navn "Formidler". Faktiske deltakere: ' + String.join(participantNames, ', ')
        );

        System.assert(
            participantNames.contains('Frilans'),
            'Mangler deltaker med navn "Frilans". Faktiske deltakere: ' + String.join(participantNames, ', ')
        );
    }

    @IsTest
    private static void getServiceAppointmentThreadParticipants() {
        TestData data = createTestData();

        Test.startTest();
        ServiceAppointment serviceAppointment = data.serviceAppointment;
        Thread__c thread = HOT_TestDataFactory.createThread('HOT_TOLK-FORMIDLER');
        thread.CRM_Related_Object__c = serviceAppointment.Id;
        insert thread;

        List<HOT_ThreadParticipants.Participant> participants = HOT_ThreadParticipants.getParticipants(thread.Id);
        Test.stopTest();

        List<String> participantNames = new List<String>();
        for (HOT_ThreadParticipants.Participant p : participants) {
            participantNames.add(p.name);
        }

        System.assert(
            participantNames.contains('Formidler'),
            'Mangler deltaker med navn "Formidler". Faktiske deltakere: ' + String.join(participantNames, ', ')
        );

        System.assert(
            participantNames.contains('Frilans'),
            'Mangler deltaker med navn "Frilans". Faktiske deltakere: ' + String.join(participantNames, ', ')
        );
    }

    @IsTest
    private static void getWageClaimThreadParticipants() {
        TestData data = createTestData();

        Test.startTest();
        ServiceAppointment serviceAppointment = data.serviceAppointment;
        serviceAppointment.Status = 'Dispatched';
        update serviceAppointment;
        serviceAppointment.Status = 'Canceled';
        update serviceAppointment;

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
