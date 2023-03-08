@isTest
public with sharing class DisableFreelanceUsersSchedulableTest {
    @isTest
    static void schedulableTest() {
        String cron_exp = '0 0 0 3 9 ? 2024';
        Test.startTest();
        String jobId = System.schedule('DisableFreelanceUsersSchedulable', cron_exp, new DisableFreelanceUsersSchedulable());
        Test.stopTest();
        System.assert(jobId != null);
    }
}