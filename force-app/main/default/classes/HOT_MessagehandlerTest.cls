@isTest
public with sharing class HOT_MessagehandlerTest {
    @isTest
    public static void messageHandlerTestWithoutDispatcher() {
        Profile pro = [SELECT Id, Name FROM Profile WHERE Name = 'NAV Administrator'];
        User user = HOT_TestDataFactory.createUser('Nøff', pro);
        insert user;

        String personAccountRecordTypeId = Schema.getGlobalDescribe()
            .get('Account')
            .getDescribe()
            .getRecordTypeInfosByDeveloperName()
            .get('PersonAccount')
            .getRecordTypeId();
        Account account = new Account(
            RecordTypeId = personAccountRecordTypeId,
            FirstName = 'Test',
            LastName = 'User',
            PersonEmail = 'HOT_testaccount@nav.hot.no'
        );
        insert Account;

        Person__c person = new Person__c();
        person.INT_Confidential__c = 'UGRADERT';
        person.Name = 'Nasse';
        person.INT_LastName__c = 'Nasse';
        person.INT_FirstName__c = 'Nøff';

        insert person;

        Contact con = new contact();
        con.LastName = 'Nøff';
        con.FirstName = 'Nasse';
        insert con;

        Thread__c t = HOT_TestDataFactory.createThread();
        t.CRM_Related_Object__c = con.Id;
        t.CRM_Account__r = account;
        t.OwnerId = user.Id;

        insert t;

        Message__c m = new Message__c();
        m.CRM_Thread__c = t.Id;
        m.CRM_From_Contact__c = con.Id;
        m.CRM_Message_Text__c = 'YOYOYOYO';

        test.startTest();
        insert m;
        test.stopTest();
    }
    @isTest
    static void messageHandlerTestWithDispatcher() {
        Profile pro = [SELECT Id, Name FROM Profile WHERE Name = 'NAV Administrator'];
        User user = HOT_TestDataFactory.createUser('Lastname', pro);
        insert user;
        String personAccountRecordTypeId = Schema.getGlobalDescribe()
            .get('Account')
            .getDescribe()
            .getRecordTypeInfosByDeveloperName()
            .get('PersonAccount')
            .getRecordTypeId();
        Account account = new Account(
            RecordTypeId = personAccountRecordTypeId,
            FirstName = 'Test',
            LastName = 'User',
            PersonEmail = 'HOT_testaccount@nav.hot.no'
        );
        insert Account;

        Person__c person = new Person__c();
        person.INT_Confidential__c = 'UGRADERT';
        person.Name = 'Nasse';
        person.INT_LastName__c = 'Nasse';
        person.INT_FirstName__c = 'Nøff';

        insert person;

        Contact con = new contact();
        con.LastName = 'Nøff';
        con.FirstName = 'Nasse';
        insert con;

        Thread__c t = HOT_TestDataFactory.createThread();
        t.CRM_Related_Object__c = con.Id;
        t.CRM_Account__r = account;
        t.HOT_Dispatcher__c = user.Id;

        insert t;

        Message__c m = new Message__c();
        m.CRM_Thread__c = t.Id;
        m.CRM_From_Contact__c = con.Id;
        m.CRM_Message_Text__c = 'YOYOYOYO';

        test.startTest();
        insert m;
        test.stopTest();
    }
}
