@IsTest(IsParallel=true)
private class HOT_ReleaseToFreelanceFlowControllerTest {
    @testSetup
    static void setup() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
    }

    @IsTest
    static void testMethod1() {
        Worktype workType = [SELECT Id FROM WorkType];
        String workTypeId = (String) workType.Id;

        Test.setCurrentPage(Page.HOT_ReleaseToFreelance);
        ApexPages.currentPage().getParameters().put('Id', workTypeId);

        String output = HOT_ReleaseToFreelanceFlowController.getRecordId();
        workType = [SELECT Id FROM WorkType];
        workTypeId = (String) workType.Id;

        System.assertEquals(workTypeId, output);
    }
}
