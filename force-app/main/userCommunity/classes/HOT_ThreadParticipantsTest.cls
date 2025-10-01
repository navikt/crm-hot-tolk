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

        // Opprett nødvendige setup-objekter FØRST
        UserRole testRole = new UserRole(Name = 'Test Rolle', DeveloperName = 'Test_Rolle');
        insert testRole;

        Profile adminProf = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Customer Community Plus User' LIMIT 1];
        PermissionSet psg = [SELECT Id FROM PermissionSet WHERE Name = 'HOT_Tolk_Frilans' LIMIT 1];
        User adminUser = HOT_TestDataFactory.createUser('rbadm', adminProf);
        adminUser.UserRoleId = testRole.Id;
        insert adminUser;

        // Kjør resten av testdataoppsettet innenfor runAs
        System.runAs(adminUser) {
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

            // Steg 3: Opprett Users koblet til hver PersonContact
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
            data.users = usersToInsert;
            insert new PermissionSetAssignment(PermissionSetId = psg.Id, AssigneeId = usersToInsert[1].Id);
            // Steg 4: Opprett annen testdata
            WorkType workType = HOT_TestDataFactory.createWorkType();
            insert workType;
            data.workType = workType;

            HOT_Request__c request = HOT_TestDataFactory.createRequest('Test', workType);
            request.Account__c = accounts[0].Id;
            insert request;
            request.Status__c = 'Godkjent';
            update request;
            data.request = request;

            // Steg 5: Opprett ServiceAppointment
            ServiceAppointment serviceAppointment = [SELECT Id FROM ServiceAppointment LIMIT 1];
            data.serviceAppointment = serviceAppointment;

            // Steg 6: Opprett ServiceResource for en av brukerne
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
        }

        return data;
    }
    @IsTest
    static void testGetParticipants() {
        TestData data = createTestData();
    }
}
