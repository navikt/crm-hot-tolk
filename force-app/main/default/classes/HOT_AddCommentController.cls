public without sharing class HOT_AddCommentController {
    @AuraEnabled
    public static void addComment(SObject record, String newComment, String fieldName) {
        if (newComment != null && newComment != '') {
            newComment =
                UserInfo.getFirstName() +
                ' ' +
                UserInfo.getLastName() +
                ', ' +
                Datetime.now() +
                ': ' +
                newComment;
            if (record.get(fieldName) == null) {
                record.put(fieldName, newComment);
            } else {
                record.put(fieldName, newComment + '\n\n' + record.get(fieldName));
            }
            update record;
        }
    }

    @InvocableVariable
    public SObject record;
    @InvocableVariable
    public String newComment;
    @InvocableVariable
    public String fieldName;

    @InvocableMethod
    public static void addComment(List<HOT_AddCommentController> inputVariables) {
        HOT_AddCommentController.addComment(
            inputVariables[0].record,
            inputVariables[0].newComment,
            inputVariables[0].fieldName
        );
    }
}
