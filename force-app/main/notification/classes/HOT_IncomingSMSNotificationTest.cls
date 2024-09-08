@isTest
private class HOT_IncomingSMSNotificationTest {
    static List<String> userNames = new List<String>{'A_User', 'B_User', 'C_User'};
    static List<String> userMunicipalities = new List<String>{'3216', '5001', '3407'};
    static List<String> userRegionNumbers = new List<String>{'03','50','34'};

    @TestSetup
    static void makeData(){
        myTriggers.disable(PersonHandler.class);
        myTriggers.disable(PersonAccessHandler.class);
        myTriggers.disable(CommunityUserUpdateHandler.class);
        User navEmployee = TestDataFactory_Community.getUsers(1, 'System Administrator', true, true)[0];
        System.runAs(navEmployee) {
            Account account = new Account();
            account.Name = 'Gunnar Gunn Gundersen';
            insert account;

            TestDataFactory.getPublicGroup('HMS Oslo', 'group_4703');
            TestDataFactory.getQueue('HMS Oslo', 'queue_4703', 'Person__c');
            TestDataFactory.getPublicGroup('HMS Trøndelag', 'group_4716');
            TestDataFactory.getQueue('HMS Trøndelag', 'queue_4716', 'Person__c');
            TestDataFactory.getPublicGroup('HMS Innlandet', 'group_47003');
            TestDataFactory.getQueue('HMS Innlandet', 'queue_47003', 'Person__c');

            List<Account> personAccounts = TestDataFactory_Community.getPersonAccounts(userNames.size());
            Map<String,Account> accountByLastName=new Map<String,Account>();
            for(Account acc:personAccounts){
                accountByLastName.put(acc.LastName,acc);
            }

            Set<Id> personAccountIds=new Set<Id>();
            List<Person__c> persons=[SELECT INT_LastName__c, CRM_Account__c FROM Person__c]; 
            Integer index = 0;
            for (Person__c person : persons) {
                person.CRM_Account__c=accountByLastName.get(person.INT_LastName__c).Id;
                person.Name = userNames[index];
                person.INT_MunicipalityNumber__c = userMunicipalities[index];
                person.INT_RegionNumber__c = userRegionNumbers[index];
                index++;
                personAccountIds.add(person.CRM_Account__c);

            }
            update persons;
            List<User> users = TestDataFactory_Community.getEmployerCommunityUser(
                personAccountIds, 
                'Trial Customer Portal User', 
                true
                );
        }
    }

    @isTest
    static void getQueueIdsFromSendersTest() {

        List<Person__c> persons = [
            SELECT Id, Name, CRM_Account__c, INT_MunicipalityNumber__c, INT_RegionNumber__c
            FROM Person__c 
            WHERE Name IN :userNames
            ORDER BY Name
        ];

        Test.startTest();
        List<Id> groupIds = HOT_IncomingSMSNotification.getQueueIdsFromSenders(persons);
        Test.stopTest();

        Id osloQueueId = [SELECT Id FROM Group WHERE DeveloperName = 'queue_4703' LIMIT 1].Id;
        System.assertEquals(osloQueueId, groupIds[0], 'Person 0 should belong to Oslo region');

        Id trondelagQueueId = [SELECT Id FROM Group WHERE DeveloperName = 'queue_4716' LIMIT 1].Id;
        System.assertEquals(trondelagQueueId, groupIds[1], 'Person 1 should belong to trondelag region');

        Id innlandetQueueId = [SELECT Id FROM Group WHERE DeveloperName = 'queue_47003' LIMIT 1].Id;
        System.assertEquals(innlandetQueueId, groupIds[2], 'Person 2 should belong to Innlandet region');
    }

    @isTest
    static void shouldNotifyDispatchersAboutSMSTest() {
        Account acc = [SELECT Id, Name FROM Account WHERE Name = 'Gunnar Gunn Gundersen'];
        SMS__c testSMS = new SMS__c();
        testSMS.Domain__c = 'HOT';
        testSMS.Type__c = 'Incoming SMS';
        testSMS.Recipient__c = HOT_IncomingSMSNotification.DISPATCH_INCOMING_NUMBER;
        testSMS.Account__c = acc.Id;

        Test.startTest();
        Boolean shouldNotify = 
            HOT_IncomingSMSNotification.shouldNotifyDispatchersAboutSMS(testSMS);
        Test.stopTest();

        System.assertEquals(true, shouldNotify, 'SMS should trigger notification of dispatchers');
    }
}