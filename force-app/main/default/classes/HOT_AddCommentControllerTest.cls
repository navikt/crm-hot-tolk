@IsTest(IsParallel=true)
private class HOT_AddCommentControllerTest {
    @testSetup
    static void setup() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('Adding comment', workType);
        insert request;
    }

    //Endre til SOQL (tekst)
    @IsTest
    static void addCommentTest() {
        String requestSOQL = 'SELECT Id, MessageToDispatcher__c FROM HOT_Request__c WHERE Subject__c = \'Adding comment\'';
        SObject request = Database.query(requestSOQL)[0];
        String newComment = 'New Comment';
        String fieldName = 'MessageToDispatcher__c';
        HOT_AddCommentController inputVariables = new HOT_AddCommentController();
        inputVariables.record = request;
        inputVariables.newComment = newComment;
        inputVariables.fieldName = fieldName;
        List<HOT_AddCommentController> inputVariablesList = new List<HOT_AddCommentController>();
        inputVariablesList.add(inputVariables);
        HOT_AddCommentController.addComment(inputVariablesList);
        requestSOQL = 'SELECT Id, MessageToDispatcher__c FROM HOT_Request__c WHERE Id = \'' + request.Id + '\'';
        SObject updatedRequest = Database.query(requestSOQL)[0];
        String comment = (String) updatedRequest.get('MessageToDispatcher__c');
        System.assertEquals(true, comment.contains('New Comment'), 'Comment was not updated');

        newComment = 'Another Comment';
        HOT_AddCommentController.addComment(request, newComment, fieldName);
        requestSOQL = 'SELECT Id, MessageToDispatcher__c FROM HOT_Request__c WHERE Id = \'' + request.Id + '\'';
        SObject updatedRequest2 = Database.query(requestSOQL)[0];
        String comment2 = (String) updatedRequest2.get('MessageToDispatcher__c');
        System.assertEquals(true, comment2.contains('Another Comment'), 'Comment was not updated');
    }
}
