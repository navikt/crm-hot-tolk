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

    @isTest
    public static void addContentDocumentLinkToAccount() {
        Person__c person = HOT_TestDataFactory.createPerson();
        person.Name = '12015678999';
        insert person;
        Account personAccount = HOT_TestDataFactory.createAccount(true);
        personAccount.INT_PersonIdent__c = '12015678999';
        personAccount.CRM_Person__c = person.Id;
        insert personAccount;

        HOT_Request__c request = [SELECT Id, Account__c FROM HOT_Request__c LIMIT 1];
        request.Account__c = personAccount.Id;
        update request;

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

        ContentDocumentLink contentDocumentLinkAccount = [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :personAccount.Id
            LIMIT 1
        ];

        Id requestContentDocumentid = contentDocumentLinkRequest.ContentDocumentId;
        Id accountContentDocumentId = contentDocumentLinkAccount.ContentDocumentId;

        System.assertEquals(
            requestContentDocumentId,
            accountContentDocumentId,
            'ContentDocumentId fra request og account stemmer ikke overens.'
        );
    }

    @isTest
    public static void addContentDocumentLinkToAccountNoAccountTest() {
        HOT_Request__c request = [SELECT Id, Account__c FROM HOT_Request__c LIMIT 1];
        update request;

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

        List<ContentDocumentLink> contentDocumentLinkRequest = [
            SELECT Id
            FROM ContentDocumentLink
            WHERE ContentDocumentId = :contentDocument.Id
        ];

        System.assertEquals(
            contentDocumentLinkRequest.size(),
            2,
            'Det har blitt opprettet en ContentDocumetLink for mye.'
        );
    }
}
