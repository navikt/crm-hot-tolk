@IsTest
private class HOT_ContentDocumentLinkHandlerTest {
    @testSetup
    static void setup() {
    }

    @IsTest
    public static void addContentDocumentLinkToServiceAppointment() {
        Person__c person = HOT_TestDataFactory.createPerson();
        person.Name = '12015678999';
        insert person;
        Account personAccount = HOT_TestDataFactory.createAccount(true);
        personAccount.INT_PersonIdent__c = '12015678999';
        personAccount.CRM_Person__c = person.Id;
        insert personAccount;

        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert WorkType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('HOT_ServiceAppointmentHandler', workType);
        insert request;

        request.Status__c = 'Godkjent';
        update request;

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

    @IsTest
    public static void addContentDocumentLinkToAccount() {
        Person__c person = HOT_TestDataFactory.createPerson();
        person.Name = '12015678999';
        insert person;
        Account personAccount = HOT_TestDataFactory.createAccount(true);
        personAccount.INT_PersonIdent__c = '12015678999';
        personAccount.CRM_Person__c = person.Id;
        insert personAccount;

        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert WorkType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('HOT_ServiceAppointmentHandler', workType);
        request.Account__c = personAccount.Id;
        insert request;

        request.Status__c = 'Godkjent';
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

    @IsTest
    public static void addContentDocumentLinkToAccountNoAccountTest() {
        Person__c person = HOT_TestDataFactory.createPerson();
        person.Name = '12015678999';
        insert person;
        Account personAccount = HOT_TestDataFactory.createAccount(true);
        personAccount.INT_PersonIdent__c = '12015678999';
        personAccount.CRM_Person__c = person.Id;
        insert personAccount;

        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert WorkType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('HOT_ServiceAppointmentHandler', workType);
        insert request;

        request.Status__c = 'Godkjent';
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
            3,
            'Det har blitt opprettet en ContentDocumetLink for mye.'
        );
    }

    @isTest
    static void testDeleteContentDocumentLink() {
        Person__c person = HOT_TestDataFactory.createPerson();
        person.Name = '12015678999';
        insert person;
        Account personAccount = HOT_TestDataFactory.createAccount(true);
        personAccount.INT_PersonIdent__c = '12015678999';
        personAccount.CRM_Person__c = person.Id;
        insert personAccount;

        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert WorkType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('HOT_ServiceAppointmentHandler', workType);
        insert request;

        request.Status__c = 'Godkjent';
        update request;

        ContentVersion contentVersion = new ContentVersion(
            Title = 'a picture',
            PathOnClient = 'Pic.jpg',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        insert contentVersion;

        ContentDocument contentDocument = [SELECT Id FROM ContentDocument LIMIT 1];
        List<ContentDocument> cdi = new List<ContentDocument>();
        cdi.add(contentDocument);

        ContentDocumentLink contentDocumentLink = new ContentDocumentLink(
            ContentDocumentId = contentDocument.Id,
            LinkedEntityId = request.Id
        );
        insert contentDocumentLink;

        // Assert the link exists before delete
        System.assertEquals(1, [SELECT Count() FROM ContentDocumentLink WHERE LinkedEntityId = :request.Id]);

        HOT_ContentDocumentLinkService input = new HOT_ContentDocumentLinkService();
        input.recordId = request.Id;
        input.contentDocuments = new List<ContentDocument>{ contentDocument };

        Test.startTest();
        HOT_ContentDocumentLinkService.deleteContentDocumentLink(new List<HOT_ContentDocumentLinkService>{ input });
        Test.stopTest();

        // Verify the ContentDocumentLink was deleted
        List<ContentDocumentLink> linksAfterDelete = [
            SELECT Id FROM ContentDocumentLink
            WHERE LinkedEntityId = :request.Id AND ContentDocumentId = :contentDocument.Id
        ];
        System.assertEquals(0, linksAfterDelete.size(), 'ContentDocumentLink should be deleted');
    }
}
