@isTest
public with sharing class HOT_MessageHelperTest {
    @TestSetup
    static void makeData() {
        Account acc = new Account();
        acc.Name = 'Test account';
        insert acc;

        Thread__c t = HOT_TestDataFactory.createThread();
        t.CRM_Related_Object__c = acc.Id;

        Thread__c t2 = HOT_TestDataFactory.createThread();
        t2.CRM_Related_Object__c = acc.Id;

        Thread__c t3 = HOT_TestDataFactory.createThread();
        t3.CRM_Related_Object__c = acc.Id;

        insert new List<Thread__c>{ t, t2, t3 };

        Message__c m = new Message__c();
        m.CRM_Thread__c = t.Id;
        m.CRM_Message_Text__c = 'Lorem Ipsum Dolor Si Amet';
        insert m;
    }
    @isTest
    static void getObjectTypeFromidTest() {
        List<Account> accList = [SELECT Id FROM Account];
        Test.startTest();
        String objectType = HOT_MessageHelper.getRecordObjectType(acclist.get(0).Id);
        Test.stopTest();
        System.assertEquals('Account', objectType, 'Object type is not recoginzed as expected');
    }
    @isTest
    static void getUserContactId() {
        Test.startTest();
        String contactId = HOT_MessageHelper.getUserContactId();
        Test.stopTest();
        System.assertEquals(null, contactId, 'User Contact Id was not returned correctly');
    }
    @isTest
    static void getThreadsCollectionSingleTest() {
        List<Account> accList = [SELECT Id FROM Account];
        Test.startTest();
        List<Thread__c> resList = HOT_MessageHelper.getThreadsCollection(accList.get(0).Id, true);
        Test.stopTest();
        System.assertEquals(1, resList.size());
    }
    /**
     * TODO, has to run in a users contect
     */
    @isTest
    static void getThreadsCollectionMultiTest() {
        List<Account> accList = [SELECT Id FROM Account];
        Test.startTest();
        List<Thread__c> resList = HOT_MessageHelper.getThreadsCollection(accList.get(0).Id, false);
        Test.stopTest();
        System.assertEquals(3, resList.size());
    }

    @isTest
    static void getSingleThreadTest() {
        List<Account> accList = [SELECT Id FROM Account];
        Test.startTest();
        Thread__c t = HOT_MessageHelper.getSingleThread(accList.get(0).Id);
        Test.stopTest();
        System.assertNotEquals(null, t);
    }
    @isTest
    static void getThreadFromIdTest() {
        Thread__c thread = new Thread__c();
        insert thread;
        Test.startTest();
        Thread__c t = HOT_MessageHelper.getThreadFromThreadId(thread.Id);
        Test.stopTest();
        System.assertNotEquals(null, t);
    }
    @isTest
    static void createThread() {
        Account acc = new Account();
        acc.Name = 'Newly created account';
        insert acc;
        WorkType workType = HOT_TestDataFactory.createWorkType();
        workType.Name = 'Work Type Name';
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('Subject', workType);
        insert request;

        Test.startTest();
        Thread__c thread = HOT_MessageHelper.createThread(request.Id, acc.Id);
        Test.stopTest();
        List<Thread__c> tList = [
            SELECT Id, CRM_Account__c, CRM_Type__c
            FROM Thread__c
            WHERE CRM_Related_Object__c = :request.Id
        ];
        System.assertNotEquals(null, tList);
        System.assertEquals(tList[0].CRM_Account__c, acc.Id);
        System.assertEquals(tList[0].CRM_Type__c, 'HOT_BRUKER-FORMIDLER');
    }

    @isTest
    static void getAccountonRequestTest() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        workType.Name = 'Work Type Name';
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('Subject', workType);
        Account personAccount = HOT_TestDataFactory.createAccount(true);
        insert personAccount;
        request.Account__c = personAccount.Id;
        insert request;

        Test.startTest();
        Id accountId = HOT_MessageHelper.getAccountOnRequest(request.Id);
        Test.stopTest();
        System.assertNotEquals(null, accountId);
        System.assertEquals(accountId, personAccount.Id);
    }

    @isTest
    static void getMessagesFromThreadTest() {
        List<Thread__c> tList = [SELECT Id FROM Thread__c ORDER BY CRM_Number_of_External_Messages__c DESC];
        Test.startTest();
        List<Message__c> msgList = HOT_MessageHelper.getMessagesFromThread(tList.get(0).Id);
        Test.stopTest();
        System.assertEquals(1, msgList.size());
    }
    @isTest
    static void getUserLisenceTest() {
        Test.startTest();
        String lisenceType = HOT_MessageHelper.getUserLisenceType(UserInfo.getUserId());
        Test.stopTest();
        System.assertNotEquals(null, lisenceType);
    }
    @isTest
    static void markasreadTest() {
        List<Thread__c> tList = [SELECT Id FROM Thread__c ORDER BY CRM_Number_of_External_Messages__c DESC];
        Test.startTest();
        HOT_MessageHelper.markAsRead(tList.get(0).Id);
        Test.stopTest();
        List<Message__c> msgList = [SELECT CRM_Read__c FROM Message__c WHERE CRM_Thread__c = :tList.get(0).Id];
        System.assertEquals(true, msgList.get(0).CRM_Read__c);
    }

    @isTest
    static void markAsReadByNavTest() {
        List<Thread__c> tList = [SELECT Id FROM Thread__c ORDER BY CRM_Number_of_External_Messages__c DESC];
        Test.startTest();
        HOT_MessageHelper.markAsReadByNav(tList.get(0).Id);
        Test.stopTest();
        List<Message__c> msgList = [
            SELECT CRM_Read_By_Nav__c, CRM_Read_By_Nav_Datetime__c
            FROM Message__c
            WHERE CRM_Thread__c = :tList.get(0).Id
        ];
        System.assertEquals(true, msgList.get(0).CRM_Read_By_Nav__c, 'Could not set CRM_Read_By_Nav__c to true.');
        System.assertNotEquals(
            null,
            msgList.get(0).CRM_Read_By_Nav_Datetime__c,
            'CRM_Read_By_Nav_Datetime__c was not set.'
        );
    }
    @isTest
    static void createMessageTest() {
        List<Thread__c> tList = [SELECT Id FROM Thread__c ORDER BY CRM_Number_of_External_Messages__c DESC];
        Test.startTest();
        HOT_MessageHelper.createMessage(tList.get(0).Id, 'Some text value', null);
        Test.stopTest();
        List<Message__c> msgList = [SELECT CRM_Read__c FROM Message__c WHERE CRM_Thread__c = :tList.get(0).Id];
        System.assertEquals(msgList.isEmpty(), false);
    }
}
