@IsTest(IsParallel=true)
private class HOT_AutoScheduleServiceTest {
    @IsTest
    private static void setAutoScheduleOnServiceAppointmentsTest() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;

        HOT_AutoScheduleService inputVariable = new HOT_AutoScheduleService();
        inputVariable.parentRecordId = request.Id;
        inputVariable.parentRecordType = 'request';
        List<HOT_AutoScheduleService> inputVariables = new List<HOT_AutoScheduleService>();
        inputVariables.add(inputVariable);

        Test.startTest();
        HOT_AutoScheduleService.setAutoScheduleOnServiceAppointments(inputVariables);
        Test.stopTest();
    }
}
