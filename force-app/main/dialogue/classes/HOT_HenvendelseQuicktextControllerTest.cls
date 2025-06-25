@IsTest
public with sharing class HOT_HenvendelseQuicktextControllerTest {
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

    @IsTest
    static void searchRecords155Test() {
        String msg = 'lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.';
        QuickText q = new QuickText(Name = 'Test Long text ', Message = msg);
        insert q;
        Test.startTest();
        List<HOT_HenvendelseQuicktextController.QuickTextMessage> msgList = HOT_HenvendelseQuicktextController.searchRecords(
            'lorem'
        );
        Test.stopTest();
        System.assertEquals(msgList.isempty(), false);
    }
}
