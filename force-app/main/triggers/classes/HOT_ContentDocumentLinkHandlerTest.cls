@IsTest(IsParallel=true)
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
    public static void addContentDocumentLinkToWorkOrder() {
        Person__c person = HOT_TestDataFactory.createPerson();
        person.Name = '12015678999';
        insert person;
        Account personAccount = HOT_TestDataFactory.createAccount(true);
        personAccount.INT_PersonIdent__c = '12015678999';
        personAccount.CRM_Person__c = person.Id;
        insert personAccount;

        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert WorkType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('HOT_WorkOrderHandler', workType);
        insert request;

        request.Status__c = 'Godkjent';
        update request;

        WorkOrder workOrder = [
            SELECT Id, HOT_Request__c
            FROM WorkOrder
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

        ContentDocumentLink contentDocumentLinkWorkOrder = [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :workOrder.Id
            LIMIT 1
        ];

        Id requestContentDocumentid = contentDocumentLinkRequest.ContentDocumentId;
        Id workOrderContentDocumentId = contentDocumentLinkWorkOrder.ContentDocumentId;

        System.assertEquals(
            requestContentDocumentId,
            workOrderContentDocumentId,
            'ContentDocumentId fra request og serviceAppointment stemmer ikke overens.'
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
            4,
            contentDocumentLinkRequest.size(),
            'Antallet opprettede dokumenter stemmer ikke overens med forventningene.'
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
        System.assertEquals(1, [SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId = :request.Id]);

        HOT_ContentDocumentLinkService input = new HOT_ContentDocumentLinkService();
        input.recordId = request.Id;
        input.contentDocuments = new List<ContentDocument>{ contentDocument };

        Test.startTest();
        HOT_ContentDocumentLinkService.deleteContentDocumentLink(new List<HOT_ContentDocumentLinkService>{ input });
        Test.stopTest();

        // Verify the ContentDocumentLink was deleted
        List<ContentDocumentLink> linksAfterDelete = [
            SELECT Id
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :request.Id AND ContentDocumentId = :contentDocument.Id
        ];
        System.assertEquals(0, linksAfterDelete.size(), 'ContentDocumentLink should be deleted');
    }

    @IsTest
    public static void addContentDocumentLinkToServiceAppointment_FromWorkOrder() {
        // Base data
        Person__c person = HOT_TestDataFactory.createPerson();
        person.Name = '12015678999';
        insert person;

        Account personAccount = HOT_TestDataFactory.createAccount(true);
        personAccount.INT_PersonIdent__c = '12015678999';
        personAccount.CRM_Person__c = person.Id;
        insert personAccount;

        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;

        // 1) Create a Work Order via the WO handler request
        HOT_Request__c requestWO = HOT_TestDataFactory.createRequest('HOT_WorkOrderHandler', workType);
        insert requestWO;
        requestWO.Status__c = 'Godkjent';
        update requestWO;

        WorkOrder wo = [
            SELECT Id
            FROM WorkOrder
            WHERE HOT_Request__c = :requestWO.Id
            LIMIT 1
        ];

        // Minimal WOLI (no Product/Quantity to avoid org validations)
        WorkOrderLineItem woli = new WorkOrderLineItem(WorkOrderId = wo.Id);
        insert woli;

        // 2) Create a Service Appointment via the existing SA flow
        HOT_Request__c requestSA = HOT_TestDataFactory.createRequest('HOT_ServiceAppointmentHandler', workType);
        insert requestSA;
        requestSA.Status__c = 'Godkjent';
        update requestSA;

        ServiceAppointment sa = [
            SELECT Id
            FROM ServiceAppointment
            WHERE HOT_Request__c = :requestSA.Id
            LIMIT 1
        ];

        // Link that SA to the WOLI so the WO→SA logic picks it up
        sa.HOT_WorkOrderLineItem__c = woli.Id;
        update sa;

        // 3) Create the file ON THE WORK ORDER (not on the request)
        ContentVersion cv = new ContentVersion(
            Title = 'WO file',
            PathOnClient = 'wo-file.jpg',
            VersionData = Blob.valueOf('Test content on WO'),
            IsMajorVersion = true
        );
        insert cv;

        ContentDocument cd = [SELECT Id FROM ContentDocument LIMIT 1];

        ContentDocumentLink cdlOnWO = new ContentDocumentLink(ContentDocumentId = cd.Id, LinkedEntityId = wo.Id);

        Test.startTest();
        insert cdlOnWO; // onAfterInsert should call createContentDocumentLinksFromWOToSA
        Test.stopTest();

        // 4) Assert the same doc is now linked to the Service Appointment
        Id woDocId = [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :wo.Id
            LIMIT 1
        ]
        .ContentDocumentId;

        Id saDocId = [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :sa.Id
            LIMIT 1
        ]
        .ContentDocumentId;

        System.assertEquals(
            woDocId,
            saDocId,
            'ContentDocumentId fra WorkOrder og ServiceAppointment stemmer ikke overens.'
        );
    }
}
