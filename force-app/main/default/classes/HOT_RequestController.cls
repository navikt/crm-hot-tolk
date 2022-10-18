public with sharing class HOT_RequestController {
     @AuraEnabled
    public static Boolean isUserDeaceased(String requestId) {
         HOT_Request__c request = [SELECT Person__r.INT_IsDeceased__c FROM HOT_Request__c WHERE Id = :requestId];
        if(request!=null){
            return request.Person__r.INT_IsDeceased__c ;
        }
        return false;
        
    }
}
