@IsTest
private with sharing class HOT_KrrErrorBatchTest {
    @IsTest
    static void batchableTest() {
        Person__c person = HOT_TestDataFactory.createPerson();
        person.Name = 'Person test';
        person.INT_KrrIntegrationStatus__c = 'Failed';
        person.HOT_WorkplaceInterpreter__c = true;
        insert person;
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('requesttest', workType);
        request.Person__c = person.Id;
        insert request;

        HOT_KrrErrorBatch instance = new HOT_KrrErrorBatch();
        Test.startTest();
        database.executebatch(instance);
        Test.stopTest();

        Person__c personRes = [SELECT HOT_KrrIntegrationErrorCounter__c FROM Person__c WHERE Id = :person.Id];
        // Counter will be 1 after Request insert, then 2 after batch also fails
        System.assertEquals(2, personRes.HOT_KrrIntegrationErrorCounter__c);
    }

    @IsTest
    static void schedulableTest() {
        String cron_exp = '0 0 0 3 9 ? 2024';
        Test.startTest();
        String jobId = System.schedule('HOT_KrrErrorBatch', cron_exp, new HOT_KrrErrorBatch());
        Test.stopTest();
        System.assert(jobId != null);
    }
}
