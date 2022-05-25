public with sharing class HOT_ThreadListController {
    @AuraEnabled(cacheable=true)
    public static List<Thread__c> getMyThreads() {
        // TODO: Select read by nav field on message
        List<Thread__c> threads = [
            SELECT
                Id,
                HOT_Subject__c
            FROM Thread__c
            WHERE
                HOT_Account__c = :UserInfo.getUserId()
        ];
        return threads;
    }

    @AuraEnabled
    public static void openThread(Id recordId) {}
}
