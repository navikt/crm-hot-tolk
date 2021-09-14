@isTest
private class HOT_RelatedFilesListControllerTest {
    @testSetup
    static void setup() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('Subject', workType);
        insert request;

        ContentVersion contentVersion = HOT_TestDataFactory.createContentVersion();
        insert contentVersion;
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        ContentDocumentLink contentDocumentLink = HOT_TestDataFactory.createContentDocumentLink(
            request.Id,
            documents[0].Id
        );
        insert contentDocumentLink;
    }

    @isTest
    static void testMethod1() {
        HOT_Request__c request = [SELECT Id FROM HOT_Request__c LIMIT 1];
        List<ContentDocument> contentDocuments = HOT_RelatedFilesListController.getContentDocuments(request.Id);
        System.assertEquals(1, contentDocuments.size(), 'Could not get ContentDocuments');
    }
}
