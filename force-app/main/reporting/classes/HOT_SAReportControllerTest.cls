@IsTest(IsParallel=true)
private class HOT_SAReportControllerTest {
    @testSetup
    static void setup() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('Bestilling', workType);
        insert request;
        request.Status__c = 'Godkjent';
        update request;
    }

    @IsTest
    static void upsertReportingDataTest() {
        Test.startTest();
        HOT_ServiceAppointmentReportController btch = new HOT_ServiceAppointmentReportController();
        Database.executeBatch(btch, 2000);
        Test.stopTest();

        List<ReportingData__c> reportingData = [SELECT Id FROM ReportingData__c];
        System.assertEquals(reportingData.size(), 1);

        ServiceAppointment serviceAppointment = [SELECT Id, Subject FROM ServiceAppointment LIMIT 1];
        serviceAppointment.Subject = 'Nummer 2';
        update serviceAppointment;

        Database.executeBatch(btch, 2000);

        List<ReportingData__c> reportingData2 = [SELECT Id FROM ReportingData__c];
        System.assertEquals(reportingData2.size(), 1);
    }
}
