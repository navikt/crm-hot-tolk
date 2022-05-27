@isTest
public class CRM_MessageReferenceHandler_Test {
    @isTest
    static void testReferenceGeneration() {
        Test.startTest();
        HOT_DIALOG_TestDataFactory.createRecord(new Message__c());
        Test.stopTest();

        System.assertEquals(1, [SELECT COUNT() FROM Message__c WHERE CRM_API_Reference__c != NULL]);
    }
}
