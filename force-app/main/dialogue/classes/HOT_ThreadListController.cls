public with sharing class HOT_ThreadListController {
    @AuraEnabled(cacheable=true)
    public static List<Thread__c> getMyThreads() {
        User user = [SELECT AccountId FROM User WHERE Id = :UserInfo.getUserId()];
        List<Thread__c> threads = [
            SELECT Id, HOT_Subject__c, CRM_Number_of_unread_Messages__c
            FROM Thread__c
            WHERE
                CRM_Account__c = :user.AccountId
                AND CRM_Account__c != NULL
                AND CRM_Type__c = 'HOT_BRUKER-FORMIDLER'
                AND HOT_Request__c != NULL
                AND CRM_Number_of_Messages__c > 0
                AND (HOT_Request__r.IsDone__c = FALSE
                OR CRM_Number_of_unread_Messages__c > 0)
        ];
        return threads;
    }
}
