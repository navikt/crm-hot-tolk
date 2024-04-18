@IsTest
public with sharing class HOT_HenvendelseQuicktextController_Test {
    @TestSetup
    static void makeData() {
        HOT_DIALOG_TestDataFactory.createQuickTexts(3);
    }
    @IsTest
    static void searchRecordsTest() {
        Test.startTest();
        List<HOT_HenvendelseQuicktextController.QuickTextMessage> msgList = HOT_HenvendelseQuicktextController.searchRecords(
            'Melding'
        );
        Test.stopTest();
        System.assertEquals(msgList.isempty(), false);
    }
    @IsTest
    static void getQuicktext_Test() {
        List<QuickText> qList = HOT_HenvendelseQuicktextController.getQuicktexts();
    }
}
