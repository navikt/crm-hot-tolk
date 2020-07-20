public with sharing class HOT_UserContactInformationController {

	@AuraEnabled
    public static Person__c getPerson() {
        User currentUser = [SELECT Id, AccountId, Account.CRM_Person__c FROM User WHERE Id = :UserInfo.getUserId()];
        Person__c person = [SELECT Id, INT_Email__c, INT_MobilePhone__c FROM Person__c WHERE Id = :currentUser.Account.CRM_Person__c];
        return person;
    }
}
