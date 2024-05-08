@IsTest
public with sharing class HOT_UpdateSAStatusServiceTest {
     @isTest
    static void UpdateServiceAppointmentStatusCanceled() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        workType.Name = 'Work Type Name';
        insert workType;
        
        HOT_Request__c request = HOT_TestDataFactory.createRequest('Subject', workType);
        insert request;
        
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder;
        
        WorkOrderLineItem workOrderLineItem = HOT_TestDataFactory.createWorkOrderLineItem(workOrder, workType);
        insert workOrderLineItem;
        
        ServiceAppointment sa = HOT_TestDataFactory.createServiceAppointment(workOrderLineItem);
        sa.HOT_Request__c = request.Id;
        sa.Status = 'None';
        insert sa;
         Account account = HOT_TestDataFactory.createAccount(true);
    insert account;
    
    User currentUser = [SELECT Id, AccountId, Account.CRM_Person__c FROM User WHERE Id = :UserInfo.getUserId()];
    Test.startTest();
    ServiceResource resource = HOT_TestDataFactory.createServiceResource(currentUser.Id);
    resource.AccountId = currentUser.AccountId;
    insert resource;
    
    HOT_InterestedResource__c interestedResource = HOT_TestDataFactory.createInterestedResource(sa.Id, resource.Id);
    insert interestedResource;

    AssignedResource ar = HOT_TestDataFactory.createAssignedResource(sa.Id, resource.Id);
    insert ar;

        
        sa.Status = 'Canceled';


        HOT_UpdateSAStatusService input = new HOT_UpdateSAStatusService();
        input.serviceAppointment = sa;

        System.runAs(currentUser){

            HOT_UpdateSAStatusService.updateServiceAppointmentStatus(new List<HOT_UpdateSAStatusService>{input});
        }
        Test.stopTest();

        ServiceAppointment updatedSa = [SELECT Id, Status, ActualStartTime, ActualEndTime, HOT_DoNotCreateHAR__c, HOT_CancelComment__c, HOT_IsNotifyDispatcher__c, HOT_AssignedResourceId__c, HOT_ServiceResource__c, HOT_CanceledByInterpreter__c FROM ServiceAppointment WHERE Id = :sa.Id];

        System.assertEquals(sa.Status, updatedSa.Status);
    }
       @isTest
    static void UpdateServiceAppointmentStatusNone() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        workType.Name = 'Work Type Name';
        insert workType;
        
        HOT_Request__c request = HOT_TestDataFactory.createRequest('Subject', workType);
        insert request;
        
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder;
        
        WorkOrderLineItem workOrderLineItem = HOT_TestDataFactory.createWorkOrderLineItem(workOrder, workType);
        insert workOrderLineItem;
        
        ServiceAppointment sa = HOT_TestDataFactory.createServiceAppointment(workOrderLineItem);
        sa.HOT_Request__c = request.Id;
        sa.Status = 'Canceled';
        insert sa;
         Account account = HOT_TestDataFactory.createAccount(true);
    insert account;
    
    User currentUser = [SELECT Id, AccountId, Account.CRM_Person__c FROM User WHERE Id = :UserInfo.getUserId()];
    Test.startTest();
    ServiceResource resource = HOT_TestDataFactory.createServiceResource(currentUser.Id);
    resource.AccountId = currentUser.AccountId;
    insert resource;
    
    HOT_InterestedResource__c interestedResource = HOT_TestDataFactory.createInterestedResource(sa.Id, resource.Id);
    insert interestedResource;

    AssignedResource ar = HOT_TestDataFactory.createAssignedResource(sa.Id, resource.Id);
    insert ar;

        
        sa.Status = 'None';


        HOT_UpdateSAStatusService input = new HOT_UpdateSAStatusService();
        input.serviceAppointment = sa;

        System.runAs(currentUser){

            HOT_UpdateSAStatusService.updateServiceAppointmentStatus(new List<HOT_UpdateSAStatusService>{input});
        }
        Test.stopTest();

        ServiceAppointment updatedSa = [SELECT Id, Status, ActualStartTime, ActualEndTime, HOT_DoNotCreateHAR__c, HOT_CancelComment__c, HOT_IsNotifyDispatcher__c, HOT_AssignedResourceId__c, HOT_ServiceResource__c, HOT_CanceledByInterpreter__c FROM ServiceAppointment WHERE Id = :sa.Id];

        System.assertEquals(sa.Status, updatedSa.Status);
    }
       @isTest
    static void UpdateServiceAppointmentStatusCompleted() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        workType.Name = 'Work Type Name';
        insert workType;
        
        HOT_Request__c request = HOT_TestDataFactory.createRequest('Subject', workType);
        insert request;
        
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder;
        
        WorkOrderLineItem workOrderLineItem = HOT_TestDataFactory.createWorkOrderLineItem(workOrder, workType);
        insert workOrderLineItem;
        
        ServiceAppointment sa = HOT_TestDataFactory.createServiceAppointment(workOrderLineItem);
        sa.HOT_Request__c = request.Id;
        sa.Status = 'None';
        insert sa;
         Account account = HOT_TestDataFactory.createAccount(true);
    insert account;
    
    User currentUser = [SELECT Id, AccountId, Account.CRM_Person__c FROM User WHERE Id = :UserInfo.getUserId()];
    Test.startTest();
    ServiceResource resource = HOT_TestDataFactory.createServiceResource(currentUser.Id);
    resource.AccountId = currentUser.AccountId;
    insert resource;
    
    HOT_InterestedResource__c interestedResource = HOT_TestDataFactory.createInterestedResource(sa.Id, resource.Id);
    insert interestedResource;

    AssignedResource ar = HOT_TestDataFactory.createAssignedResource(sa.Id, resource.Id);
    insert ar;

        
        sa.Status = 'Completed';


        HOT_UpdateSAStatusService input = new HOT_UpdateSAStatusService();
        input.serviceAppointment = sa;

        System.runAs(currentUser){

            HOT_UpdateSAStatusService.updateServiceAppointmentStatus(new List<HOT_UpdateSAStatusService>{input});
        }
        Test.stopTest();

        ServiceAppointment updatedSa = [SELECT Id, Status, ActualStartTime, ActualEndTime, HOT_DoNotCreateHAR__c, HOT_CancelComment__c, HOT_IsNotifyDispatcher__c, HOT_AssignedResourceId__c, HOT_ServiceResource__c, HOT_CanceledByInterpreter__c FROM ServiceAppointment WHERE Id = :sa.Id];

        System.assertEquals(sa.Status, updatedSa.Status);
    }


    @isTest
    static void testUpdateServiceAppointmentStatusWithDifferentResource() {
               WorkType workType = HOT_TestDataFactory.createWorkType();
        workType.Name = 'Work Type Name';
        insert workType;
        
        HOT_Request__c request = HOT_TestDataFactory.createRequest('Subject', workType);
        insert request;
        
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder;
        
        WorkOrderLineItem workOrderLineItem = HOT_TestDataFactory.createWorkOrderLineItem(workOrder, workType);
        insert workOrderLineItem;
        
        ServiceAppointment sa = HOT_TestDataFactory.createServiceAppointment(workOrderLineItem);
        sa.HOT_Request__c = request.Id;
        sa.Status = 'None';
        insert sa;
         Account account = HOT_TestDataFactory.createAccount(true);
    insert account;
    
    User currentUser = [SELECT Id, AccountId, Account.CRM_Person__c FROM User WHERE Id = :UserInfo.getUserId()];
    Test.startTest();
    ServiceResource resource = HOT_TestDataFactory.createServiceResource(currentUser.Id);
    resource.AccountId = currentUser.AccountId;
    insert resource;
    
    HOT_InterestedResource__c interestedResource = HOT_TestDataFactory.createInterestedResource(sa.Id, resource.Id);
    insert interestedResource;

    AssignedResource ar = HOT_TestDataFactory.createAssignedResource(sa.Id, resource.Id);
    insert ar;

        
        sa.Status = 'Completed';


        HOT_UpdateSAStatusService input = new HOT_UpdateSAStatusService();
        input.serviceAppointment = sa;

        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' OR Name = 'Standardbruker' LIMIT 1];
        User user1 = HOT_TestDataFactory.createUser('user1', profile);
        insert user1;

        System.runAs(user1){

            HOT_UpdateSAStatusService.updateServiceAppointmentStatus(new List<HOT_UpdateSAStatusService>{input});
        }
        Test.stopTest();

        ServiceAppointment updatedSa = [SELECT Id, Status, ActualStartTime, ActualEndTime, HOT_DoNotCreateHAR__c, HOT_CancelComment__c, HOT_IsNotifyDispatcher__c, HOT_AssignedResourceId__c, HOT_ServiceResource__c, HOT_CanceledByInterpreter__c FROM ServiceAppointment WHERE Id = :sa.Id];

        System.assertEquals('None', updatedSa.Status, 'Should not be changing status');
    }
    
}