public without sharing class HOT_ThreadListController {
    @AuraEnabled(cacheable=true)
    public static List<Thread__c> getMyThreads() {
        // TODO: Create new checkbox formula field which checks CRM_Number_of_unread_Messages__c and use it in list
        // TODO: Add HOT_Subject__c field when it's in master
        List<Thread__c> threads = [
            SELECT
                Id,
                CRM_Number_of_unread_Messages__c,
                Name
            FROM Thread__c
           // WHERE
                //CRM_Account__c = :UserInfo.getUserId()
        ];
        return threads;
    }

    @AuraEnabled
    public static void openThread(Id recordId) {}
}
