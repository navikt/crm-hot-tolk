public with sharing class HOT_RequestListContoller {

	@AuraEnabled(cacheable = true)
	public static List<HOT_Request__c> getRequestList() {
		return [SELECT Id, Name, UserName__c FROM HOT_Request__c];
	}
}