public without sharing class HOT_InterestedResourcesListController {
    
	@AuraEnabled(cacheable = true)
	public static List<HOT_InterestedResource__c> getInterestedResources() {
		Id userId = UserInfo.getUserId();
		List<ServiceResource> serviceResource = [SELECT Id, Name FROM ServiceResource WHERE RelatedRecordId=:userId];
		
		List<HOT_InterestedResource__c> interestedResources = [SELECT Id, Name, Comments__c, toLabel(Status__c), ServiceAppointmentStartTime__c, ServiceAppointmentEndTime__c, ServiceAppointmentAddress__c,
		ServiceAppointmentFreelanceSubject__c, IsNewComment__c, ServiceAppointment__c, AppointmentNumber__c, NumberOfInterestedResources__c, ServiceAppointment__r.HOT_FreelanceSubject__c,
		WorkTypeName__c, ServiceAppointment__r.HOT_DeadlineDate__c, ServiceAppointmentCity__c, ServiceAppointment__r.ServiceTerritory.Name
		FROM HOT_InterestedResource__c 
		WHERE 
		ServiceResource__c IN: serviceResource
		AND
		Status__c NOT IN ('Assigned')];
		return interestedResources;
	}
	
	@AuraEnabled
	public static void retractInterests(List<String> retractionIds){
		List<HOT_InterestedResource__c> interestedResources = [SELECT Id, Status__c
		FROM HOT_InterestedResource__c WHERE Id IN :retractionIds];
		for(HOT_InterestedResource__c IR: interestedResources){
			if(IR.Status__c == 'Interested'){
				IR.Status__c = 'Retracted Interest';
			}
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
	public static void readComment(Id interestedResourceId){
		HOT_InterestedResource__c interestedResource = new HOT_InterestedResource__c(Id = interestedResourceId, IsNewComment__c = false);
		update interestedResource;
	}

	@AuraEnabled
	public static void dispatcherReadComment(Id recordId){
		HOT_InterestedResource__c interestedResource = new HOT_InterestedResource__c(Id = recordId, IsDispatcherNewComment__c = false);
		update interestedResource;
	}

	@AuraEnabled
	public static void addComment(Id interestedResourceId, String newComment){
		if(newComment != null && newComment != ''){
			newComment = UserInfo.getFirstName() + ' ' + UserInfo.getLastName()
			+ ', ' + Datetime.now() + ': ' + newComment;
			HOT_InterestedResource__c interestedResource = [SELECT Id, Comments__c, IsNewComment__c, IsDispatcherNewComment__c FROM HOT_InterestedResource__c WHERE Id =: interestedResourceId];
			if(interestedResource.Comments__c == null){
				interestedResource.Comments__c = newComment;
			}
			else{
			interestedResource.Comments__c = interestedResource.Comments__c + '\n\n' + newComment;
			}
			if(Test.isRunningTest() ? true : UserInfo.getProfileId() == [SELECT Id FROM Profile WHERE Name = 'NAV Samhandler'][0].Id){
					System.debug('IsDispatcherNewComment__c = true');
				interestedResource.IsDispatcherNewComment__c = true;
			}
			else{
				interestedResource.IsNewComment__c = true;
			}
			update interestedResource;
		}
	}

	@InvocableVariable public ID recordId;
	@InvocableVariable public String newComment;

	@InvocableMethod
	public static void addComment(List<HOT_InterestedResourcesListController> inputVariables){
		HOT_InterestedResourcesListController.addComment(inputVariables[0].recordId, inputVariables[0].newComment);
	}


	
}
