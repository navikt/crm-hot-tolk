@isTest
public class HOT_InterpreterOnWorkOrderServiceTest {
    @testSetup
    static void setup() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;

        List<HOT_Request__c> requests = new List<HOT_Request__c>();
        HOT_Request__c request = HOT_TestDataFactory.createRequest('subject', workType);
        HOT_Request__c request2 = HOT_TestDataFactory.createRequest('subject 2', workType);
        requests.add(request);
        requests.add(request2);
        insert requests;

        request.Status__c = 'Godkjent';
        request2.Status__c = 'Godkjent';
        update requests;

        OperatingHours operatingHours = HOT_TestDataFactory.createOperatingHours();
        insert operatingHours;
        ServiceTerritory serviceTerritory = HOT_TestDataFactory.createServiceTerritory(operatingHours);
        insert serviceTerritory;

        Profile profile = [
            SELECT Id, Name
            FROM Profile
            WHERE Name = 'System Administrator' OR Name = 'Systemadministrator'
        ];
        User user = HOT_TestDataFactory.createUser('User2', profile);
        insert user;

        List<ServiceResource> serviceResources = new List<ServiceResource>();
        ServiceResource serviceResourceAdmin = HOT_TestDataFactory.createServiceResource(UserInfo.getUserId());
        serviceResourceAdmin.HOT_IsFreelanceInterpreter__c = true;
        ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(user.Id);
        serviceResource.HOT_IsFreelanceInterpreter__c = true;
        serviceResource.HOT_ServiceTerritory__c = serviceTerritory.Id;
        serviceResources.add(serviceResourceAdmin);
        serviceResources.add(serviceResource);
        insert serviceResources;
    }

    @isTest
    static void updateInterpreterFieldOnWorkOrderAfterSingleAssignedResourceInsert() {
        ServiceAppointment serviceAppointment = [
            SELECT Id, HOT_ServiceResource__c, Status, HOT_WorkOrderLineItem__r.WorkOrderId
            FROM ServiceAppointment
            WHERE Subject = 'subject'
            LIMIT 1
        ];
        ServiceResource resource1 = [
            SELECT Id, RelatedRecordId, Name
            FROM ServiceResource
            WHERE RelatedRecordId = :UserInfo.getUserId()
        ];
        AssignedResource assignedResource1 = HOT_TestDataFactory.createAssignedResource(
            serviceAppointment.Id,
            resource1.Id
        );

        WorkOrder workOrder = [
            SELECT Status
            FROM WorkOrder
            WHERE Id = :serviceAppointment.HOT_WorkOrderLineItem__r.WorkOrderId
        ];
        workOrder.Status = 'Dispatched';
        update workOrder;

        Test.startTest();
        insert assignedResource1;
        Test.stopTest();

        workOrder = [
            SELECT Id, HOT_Interpreters__c, Status
            FROM WorkOrder
            WHERE Id = :serviceAppointment.HOT_WorkOrderLineItem__r.WorkOrderId
        ];

        System.assertEquals(
            resource1.Name,
            workOrder.HOT_Interpreters__c,
            'Could not set HOT_Interpreters__c onAfterInsert'
        );
    }

    @isTest
    static void updateInterpreterFieldOnWorkOrderAfterMultipleAssignedResourceInsert() {
        ServiceAppointment serviceAppointment1 = [
            SELECT Id, HOT_ServiceResource__c, Status, HOT_WorkOrderLineItem__r.WorkOrderId
            FROM ServiceAppointment
            WHERE Subject = 'subject'
            LIMIT 1
        ];
        WorkOrderLineItem workOrderLineItem = [
            SELECT Id, WorkOrderId
            FROM WorkOrderLineItem
            WHERE Id = :serviceAppointment1.HOT_WorkOrderLineItem__c
            LIMIT 1
        ];
        WorkOrderLineItem workOrderLineItem2 = workOrderLineItem.clone();
        insert workOrderLineItem2;
        // Create and insert service appointments based on same work order line item
        ServiceAppointment serviceAppointment2 = HOT_TestDataFactory.createServiceAppointment(workOrderLineItem);
        ServiceAppointment serviceAppointment3 = HOT_TestDataFactory.createServiceAppointment(workOrderLineItem2);
        insert serviceAppointment2;
        insert serviceAppointment3;
        ServiceResource resource1 = [
            SELECT Id, Name
            FROM ServiceResource
            WHERE RelatedRecordId = :UserInfo.getUserId()
        ];
        ServiceResource resource2 = [
            SELECT Id, Name
            FROM ServiceResource
            WHERE RelatedRecordId != :UserInfo.getUserId()
        ];
        // Create third service resource
        Profile profile = [
            SELECT Id, Name
            FROM Profile
            WHERE Name = 'System Administrator' OR Name = 'Systemadministrator'
        ];
        User user3 = HOT_TestDataFactory.createUser('User3', profile);
        insert user3;
        ServiceResource resource3 = HOT_TestDataFactory.createServiceResource(user3.Id);
        resource3.HOT_IsFreelanceInterpreter__c = true;
        ServiceTerritory serviceTerritory = [SELECT ID FROM ServiceTerritory LIMIT 1];
        resource3.HOT_ServiceTerritory__c = serviceTerritory.Id;
        insert resource3;
        // Set unique names
        resource1.Name = 'resource1';
        resource2.Name = 'resource2';
        resource3.Name = 'resource3';
        update new List<ServiceResource>{ resource1, resource2, resource3 };

        // Add assigned resources
        AssignedResource assignedResource1 = HOT_TestDataFactory.createAssignedResource(
            serviceAppointment1.Id,
            resource1.Id
        );
        AssignedResource assignedResource2 = HOT_TestDataFactory.createAssignedResource(
            serviceAppointment2.Id,
            resource2.Id
        );
        AssignedResource assignedResource3 = HOT_TestDataFactory.createAssignedResource(
            serviceAppointment3.Id,
            resource3.Id
        );

        WorkOrder workOrder = [
            SELECT Status
            FROM WorkOrder
            WHERE Id = :serviceAppointment1.HOT_WorkOrderLineItem__r.WorkOrderId
        ];
        workOrder.Status = 'Dispatched';
        update workOrder;

        Test.startTest();
        insert new List<AssignedResource>{ assignedResource1, assignedResource2, assignedResource3 };
        Test.stopTest();

        workOrder = [SELECT Id, HOT_Interpreters__c FROM WorkOrder WHERE Id = :workOrderLineItem.WorkOrderId];

        System.assert(
            workOrder.HOT_Interpreters__c.contains(resource1.Name),
            'Could not set multiple HOT_Interpreters__c onAfterInsert'
        );
        System.assert(
            workOrder.HOT_Interpreters__c.contains(resource2.Name),
            'Could not set multiple HOT_Interpreters__c onAfterInsert'
        );
        System.assert(
            workOrder.HOT_Interpreters__c.contains(resource3.Name),
            'Could not set multiple HOT_Interpreters__c onAfterInsert'
        );
    }

    @isTest
    static void updateInterpreterFieldOnWorkOrderAfterSingleAssignedResourceDelete() {
        ServiceAppointment serviceAppointment = [
            SELECT Id, HOT_ServiceResource__c, Status, HOT_WorkOrderLineItem__r.WorkOrderId
            FROM ServiceAppointment
            WHERE Subject = 'subject'
            LIMIT 1
        ];

        ServiceResource resource1 = [
            SELECT Id, Name
            FROM ServiceResource
            WHERE RelatedRecordId = :UserInfo.getUserId()
        ];
        AssignedResource assignedResource1 = HOT_TestDataFactory.createAssignedResource(
            serviceAppointment.Id,
            resource1.Id
        );

        WorkOrder workOrder = [
            SELECT Id, Status, HOT_Interpreters__c
            FROM WorkOrder
            WHERE Id = :serviceAppointment.HOT_WorkOrderLineItem__r.WorkOrderId
        ];
        workOrder.Status = 'Dispatched';
        workOrder.HOT_Interpreters__c = resource1.Name;
        update workOrder;
        insert assignedResource1;

        serviceAppointment = [
            SELECT Id, HOT_ServiceResource__r.Name, HOT_WorkOrderLineItem__r.WorkOrderId
            FROM ServiceAppointment
            WHERE Id = :serviceAppointment.Id
        ];

        System.assertEquals(
            resource1.Name,
            serviceAppointment.HOT_ServiceResource__r.Name,
            'Could not set sa.HOT_ServiceResource__r.Name'
        );

        workOrder = [
            SELECT Id, HOT_Interpreters__c
            FROM WorkOrder
            WHERE Id = :serviceAppointment.HOT_WorkOrderLineItem__r.WorkOrderId
        ];

        System.assertEquals(
            resource1.Name,
            workOrder.HOT_Interpreters__c,
            'Could not get name from HOT_Interpreters__c'
        );

        Test.startTest();
        delete assignedResource1;
        Test.stopTest();

        workOrder = [
            SELECT Id, HOT_Interpreters__c
            FROM WorkOrder
            WHERE Id = :serviceAppointment.HOT_WorkOrderLineItem__r.WorkOrderId
        ];

        System.assertEquals(
            null,
            workOrder.HOT_Interpreters__c,
            'Could not remove name from HOT_Interpreters__c onAfterDelete'
        );
    }

    @isTest
    static void updateInterpreterFieldOnWorkOrderAfterMultipleAssignedResourceDelete() {
        ServiceAppointment serviceAppointment1 = [
            SELECT Id, HOT_ServiceResource__c, Status, HOT_WorkOrderLineItem__r.WorkOrderId
            FROM ServiceAppointment
            WHERE Subject = 'subject'
            LIMIT 1
        ];
        WorkOrderLineItem workOrderLineItem = [
            SELECT Id, WorkOrderId
            FROM WorkOrderLineItem
            WHERE Id = :serviceAppointment1.HOT_WorkOrderLineItem__c
            LIMIT 1
        ];
        WorkOrderLineItem workOrderLineItem2 = workOrderLineItem.clone();
        insert workOrderLineItem2;
        // Create and insert service appointments based on same work order line item
        ServiceAppointment serviceAppointment2 = HOT_TestDataFactory.createServiceAppointment(workOrderLineItem);
        ServiceAppointment serviceAppointment3 = HOT_TestDataFactory.createServiceAppointment(workOrderLineItem2);
        insert new List<ServiceAppointment>{ serviceAppointment2, serviceAppointment3 };

        ServiceResource resource1 = [
            SELECT Id, Name
            FROM ServiceResource
            WHERE RelatedRecordId = :UserInfo.getUserId()
        ];
        ServiceResource resource2 = [
            SELECT Id, Name
            FROM ServiceResource
            WHERE RelatedRecordId != :UserInfo.getUserId()
        ];
        // Create third service resource
        Profile profile = [
            SELECT Id, Name
            FROM Profile
            WHERE Name = 'System Administrator' OR Name = 'Systemadministrator'
        ];
        User user3 = HOT_TestDataFactory.createUser('User3', profile);
        insert user3;
        ServiceResource resource3 = HOT_TestDataFactory.createServiceResource(user3.Id);
        resource3.HOT_IsFreelanceInterpreter__c = true;
        ServiceTerritory serviceTerritory = [SELECT ID FROM ServiceTerritory LIMIT 1];
        resource3.HOT_ServiceTerritory__c = serviceTerritory.Id;
        insert resource3;
        // Set unique names
        resource1.Name = 'resource1';
        resource2.Name = 'resource2';
        resource3.Name = 'resource3';
        update new List<ServiceResource>{ resource1, resource2, resource3 };
        Test.startTest();
        // Add assigned resources
        AssignedResource assignedResource1 = HOT_TestDataFactory.createAssignedResource(
            serviceAppointment1.Id,
            resource1.Id
        );
        AssignedResource assignedResource2 = HOT_TestDataFactory.createAssignedResource(
            serviceAppointment2.Id,
            resource2.Id
        );
        AssignedResource assignedResource3 = HOT_TestDataFactory.createAssignedResource(
            serviceAppointment3.Id,
            resource3.Id
        );
        insert new List<AssignedResource>{ assignedResource1, assignedResource2, assignedResource3 };

        WorkOrder workOrder = [
            SELECT Status
            FROM WorkOrder
            WHERE Id = :serviceAppointment1.HOT_WorkOrderLineItem__r.WorkOrderId
        ];
        workOrder.Status = 'Dispatched';
        update workOrder;

        delete assignedResource2;
        Test.stopTest();

        workOrder = [SELECT Id, HOT_Interpreters__c FROM WorkOrder WHERE Id = :workOrderLineItem.WorkOrderId];

        System.assert(
            workOrder.HOT_Interpreters__c.contains(resource1.Name),
            'Could not set multiple HOT_Interpreters__c onAfterDelete'
        );
        System.assert(
            !workOrder.HOT_Interpreters__c.contains(resource2.Name),
            'Could not set multiple HOT_Interpreters__c onAfterDelete'
        );
        System.assert(
            workOrder.HOT_Interpreters__c.contains(resource3.Name),
            'Could not set multiple HOT_Interpreters__c onAfterDelete'
        );
    }

    @isTest
    static void updateInterpreterFieldOnWorkOrderAfterSingleAssignedResourceEdit() {
        ServiceAppointment serviceAppointment = [
            SELECT Id, HOT_ServiceResource__c, Status, HOT_WorkOrderLineItem__r.WorkOrderId
            FROM ServiceAppointment
            WHERE Subject = 'subject'
            LIMIT 1
        ];
        ServiceResource resource1 = [
            SELECT Id, Name
            FROM ServiceResource
            WHERE RelatedRecordId = :UserInfo.getUserId()
        ];
        ServiceResource resource2 = [
            SELECT Id, Name
            FROM ServiceResource
            WHERE RelatedRecordId != :UserInfo.getUserId()
        ];
        // Set unique names
        resource1.Name = 'resource1';
        resource2.Name = 'resource2';
        update new List<ServiceResource>{ resource1, resource2 };

        WorkOrder workOrder = [
            SELECT Status
            FROM WorkOrder
            WHERE Id = :serviceAppointment.HOT_WorkOrderLineItem__r.WorkOrderId
        ];
        workOrder.Status = 'Dispatched';
        update workOrder;

        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(
            serviceAppointment.Id,
            resource1.Id
        );
        insert assignedResource;

        assignedResource.ServiceResourceId = resource2.Id;
        Test.startTest();
        update assignedResource;
        Test.stopTest();

        workOrder = [
            SELECT Id, HOT_Interpreters__c
            FROM WorkOrder
            WHERE Id = :serviceAppointment.HOT_WorkOrderLineItem__r.WorkOrderId
        ];

        System.assert(
            workOrder.HOT_Interpreters__c.contains(resource2.Name),
            'Could not set single HOT_Interpreters__c onAfterUpdate'
        );
        System.assert(
            !workOrder.HOT_Interpreters__c.contains(resource1.Name),
            'Could not set single HOT_Interpreters__c onAfterUpdate'
        );
    }

    @isTest
    static void updateInterpreterFieldOnWorkOrderAfterMultipleAssignedResourceEdit() {
        ServiceAppointment serviceAppointment1 = [
            SELECT Id, HOT_ServiceResource__c, Status, HOT_WorkOrderLineItem__r.WorkOrderId
            FROM ServiceAppointment
            WHERE Subject = 'subject'
            LIMIT 1
        ];
        WorkOrderLineItem workOrderLineItem = [
            SELECT Id, WorkOrderId
            FROM WorkOrderLineItem
            WHERE Id = :serviceAppointment1.HOT_WorkOrderLineItem__c
            LIMIT 1
        ];
        WorkOrderLineItem workOrderLineItem2 = workOrderLineItem.clone();
        insert workOrderLineItem2;
        // Create and insert service appointments based on same work order line item
        ServiceAppointment serviceAppointment2 = HOT_TestDataFactory.createServiceAppointment(workOrderLineItem2);
        ServiceAppointment serviceAppointment3 = HOT_TestDataFactory.createServiceAppointment(workOrderLineItem2);
        insert new List<ServiceAppointment>{ serviceAppointment2, serviceAppointment3 };

        ServiceResource resource1 = [
            SELECT Id, Name
            FROM ServiceResource
            WHERE RelatedRecordId = :UserInfo.getUserId()
        ];
        ServiceResource resource2 = [
            SELECT Id, Name
            FROM ServiceResource
            WHERE RelatedRecordId != :UserInfo.getUserId()
        ];
        // Create third service resource
        Profile profile = [
            SELECT Id, Name
            FROM Profile
            WHERE Name = 'System Administrator' OR Name = 'Systemadministrator'
        ];
        User user3 = HOT_TestDataFactory.createUser('User3', profile);
        insert user3;
        ServiceResource resource3 = HOT_TestDataFactory.createServiceResource(user3.Id);
        resource3.HOT_IsFreelanceInterpreter__c = true;
        ServiceTerritory serviceTerritory = [SELECT ID FROM ServiceTerritory LIMIT 1];
        resource3.HOT_ServiceTerritory__c = serviceTerritory.Id;
        insert resource3;
        // Set unique names
        resource1.Name = 'resource1';
        resource2.Name = 'resource2';
        resource3.Name = 'resource3';
        update new List<ServiceResource>{ resource1, resource2, resource3 };

        WorkOrder workOrder = [
            SELECT Status
            FROM WorkOrder
            WHERE Id = :serviceAppointment1.HOT_WorkOrderLineItem__r.WorkOrderId
        ];
        workOrder.Status = 'Dispatched';
        update workOrder;
        Test.startTest();
        // Add assigned resources
        AssignedResource assignedResource1 = HOT_TestDataFactory.createAssignedResource(
            serviceAppointment1.Id,
            resource1.Id
        );
        AssignedResource assignedResource2 = HOT_TestDataFactory.createAssignedResource(
            serviceAppointment2.Id,
            resource2.Id
        );
        insert new List<AssignedResource>{ assignedResource1, assignedResource2 };

        assignedResource2.ServiceResourceId = resource3.Id;

        update assignedResource2;
        Test.stopTest();

        workOrder = [SELECT Id, HOT_Interpreters__c FROM WorkOrder WHERE Id = :workOrderLineItem.WorkOrderId];

        System.assert(
            workOrder.HOT_Interpreters__c.contains(resource1.Name),
            'Could not set multiple HOT_Interpreters__c onAfterUpdate'
        );
        System.assert(
            !workOrder.HOT_Interpreters__c.contains(resource2.Name),
            'Could not set multiple HOT_Interpreters__c onAfterUpdate'
        );
        System.assert(
            workOrder.HOT_Interpreters__c.contains(resource3.Name),
            'Could not set multiple HOT_Interpreters__c onAfterUpdate'
        );
    }

    @isTest
    static void appendInterpretersTest() {
        ServiceAppointment serviceAppointment = [
            SELECT
                Id,
                HOT_ServiceResource__c,
                Status,
                HOT_WorkOrderLineItem__r.WorkOrderId,
                HOT_IsScreenInterpreterNew__c,
                HOT_ServiceResource__r.Name
            FROM ServiceAppointment
            WHERE Subject = 'subject'
            LIMIT 1
        ];

        WorkOrder workOrder = [
            SELECT Status
            FROM WorkOrder
            WHERE Id = :ServiceAppointment.HOT_WorkOrderLineItem__r.WorkOrderId
        ];

        String newInterpreter = '';
        for (Integer i = 0; i < 255; i++) {
            newInterpreter += 'a';
        }

        workOrder.HOT_Interpreters__c = newInterpreter;

        HOT_InterpreterOnWorkOrderService.appendInterpreterName(workOrder, serviceAppointment);

        System.assert(
            workOrder.HOT_Interpreters__c.endsWith('...'),
            'Expected Interpreters to have 3 dots (...) after their names'
        );
        System.debug(workOrder.HOT_Interpreters__c);
    }
}
