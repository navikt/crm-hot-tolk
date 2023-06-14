public without sharing class HOT_ThreadDetailController {
    @AuraEnabled(cacheable=true)
    public static Thread__c getRecord(Id recordId) {
       Thread__c thread= [SELECT HOT_Subject__c, CRM_Is_Closed__c, CRM_Thread_Type__c, CRM_Related_Object__c FROM Thread__c WHERE Id = :recordId LIMIT 1];
        return thread;
    }
}