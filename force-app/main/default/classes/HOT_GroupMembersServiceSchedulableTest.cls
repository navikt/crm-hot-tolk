@isTest
public with sharing class HOT_GroupMembersServiceSchedulableTest {
    
    private static String CRON_EXP = '0 0 0 3 9 ? 2022';

    @IsTest
    private static void execute(){
        Test.startTest();
        String jobId = System.schedule('HOT_GroupMembersServiceSchedulable', CRON_EXP, new HOT_GroupMembersServiceSchedulable());
        Test.stopTest();
        System.assert(jobId!=null);
    }
}
