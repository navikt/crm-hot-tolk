public without sharing class HOT_InterestedResourcesListController {
    
	@AuraEnabled(cacheable = true)
	public static List<HOT_InterestedResource__c> getInterestedResources() {
		Id userId = UserInfo.getUserId();
		List<ServiceResource> serviceResource = [SELECT Id, Name FROM ServiceResource WHERE RelatedRecordId=:userId];
		
		List<HOT_InterestedResource__c> interestedResources = [SELECT Id, Name, Comments__c, Status__c, ServiceAppointmentTime__c, ServiceAppointmentAddress__c,
		ServiceAppointment__r.HOT_FreelanceSubject__c
		FROM HOT_InterestedResource__c WHERE ServiceResource__c IN: serviceResource];

		return interestedResources;
	}
	
	@AuraEnabled
	public static void retractInterests(List<String> retractionIds){
		List<HOT_InterestedResource__c> interestedResources = [SELECT Id, Status__c
		FROM HOT_InterestedResource__c WHERE Id IN :retractionIds];
		for(HOT_InterestedResource__c IR: interestedResources){
			IR.Status__c = 'Retracted Interest';
		}
		update interestedResources;	
	}
	@AuraEnabled
	public static void resendInterest(Id interestedId){
		HOT_InterestedResource__c interestedResource = [SELECT Id, Status__c
		FROM HOT_InterestedResource__c WHERE Id = :interestedId];
		interestedResource.Status__c = 'Interested';
		update interestedResource;	
	}

	@AuraEnabled
	public static void addComment(Id interestedResourceId, String newComment){
		ServiceResource serviceResource = [SELECT Id, Name FROM ServiceResource WHERE RelatedRecordId = :UserInfo.getUserId()];
		newComment = UserInfo.getFirstName() + ' ' + UserInfo.getLastName()
		+ ', ' + Datetime.now() + ': ' + newComment;
		HOT_InterestedResource__c interestedResource = [SELECT Id, Comments__c FROM HOT_InterestedResource__c WHERE Id =: interestedResourceId];
		if(interestedResource.Comments__c == null){
			interestedResource.Comments__c = newComment;
		}
		else{
		interestedResource.Comments__c = interestedResource.Comments__c + '\n\n' + newComment;
		}
		update interestedResource;
	}

		@InvocableVariable public ID recordId;
		@InvocableVariable public String newComment;
	
		@InvocableMethod
		public static void addComment(List<HOT_InterestedResourcesListController> inputVariables){
			HOT_InterestedResourcesListController.addComment(inputVariables[0].recordId, inputVariables[0].newComment);
		}
	
}
