public with sharing class HOT_ThreadListController {
    @AuraEnabled(cacheable=true)
    public static List<Thread__c> getMyThreads() {
        // TODO: Roll-up field on Thread to check if there are any Message children with CRM_Read_By_NAV__C == true?
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
