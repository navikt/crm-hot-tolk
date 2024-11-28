@isTest
public class HOT_HotFilesControllerTest {
    @testSetup
    static void setupTestData() {
        Person__c person = HOT_TestDataFactory.createPerson();
        person.Name = '12015678999';
        insert person;

        Account personAccount = HOT_TestDataFactory.createAccount(true);
        personAccount.INT_PersonIdent__c = '12015678999';
        personAccount.CRM_Person__c = person.Id;
        insert personAccount;

        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;

        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;

        WorkOrder wo = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert wo;

        WorkOrderLineItem woli = HOT_TestDataFactory.createWorkOrderLineItem(wo, workType);
        insert woli;

        ServiceAppointment sa = HOT_TestDataFactory.createServiceAppointment(woli);
        sa.HOT_Account__c = personAccount.Id;
        insert sa;

        HOT_File__c hotFile = new HOT_File__c(Service_Appointment__c = sa.Id, Account__c = personAccount.Id);
        insert hotFile;

        ContentVersion contentVersion = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'TestFile.txt',
            VersionData = Blob.valueOf('Test content')
        );
        insert contentVersion;
    }

    @isTest
    static void testGetHotFileRecordId() {
        Person__c person = HOT_TestDataFactory.createPerson();
        person.Name = '12015678999';
        insert person;

        Account personAccount = HOT_TestDataFactory.createAccount(true);
        personAccount.INT_PersonIdent__c = '12015678999';
        personAccount.CRM_Person__c = person.Id;
        insert personAccount;

        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;

        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;

        WorkOrder wo = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert wo;

        WorkOrderLineItem woli = HOT_TestDataFactory.createWorkOrderLineItem(wo, workType);
        insert woli;

        ServiceAppointment sa = HOT_TestDataFactory.createServiceAppointment(woli);
        sa.HOT_Account__c = personAccount.Id;
        insert sa;

        HOT_File__c hotFile = new HOT_File__c(Service_Appointment__c = sa.Id, Account__c = personAccount.Id);
        insert hotFile;

        Test.startTest();
        Id hotFileId = HOT_HotFilesController.getHotFileRecordId(sa.Id);
        Test.stopTest();

        System.assertNotEquals(null, hotFileId, 'HotFileId should not be null');
    }

    @isTest
    static void testCreateHotFileRecord_New() {
        Person__c newPerson = HOT_TestDataFactory.createPerson();
        newPerson.Name = '13015678999';
        insert newPerson;

        Account newPersonAccount = HOT_TestDataFactory.createAccount(true);
        newPersonAccount.INT_PersonIdent__c = '13015678999';
        newPersonAccount.CRM_Person__c = newPerson.Id;
        insert newPersonAccount;

        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;

        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST_NEW', workType);
        insert request;

        WorkOrder wo = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert wo;

        WorkOrderLineItem woli = HOT_TestDataFactory.createWorkOrderLineItem(wo, workType);
        insert woli;

        ServiceAppointment sa = HOT_TestDataFactory.createServiceAppointment(woli);
        sa.HOT_Account__c = newPersonAccount.Id;
        insert sa;

        Test.startTest();
        Id hotFileId = HOT_HotFilesController.createHotFileRecord(sa.Id);
        Test.stopTest();

        HOT_File__c hotFile = [SELECT Id, Service_Appointment__c, Account__c FROM HOT_File__c WHERE Id = :hotFileId];
        System.assertNotEquals(null, hotFile, 'HotFile record should not be null');
        System.assertEquals(sa.Id, hotFile.Service_Appointment__c, 'Service Appointment IDs should match');
        System.assertEquals(newPersonAccount.Id, hotFile.Account__c, 'Account IDs should match');
    }

    @isTest
    static void testCreateHotFileRecord_Existing() {
        ServiceAppointment sa = [SELECT Id FROM ServiceAppointment LIMIT 1];

        Test.startTest();
        Id hotFileId1 = HOT_HotFilesController.createHotFileRecord(sa.Id);
        Id hotFileId2 = HOT_HotFilesController.createHotFileRecord(sa.Id);
        Test.stopTest();

        System.assertEquals(hotFileId1, hotFileId2, 'HotFile IDs should be the same for existing records');
    }

    @isTest
    static void testShareWithUser() {
        HOT_File__c hotFile = [SELECT Id, Account__c FROM HOT_File__c LIMIT 1];
        ContentVersion contentVersion = [SELECT Id, ContentDocumentId FROM ContentVersion LIMIT 1];

        List<Id> contentDocumentIds = new List<Id>{ contentVersion.ContentDocumentId };

        Test.startTest();
        HOT_HotFilesController.shareWithUser(hotFile.Id, contentDocumentIds);
        Test.stopTest();

        // Verify that a ContentDocumentLink has been created
        List<ContentDocumentLink> cdls = [
            SELECT Id, ContentDocumentId, LinkedEntityId, ShareType
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :hotFile.Account__c AND ContentDocumentId = :contentVersion.ContentDocumentId
        ];

        System.assertNotEquals(0, cdls.size(), 'ContentDocumentLink should be created');
        System.assertEquals('V', cdls[0].ShareType, 'ShareType should be View (V)');
    }

    @isTest
    static void testShareWithUser_NullAccount() {
        HOT_File__c hotFile = new HOT_File__c();
        insert hotFile;

        List<Id> contentDocumentIds = new List<Id>();

        Test.startTest();
        HOT_HotFilesController.shareWithUser(hotFile.Id, contentDocumentIds);
        Test.stopTest();

        // No exception should be thrown, and no action taken
    }
}
