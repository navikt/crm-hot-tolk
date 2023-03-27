@isTest
public class HOT_ThreadListControllerTest {
    @TestSetup
    static void makeData() {
        Person__c person = HOT_TestDataFactory.createPerson('01010112345');
        insert person;
        Account account = [SELECT Id FROM Account];
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        request.Account__c = account.Id;
        insert request;

        Thread__c t = new Thread__c();
        t.HOT_Request__c = request.Id;

        Thread__c t2 = new Thread__c();
        t2.HOT_Request__c = request.Id;

        Thread__c t3 = new Thread__c();
        t3.HOT_Request__c = request.Id;

        HOT_DIALOG_TestDataFactory.createRecordList(new List<Thread__c>{ t, t2, t3 });
    }

    @isTest
    public static void getMyThreadsTest() {
        List<Thread__c> threadList = HOT_ThreadListController.getMyThreads();

        System.assertEquals(0, threadList.size(), 'Could not get my threads'); // Can't get current running user in test
    }
}
