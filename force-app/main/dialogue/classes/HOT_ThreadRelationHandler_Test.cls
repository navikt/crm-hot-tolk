@isTest
public class CRM_ThreadRelationHandler_Test {
    @isTest
    static void testRelationHandling() {
        Account acc = (Account) HOT_DIALOG_TestDataFactory.createRecord(new Account());
        HOT_DIALOG_TestDataFactory.createRecord(new Thread__c(CRM_Related_Object__c = acc.Id));

        Thread__c thread = [SELECT Id, CRM_Related_Object__c, CRM_Related_Object_Type__c FROM Thread__c LIMIT 1];
        System.assertEquals('Account', thread.CRM_Related_Object_Type__c);

        Test.startTest();
        thread.CRM_Related_Object__c = thread.Id;
        update thread;
        Test.stopTest();

        Thread__c updatedThread = [
            SELECT Id, CRM_Related_Object__c, CRM_Related_Object_Type__c
            FROM Thread__c
            WHERE ID = :thread.Id
        ];
        System.assertEquals('Thread__c', updatedThread.CRM_Related_Object_Type__c);
    }
}
