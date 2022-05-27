public with sharing class HOT_ThreadListController {
    @AuraEnabled(cacheable=true)
    public static List<Thread__c> getMyThreads() {
        List<Thread__c> threads = [
            SELECT
                Id,
                HOT_Subject__c,
                CRM_Number_of_unread_Messages__c
            FROM Thread__c
            WHERE
                HOT_Account__c = :UserInfo.getUserId()
        ];
        return threads;
    }

    @AuraEnabled
    public static void openThread(Id recordId) {}
}
