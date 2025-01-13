@IsTest
public class HOT_RecordFilesControllerWithSharingTest {
    @TestSetup
    static void setupTestData() {
        WorkType wt = HOT_TestDataFactory.createWorkType('TestWorkType');
        insert wt;

        HOT_Request__c req = HOT_TestDataFactory.createRequest('Test Request', wt);
        insert req;

        WorkOrder wo = HOT_TestDataFactory.createWorkOrder(req, wt);
        insert wo;

        WorkOrderLineItem woli = HOT_TestDataFactory.createWorkOrderLineItem(wo, wt);
        insert woli;

        ServiceAppointment sa = HOT_TestDataFactory.createServiceAppointment(woli);
        insert sa;

        HOT_File__c hf = new HOT_File__c(Service_Appointment__c = sa.Id);
        insert hf;

        // Create separate content versions and links for each entity to avoid duplicates
        ContentVersion cvWo = HOT_TestDataFactory.createContentVersion(
            'TestTitle_WO',
            'TestFile_WO.jpg',
            'Test Data WO'
        );
        insert cvWo;
        cvWo = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cvWo.Id LIMIT 1];
        ContentDocument cdWo = [SELECT Id FROM ContentDocument WHERE Id = :cvWo.ContentDocumentId LIMIT 1];
        insert HOT_TestDataFactory.createContentDocumentLink(wo.Id, cdWo.Id);

        ContentVersion cvReq = HOT_TestDataFactory.createContentVersion(
            'TestTitle_Req',
            'TestFile_Req.jpg',
            'Test Data Req'
        );
        insert cvReq;
        cvReq = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cvReq.Id LIMIT 1];
        ContentDocument cdReq = [SELECT Id FROM ContentDocument WHERE Id = :cvReq.ContentDocumentId LIMIT 1];
        insert HOT_TestDataFactory.createContentDocumentLink(req.Id, cdReq.Id);

        ContentVersion cvSa = HOT_TestDataFactory.createContentVersion(
            'TestTitle_SA',
            'TestFile_SA.jpg',
            'Test Data SA'
        );
        insert cvSa;
        cvSa = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cvSa.Id LIMIT 1];
        ContentDocument cdSa = [SELECT Id FROM ContentDocument WHERE Id = :cvSa.ContentDocumentId LIMIT 1];
        insert HOT_TestDataFactory.createContentDocumentLink(sa.Id, cdSa.Id);

        ContentVersion cvHf = HOT_TestDataFactory.createContentVersion(
            'TestTitle_HF',
            'TestFile_HF.jpg',
            'Test Data HF'
        );
        insert cvHf;
        cvHf = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cvHf.Id LIMIT 1];
        ContentDocument cdHf = [SELECT Id FROM ContentDocument WHERE Id = :cvHf.ContentDocumentId LIMIT 1];
        insert HOT_TestDataFactory.createContentDocumentLink(hf.Id, cdHf.Id);
    }

    private static void assertContentDocumentExists(List<ContentDocument> docs, Id expectedId, String message) {
        Boolean found = false;
        for (ContentDocument d : docs) {
            if (d.Id == expectedId) {
                found = true;
                break;
            }
        }
        System.assert(found, message);
    }

    @IsTest
    static void testGetContentDocuments_WorkOrder_Record() {
        // Fetch the WorkOrder and ContentDocument for assertion
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];

        Test.startTest();
        List<ContentDocument> results = HOT_RecordFilesControllerWithSharing.getContentDocuments(wo.Id, true);
        Test.stopTest();
        System.assertNotEquals(0, results.size(), 'Expected content documents for WorkOrder.');
    }

    @IsTest
    static void testGetContentDocuments_ServiceAppointment_Record() {
        // Fetch the ServiceAppointment and associated ContentDocument
        ServiceAppointment sa = [SELECT Id FROM ServiceAppointment LIMIT 1];

        Test.startTest();
        List<ContentDocument> results = HOT_RecordFilesControllerWithSharing.getContentDocuments(sa.Id, true);
        Test.stopTest();
        System.assertNotEquals(0, results.size(), 'Expected content documents for ServiceAppointment.');
    }

    @IsTest
    static void testGetContentDocuments_Request_Record() {
        // Fetch the Request and associated ContentDocument
        HOT_Request__c req = [SELECT Id FROM HOT_Request__c LIMIT 1];

        Test.startTest();
        List<ContentDocument> results = HOT_RecordFilesControllerWithSharing.getContentDocuments(req.Id, true);
        Test.stopTest();
        System.assertNotEquals(0, results.size(), 'Expected content documents for Request.');
    }

    @IsTest
    static void testGetContentDocuments_isGetAll_False() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];

        Test.startTest();
        List<ContentDocument> results = HOT_RecordFilesControllerWithSharing.getContentDocuments(wo.Id, false);
        Test.stopTest();
        System.assert(results != null, 'Expected a valid, non-null result.');
    }

    @IsTest
    static void testGetContentDocuments_Null_Record() {
        Test.startTest();
        List<ContentDocument> results = HOT_RecordFilesControllerWithSharing.getContentDocuments(null, true);
        Test.stopTest();
        System.assertEquals(0, results.size(), 'Expected no documents when recordId is null.');
    }
}
