@isTest
public with sharing class HOT_DisableFreelancePart2SchedulableTest {
    @isTest
    static void schedulableTest() {
        String cron_exp = '0 0 0 3 9 ? 2099';
        Test.startTest();
        String jobId = System.schedule(
            'HOT_DisableFreelancePart2Schedulable',
            cron_exp,
            new HOT_DisableFreelancePart2Schedulable()
        );
        Test.stopTest();
        System.assert(jobId != null);
    }
}
