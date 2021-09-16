@isTest
private class HOT_ContentDocumentLinkHandlerTest {
    @testSetup
    static void setup() {
        OperatingHours operatingHours = HOT_TestDataFactory.createOperatingHours();
        insert operatingHours;
        ServiceTerritory serviceTerritory = HOT_TestDataFactory.createServiceTerritory(operatingHours);
        insert serviceTerritory;

        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' OR Name = 'Standardbruker' LIMIT 1];
        User user = HOT_TestDataFactory.createUser('user', profile);
        insert user;
        ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(user.Id);
        serviceResource.HOT_IsFreelanceInterpreter__c = true;
        insert serviceResource;
        ServiceTerritoryMember serviceTerritoryMember = HOT_TestDataFactory.createServiceTerritoryMember(
            serviceResource,
            serviceTerritory
        );
        insert serviceTerritoryMember;

        HOT_Resource__c resource = new HOT_Resource__c();
        resource.Name = 'Test';
        resource.Service_Resource__c = serviceResource.Id;
        insert resource;

        HOT_ResourceMember__c resourceMember = new HOT_ResourceMember__c();
        resourceMember.Resource__c = resource.Id;
        resourceMember.Service_Resource__c = serviceResource.Id;
        insert resourceMember;

        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert WorkType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('HOT_ServiceAppointmentHandler', workType);
        request.PreferredResource1__c = resource.Id;
        request.NumberOfInterpreters__c = 3;
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
        insert contentDocumentLink;

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
