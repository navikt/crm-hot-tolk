public with sharing class HOT_RequestListContoller {

	@AuraEnabled(cacheable = true)
	public static List<HOT_Request__c> getRequestList() {
		Id userId = UserInfo.getUserId();
		User user = [SELECT Id, AccountId FROM User WHERE Id = : userId];

		//Only gets Users Requests (This is the one that should be used in Live)
		//return [SELECT Name, AssigmentInformation__c, InterpretationAddress__c, MeetingAddress__c, StartTime__c, Duration__c, Status__c FROM HOT_Request__c WHERE Account__c = : user.AccountId];

		//Gets ALL requests
		return [SELECT Name, AssigmentInformation__c, InterpretationAddress__c, MeetingAddress__c, StartTime__c, Duration__c, EndTime__c, Status__c FROM HOT_Request__c];
	}
}