@isTest
public with sharing class HOT_DisableFreelanceSchedulableTest {
    @isTest
    static void schedulableTest() {
        String cron_exp = '0 0 0 3 9 ? 2024';
        Test.startTest();
        String jobId = System.schedule(
            'HOT_DisableFreelanceSchedulable',
            cron_exp,
            new HOT_DisableFreelanceSchedulable()
        );
        Test.stopTest();
        System.assert(jobId != null);
    }
}
