@IsTest(IsParallel=true)
private class HOT_KrrCalloutQueuableTest {
    @TestSetup
    static void makeData() {
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
    }

    @IsTest
    static void batchableTest() {
        List<HOT_Request__c> reqs = new List<HOT_Request__c>([SELECT id FROM HOT_Request__c]);

        Test.startTest();
        HOT_KrrCalloutQueuable job = new HOT_KrrCalloutQueuable(reqs);
        ID jobid = System.enqueueJob(job);
        Test.stopTest();

        System.assertNotEquals(null, jobID, 'The job ID should not be null.');
    }
}
