@isTest
private class HOT_IRListControllerTest{

	@testSetup static void setup(){

		Serviceresource serviceResource = HOT_TestDataFactory.createServiceResource(UserInfo.getUserId());
		insert serviceResource;
		WorkType workType = HOT_TestDataFactory.createWorkType();
		insert workType;
		HOT_Request__c request = HOT_TestDataFactory.createRequest('Bestilling', workType);
		insert request;
		request.Status__c = 'Godkjent';
		update request;

		ServiceAppointment serviceAppointment = [SELECT Id FROM ServiceAppointment];
		Hot_interestedresource__c interestedResource = new Hot_interestedresource__c (
			ServiceAppointment__c = serviceAppointment.Id,
			ServiceResource__c = serviceResource.Id,
			Comments__c = 'Test Value', 
			Status__c ='Interested'
		);
		insert interestedResource;
		 
	}

	@isTest static void getInterestedResourcesTest() {
		List<HOT_InterestedResource__c> interestedResources = HOT_InterestedResourcesListController.getInterestedResources();
		System.assertEquals(1, interestedResources.size(), 'Could not get list of interested resources');
	}

	@isTest static void retractInterestsTest() {
		HOT_InterestedResource__c interestedResource = [SELECT Id, Status__c FROM HOT_InterestedResource__c];
		List<Id> retractionIds = new List<Id>{interestedResource.Id};
		HOT_InterestedResourcesListController.retractInterests(retractionIds);
		HOT_InterestedResource__c updatedInterestedResource = [SELECT Id, Status__c FROM HOT_InterestedResource__c WHERE Id = :interestedResource.Id];
		System.assertEquals('Retracted Interest', updatedInterestedResource.Status__c, 'Status was not updated');
	}
	@isTest static void resendInterestTest() {
		HOT_InterestedResource__c interestedResource = [SELECT Id, Status__c FROM HOT_InterestedResource__c];
		List<Id> retractionIds = new List<Id>{interestedResource.Id};
		HOT_InterestedResourcesListController.retractInterests(retractionIds);
		HOT_InterestedResourcesListController.resendInterest(interestedResource.Id);
		HOT_InterestedResource__c updatedInterestedResource = [SELECT Id, Status__c FROM HOT_InterestedResource__c WHERE Id = :interestedResource.Id];
		System.assertEquals('Interested', updatedInterestedResource.Status__c, 'Status was not updated');
	}
	@isTest static void addCommentTest() {
		HOT_InterestedResource__c interestedResource = [SELECT Id, Comments__c FROM HOT_InterestedResource__c];
		String newComment = 'New Comment';
		HOT_InterestedResourcesListController.addComment(interestedResource.Id, newComment);
		HOT_InterestedResource__c updatedInterestedResource = [SELECT Id, Comments__c FROM HOT_InterestedResource__c WHERE Id = :interestedResource.Id];
		System.debug(updatedInterestedResource.Comments__c);
		System.assertEquals(true, updatedInterestedResource.Comments__c.contains('New Comment'), 'Comment was not updated');
	}

	@isTest static void readCommentTest(){
		HOT_InterestedResource__c interestedResource = [SELECT Id, IsNewComment__c FROM HOT_InterestedResource__c];
		interestedResource.IsNewComment__c = true;
		update interestedResource;
		HOT_InterestedResourcesListController.readComment(interestedResource.Id);
		interestedResource = [SELECT Id, IsNewComment__c FROM HOT_InterestedResource__c];
		System.assertEquals(false, interestedResource.IsNewComment__c, 'Could not set IsNewComment__c');
	}

	@isTest static void dispatcherReadCommentTest(){
		HOT_InterestedResource__c interestedResource = [SELECT Id, IsDispatcherNewComment__c FROM HOT_InterestedResource__c];
		interestedResource.IsDispatcherNewComment__c = true;
		update interestedResource;
		HOT_InterestedResourcesListController.dispatcherReadComment(interestedResource.Id);
		interestedResource = [SELECT Id, IsDispatcherNewComment__c FROM HOT_InterestedResource__c];
		System.assertEquals(false, interestedResource.IsDispatcherNewComment__c, 'Could not set IsDispatcherNewComment__c');
	}

	@isTest static void dispatcherAddCommentTest(){
		HOT_InterestedResource__c interestedResource = [SELECT Id FROM HOT_InterestedResource__c];
		HOT_InterestedResourcesListController interestedResourcesListController = new HOT_InterestedResourcesListController();
		interestedResourcesListController.recordId = interestedResource.Id;
		interestedResourcesListController.newComment = 'New Comment From Dispatcher';
		HOT_InterestedResourcesListController.addComment(new List<HOT_InterestedResourcesListController>{interestedResourcesListController});
		interestedResource = [SELECT Id, IsDispatcherNewComment__c FROM HOT_InterestedResource__c];
		System.assertEquals(true, interestedResource.IsDispatcherNewComment__c, 'Could not set IsDispatcherNewComment__c');

	}
}