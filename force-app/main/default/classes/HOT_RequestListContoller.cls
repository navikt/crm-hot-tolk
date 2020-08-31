public with sharing class HOT_RequestListContoller {

	@AuraEnabled(cacheable = true)
	public static List<HOT_Request__c> getRequestList() {
		Id userId = UserInfo.getUserId();
		User user = [SELECT Id, AccountId, Name FROM User WHERE Id = : userId];
		//Orig
		List<HOT_Request__c> requests = [SELECT Name, Subject__c, StartTime__c, EndTime__c, MeetingStreet__c, MeetingPostalCode__c, 
		MeetingPostalCity__c, InterpretationStreet__c, InterpretationPostalCode__c, InterpretationPostalCity__c, 
		Description__c, Status__c, ExternalRequestStatus__c, Account__c, (SELECT ServiceAppointment.HOT_ServiceResource__r.Name FROM HOT_Request__c.ServiceAppointments__r),
		Source__c, Type__c, EventType__c, Orderer__r.Name, OrdererPhone__c, OrdererEmail__c, UserName__c, UserPersonNumber__c, Company__r.Name, OrganizationNumber__c, InvoiceReference__c, AdditionalInvoicetext__c
		FROM HOT_Request__c WHERE Account__c !=null AND Account__c = : user.AccountId ORDER BY StartTime__c ASC];
		return requests;
	}

	@AuraEnabled(cacheable = true)
	public static List<HOT_Request__c> getRequestListFromAccountFromRequestId(Id recordId) {
		HOT_Request__c currentRecord = [SELECT Id, Name, Account__c FROM HOT_Request__c WHERE Id = :recordId];
		List<HOT_Request__c> requests = [SELECT Name, Id, StartTime__c, EndTime__c, Status__c, Account__c, ExternalRequestStatus__c
		FROM HOT_Request__c WHERE Account__c !=null AND Account__c = : currentRecord.Account__c];
		return requests;
	}
}