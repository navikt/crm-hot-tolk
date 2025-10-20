@IsTest
public class HOT_RecordInfoControllerTest {
    @TestSetup
    static void makeData() {
        HOT_ST_TestDataFactory.createRecord(new LiveChatTranscript());
    }

    @IsTest
    static void getRelatedRecordTest() {
        LiveChatTranscript trans = [SELECT Id FROM LiveChatTranscript LIMIT 1];

        Test.startTest();
        trans = (LiveChatTranscript) HOT_RecordInfoController.getRelatedRecord(
            String.valueOf(trans.Id),
            'LiveChatVisitorId',
            'LiveChatTranscript'
        );
        Test.stopTest();

        System.assertNotEquals(null, trans.LiveChatVisitorId);
    }

    @IsTest
    static void getReverseRelatedRecordTest() {
        LiveChatVisitor vis = [SELECT Id FROM LiveChatVisitor LIMIT 1];
        List<LiveChatTranscript> trans;
        Test.startTest();
        trans = (List<LiveChatTranscript>) HOT_RecordInfoController.getReverseRelatedRecord(
            String.valueOf(vis.Id),
            'Id',
            'LiveChatTranscript',
            'LiveChatVisitorId'
        );
        Test.stopTest();

        System.assertNotEquals(0, trans.size());
        System.assertNotEquals(null, trans[0].Id);
    }
}
