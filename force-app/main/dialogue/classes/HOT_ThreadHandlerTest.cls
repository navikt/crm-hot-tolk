@isTest
public without sharing class HOT_ThreadHandlerTest {
    @TestSetup
    static void makeData() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
    }
    @isTest
    static void setThreadNameBasedOnRequestTest() {
        HOT_Request__c request = [SELECT Id, OwnerId, Subject__c FROM HOT_Request__c];
        Thread__c thread = HOT_TestDataFactory.createThread();
        thread.CRM_Related_Object__c = request.Id;

        Test.startTest();
        insert thread;
        Test.stopTest();

        thread = [SELECT Id, Name FROM Thread__c WHERE Id = :thread.Id];

        System.assertEquals('SAMTALE MED BRUKER: TEST', thread.Name, 'Could not set thread Name based on request');
    }
     @isTest
    static void setThreadNameBasedOnWorkorderTest() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        workOrder.Subject='TEST';
        insert workOrder;
        Thread__c thread = HOT_TestDataFactory.createThread();
        thread.CRM_Type__c = 'HOT_BRUKER-FORMIDLER';
        thread.CRM_Related_Object__c = workOrder.Id;
        Test.startTest();
        insert thread;
        Test.stopTest();

        thread = [SELECT Id, Name FROM Thread__c WHERE Id = :thread.Id];

        System.assertEquals('SAMTALE MELLOM BRUKER OG TOLKER: TEST', thread.Name, 'Could not set thread Name based on workOrder');
    }
     @isTest
    static void setThreadNameBasedOnServiceAppointmentTest() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder;
        WorkOrderLineItem woli=HOT_TestDataFactory.createWorkOrderLineItem(workOrder,workType);
        insert woli;
        ServiceAppointment sa=HOT_TestDataFactory.createServiceAppointment(woli);
        sa.Subject='TEST';
        insert sa;
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' OR Name = 'Standardbruker' LIMIT 1];
        User user = HOT_TestDataFactory.createUser('user', profile);
        insert user;
        ServiceResource resource = HOT_TestDataFactory.createServiceResource(user.Id);
        insert resource;

        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(
            sa.Id,
            resource.Id
        );
        insert assignedResource;
        Thread__c thread = HOT_TestDataFactory.createThread();
        thread.CRM_Type__c = 'HOT_TOLK-FORMIDLER';
        thread.CRM_Related_Object__c = sa.Id;
        Test.startTest();
        insert thread;
        Test.stopTest();

        thread = [SELECT Id, Name FROM Thread__c WHERE Id = :thread.Id];

        System.assertEquals(sa.Subject, thread.Name, 'Could not set thread Name based on workOrder');
    }
     @isTest
    static void setThreadNameBasedOnInterestedResourceTest() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder;
        WorkOrderLineItem woli=HOT_TestDataFactory.createWorkOrderLineItem(workOrder,workType);
        insert woli;
        ServiceAppointment sa=HOT_TestDataFactory.createServiceAppointment(woli);
        sa.Subject='TEST';
        insert sa;
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' OR Name = 'Standardbruker' LIMIT 1];
        User user = HOT_TestDataFactory.createUser('user', profile);
        insert user;
        ServiceResource resource = HOT_TestDataFactory.createServiceResource(user.Id);
        insert resource;
        HOT_InterestedResource__c interestedResource=HOT_TestDataFactory.createInterestedResource(sa.Id, resource.Id);
        insert interestedResource;


        Thread__c thread = HOT_TestDataFactory.createThread();
        thread.CRM_Type__c = 'HOT_TOLK-FORMIDLER';
        thread.CRM_Related_Object__c = interestedResource.Id;
        Test.startTest();
        insert thread;
        Test.stopTest();

        thread = [SELECT Id, Name FROM Thread__c WHERE Id = :thread.Id];

        System.assertEquals(sa.Subject, thread.Name, 'Could not set thread Name based on workOrder');
    }
}
