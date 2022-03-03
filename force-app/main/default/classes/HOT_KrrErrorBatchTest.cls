@isTest
private with sharing class HOT_KrrErrorBatchTest {
    @isTest
    static void batchableTest() {
        Person__c person = HOT_TestDataFactory.createPerson();
        person.Name = 'Person test';
        person.HOT_IntegrationErrorCounter__c = 1;
        person.INT_KrrIntegrationStatus__c = 'Failed';
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
    }

    @isTest
    static void schedulableTest() {
        String cron_exp = '0 0 0 3 9 ? 2022';
        Test.startTest();
        String jobId = System.schedule(
            'HOT_KrrErrorBatch',
            cron_exp,
            new HOT_KrrErrorBatch()
        );
        Test.stopTest();
        System.assert(jobId != null);
    }
}
