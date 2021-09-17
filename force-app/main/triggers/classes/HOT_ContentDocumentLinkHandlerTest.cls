@isTest
private class HOT_ContentDocumentLinkHandlerTest {
    @testSetup
    static void setup() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert WorkType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('HOT_ServiceAppointmentHandler', workType);
        insert request;

        request.Status__c = 'Godkjent';
        update request;
    }

    @isTest
    public static void addContentDocumentLinkToServiceAppointment() {
        HOT_Request__c request = [SELECT Id FROM HOT_Request__c LIMIT 1];
        ServiceAppointment serviceAppointment = [
            SELECT Id, HOT_Request__c
            FROM ServiceAppointment
            WHERE HOT_Request__c = :request.Id
            LIMIT 1
        ];

        ContentVersion contentVersion = new ContentVersion(
            Title = 'a picture',
            PathOnClient = 'Pic.jpg',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        insert contentVersion;

        ContentDocument contentDocument = [SELECT Id FROM ContentDocument LIMIT 1];

        ContentDocumentLink contentDocumentLink = new ContentDocumentLink(
            ContentDocumentId = contentDocument.Id,
            LinkedEntityId = request.Id
        );

        Test.startTest();
        insert contentDocumentLink;
        Test.stopTest();

        ContentDocumentLink contentDocumentLinkRequest = [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :request.Id
            LIMIT 1
        ];

        ContentDocumentLink contentDocumentLinkServiceAppointment = [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :serviceAppointment.Id
            LIMIT 1
        ];

        Id requestContentDocumentid = contentDocumentLinkRequest.ContentDocumentId;
        Id serviceAppointmentContentDocumentId = contentDocumentLinkServiceAppointment.ContentDocumentId;

        System.assertEquals(
            requestContentDocumentId,
            serviceAppointmentContentDocumentId,
            'ContentDocumentId fra request og serviceAppointment stemmer ikke overens.'
        );
    }
}
