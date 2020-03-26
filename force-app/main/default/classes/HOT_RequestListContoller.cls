public with sharing class HOT_RequestListContoller {

	@AuraEnabled(cacheable = true)
	public static List<HOT_Request__c> getRequestList() {
		Id userId = UserInfo.getUserId();
		User user = [SELECT Id, AccountId, Name FROM User WHERE Id = : userId];
		//Orig
		List<HOT_Request__c> requests = [SELECT Name, Subject__c, StartTime__c, EndTime__c, MeetingStreet__c, MeetingPostalCode__c, 
		MeetingPostalCity__c, InterpretationStreet__c, InterpretationPostalCode__c, InterpretationPostalCity__c, 
		Description__c, Status__c, ExternalRequestStatus__c, Account__c
		FROM HOT_Request__c WHERE Account__c !=null AND Account__c = : user.AccountId ORDER BY StartTime__c ASC];
		return requests;
	}
}