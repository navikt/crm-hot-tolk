public with sharing class HOT_RequestListContoller {

	@AuraEnabled(cacheable = true)
	public static List<HOT_Request__c> getRequestList() {
		return [SELECT UserName__c, Name, AssigmentInformation__c, StartTime__c, EndTime__c, Status__c FROM HOT_Request__c];
	}
}