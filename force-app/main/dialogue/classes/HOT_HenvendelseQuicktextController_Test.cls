@isTest
public with sharing class CRM_HenvendelseQuicktextController_Test {
    @TestSetup
    static void makeData() {
        HOT_DIALOG_TestDataFactory.createQuickTexts(3);
    }
    @isTest
    static void searchRecordsTest() {
        Test.startTest();
        List<CRM_HenvendelseQuicktextController.QuickTextMessage> msgList = CRM_HenvendelseQuicktextController.searchRecords(
            'Melding'
        );
        Test.stopTest();
        System.assertEquals(msgList.isempty(), false);
    }
    @isTest
    static void getQuicktext_Test() {
        List<QuickText> qList = CRM_HenvendelseQuicktextController.getQuicktexts();
    }
}
