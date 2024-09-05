@IsTest
private class HOT_SAReportingSchedulableTest {
    private static String CRON_EXP = '0 0 0 3 9 ? 2099';

    @testSetup
    static void setup() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('Subject', worktype);
        insert request;
        request.Status__c = 'Godkjent';
        update request;
    }

    @IsTest
    private static void execute() {
        Test.startTest();
        String jobId = System.schedule('HOT_SAReportingSchedulable', CRON_EXP, new HOT_SAReportingSchedulable());
        Test.stopTest();
        System.assert(jobId != null);
        List<ReportingData__c> reportingData = [SELECT Id FROM ReportingData__c];
        System.assertEquals(reportingData.size(), 0);
    }
}
