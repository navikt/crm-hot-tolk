@isTest
public class HOT_RecordFilesControllerWithSharingTest {
    @testSetup
    static void setupTestData() {
        // Create a Person__c record
        Person__c person = HOT_TestDataFactory.createPerson();
        person.Name = '12015678999';
        insert person;

        // Create an Account linked to the Person__c
        Account personAccount = HOT_TestDataFactory.createAccount(true);
        personAccount.INT_PersonIdent__c = '12015678999';
        personAccount.CRM_Person__c = person.Id;
        insert personAccount;

        // Create a WorkType
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;

        // Create a HOT_Request__c
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;

        // Create a WorkOrder linked to the HOT_Request__c
        WorkOrder wo = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert wo;

        // Create a WorkOrderLineItem linked to the WorkOrder
        // Ensure you have a valid PricebookEntryId
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry LIMIT 1];
        WorkOrderLineItem woli = HOT_TestDataFactory.createWorkOrderLineItem(wo, workType);
        woli.PricebookEntryId = pbe.Id;
        woli.Quantity = 1;
        woli.UnitPrice = 100;
        insert woli;

        // Create a ServiceAppointment linked to the WorkOrderLineItem and Account
        ServiceAppointment sa = HOT_TestDataFactory.createServiceAppointment(woli);
        sa.HOT_Account__c = personAccount.Id;
        sa.HOT_WorkOrderLineItem__c = woli.Id;
        sa.StartDate = System.today();
        sa.EndDate = System.today().addDays(1);
        insert sa;

        // Create a HOT_File__c linked to the ServiceAppointment
        HOT_File__c hotFile = new HOT_File__c(Service_Appointment__c = sa.Id, Account__c = personAccount.Id);
        insert hotFile;

        // Create a ContentVersion (which will create a ContentDocument)
        ContentVersion contentVersion = HOT_TestDataFactory.createContentVersion(
            'Test File',
            'TestFile.txt',
            'Test content'
        );
        insert contentVersion;

        // Get the ContentDocumentId from the ContentVersion
        ContentVersion cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id];
        Id contentDocumentId = cv.ContentDocumentId;

        // Create ContentDocumentLinks to various records
        List<ContentDocumentLink> cdls = new List<ContentDocumentLink>{
            // Link to WorkOrder
            HOT_TestDataFactory.createContentDocumentLink(wo.Id, contentDocumentId),
            // Link to ServiceAppointment
            HOT_TestDataFactory.createContentDocumentLink(sa.Id, contentDocumentId),
            // Link to HOT_Request__c
            HOT_TestDataFactory.createContentDocumentLink(request.Id, contentDocumentId),
            // Link to HOT_File__c
            HOT_TestDataFactory.createContentDocumentLink(hotFile.Id, contentDocumentId)
        };
        insert cdls;
    }

    @isTest
    static void testGetContentDocumentsWithValidRecordId_GetAllTrue() {
        // Get the WorkOrder Id
        WorkOrder wo = [SELECT Id FROM WorkOrder WHERE Subject = 'Test WorkOrder' LIMIT 1];
        String recordId = wo.Id;
        Boolean isGetAll = true;

        Test.startTest();
        List<ContentDocument> contentDocuments = HOT_RecordFilesControllerWithSharing.getContentDocuments(
            recordId,
            isGetAll
        );
        Test.stopTest();

        System.assertNotEquals(0, contentDocuments.size(), 'ContentDocuments should be returned');

        // Verify that the expected ContentDocument is in the results
        ContentDocument cd = [SELECT Id FROM ContentDocument WHERE Title = 'Test File' LIMIT 1];
        Set<Id> contentDocIds = new Set<Id>();
        for (ContentDocument doc : contentDocuments) {
            contentDocIds.add(doc.Id);
        }
        System.assert(contentDocIds.contains(cd.Id), 'Expected ContentDocument should be in the results');
    }

    @isTest
    static void testGetContentDocumentsWithValidRecordId_GetAllFalse() {
        // Get the WorkOrder Id
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        String recordId = wo.Id;
        Boolean isGetAll = false;

        Test.startTest();
        List<ContentDocument> contentDocuments = HOT_RecordFilesControllerWithSharing.getContentDocuments(
            recordId,
            isGetAll
        );
        Test.stopTest();

        System.assertNotEquals(null, contentDocuments, 'ContentDocuments should not be null');
        // Additional assertions can be added based on the logic of getOnlyMyContentDocuments
    }

    @isTest
    static void testGetContentDocumentsWithNullRecordId() {
        String recordId = null;
        Boolean isGetAll = true;

        Test.startTest();
        List<ContentDocument> contentDocuments = HOT_RecordFilesControllerWithSharing.getContentDocuments(
            recordId,
            isGetAll
        );
        Test.stopTest();

        System.assertEquals(0, contentDocuments.size(), 'ContentDocuments list should be empty when recordId is null');
    }

    @isTest
    static void testGetContentDocumentsWithNoContentDocumentLinks() {
        // Create a new WorkOrder without any linked ContentDocumentLinks
        WorkOrder wo = HOT_TestDataFactory.createWorkOrder(null, null);
        wo.Subject = 'WorkOrder Without ContentDocumentLinks';
        insert wo;

        String recordId = wo.Id;
        Boolean isGetAll = true;

        Test.startTest();
        List<ContentDocument> contentDocuments = HOT_RecordFilesControllerWithSharing.getContentDocuments(
            recordId,
            isGetAll
        );
        Test.stopTest();

        System.assertEquals(
            0,
            contentDocuments.size(),
            'ContentDocuments list should be empty when there are no ContentDocumentLinks'
        );
    }

    @isTest
    static void testGetContentDocumentsWithWorkOrderWithoutRequest() {
        // Create a WorkOrder without HOT_Request__c
        WorkOrder wo = HOT_TestDataFactory.createWorkOrder(null, null);
        wo.Subject = 'WorkOrder Without HOT_Request__c';
        insert wo;

        String recordId = wo.Id;
        Boolean isGetAll = true;

        Test.startTest();
        List<ContentDocument> contentDocuments = HOT_RecordFilesControllerWithSharing.getContentDocuments(
            recordId,
            isGetAll
        );
        Test.stopTest();

        System.assertEquals(
            0,
            contentDocuments.size(),
            'ContentDocuments list should be empty when WorkOrder has no HOT_Request__c'
        );
    }
}
