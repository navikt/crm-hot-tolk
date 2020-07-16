@isTest
private class HOT_AddCommentControllerTest{

	@testSetup static void setup(){
		WorkType workType = HOT_TestDataFactory.createWorkType();
		insert workType;
		HOT_Request__c request = HOT_TestDataFactory.createRequest('Adding comment', workType);
		insert request;
		
	}

	@isTest static void addCommentTest() {
		HOT_Request__c request = [SELECT Id, MessageToDispatcher__c FROM HOT_Request__c WHERE Subject__c = 'Adding comment'];
		String newComment = 'New Comment';
		String fieldName = 'MessageToDispatcher__c';
		HOT_AddCommentController inputVariables = new HOT_AddCommentController();
		inputVariables.record = request;
		inputVariables.newComment = newComment;
		inputVariables.fieldName = fieldName;
		List<HOT_AddCommentController> inputVariablesList = new List<HOT_AddCommentController>();
		inputVariablesList.add(inputVariables);
		HOT_AddCommentController.addComment(inputVariablesList);
		HOT_Request__c updatedRequest = [SELECT Id, MessageToDispatcher__c FROM HOT_Request__c WHERE Id = :request.Id];
		System.assertEquals(true, updatedRequest.MessageToDispatcher__c.contains('New Comment'), 'Comment was not updated');
		
		newComment = 'Another Comment';
		HOT_AddCommentController.addComment(request, newComment, fieldName);
		HOT_Request__c updatedRequest2 = [SELECT Id, MessageToDispatcher__c FROM HOT_Request__c WHERE Id = :request.Id];
		System.assertEquals(true, updatedRequest2.MessageToDispatcher__c.contains('Another Comment'), 'Comment was not updated');

	}
}