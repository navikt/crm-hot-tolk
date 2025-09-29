@isTest(IsParallel=true)
private class HOT_ContentVersionHandlerTest {
    @isTest
    static void createDocumentLinks() {
        WorkType workType = HOT_TestDataFactory.createWorkType();

        insert WorkType;

        HOT_Request__c request = HOT_TestDataFactory.createRequest('HOT_ServiceAppointmentHandler', workType);

        insert request;

        ContentVersion cv1 = new ContentVersion(
            Title = 'Test1',
            PathOnClient = 'test.txt',
            VersionData = Blob.valueOf('Test ContentVersion'),
            FirstPublishLocationId = request.Id
        );
        ContentVersion cv2 = new ContentVersion(
            Title = 'Test2',
            PathOnClient = 'test.txt',
            VersionData = Blob.valueOf('Test ContentVersion'),
            HOT_RelatedRecordId_fileupload__c = request.Id
        );

        Test.startTest();
        insert new List<ContentVersion>{ cv1, cv2 };
        Test.stopTest();

        List<ContentDocumentLink> contentDocumentLinks = [
            SELECT ContentDocumentId, LinkedEntityId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :request.Id
        ];

        System.Assert.areEqual(2, contentDocumentLinks.size(), 'Could not create ContentDocumentLink');
    }
}
