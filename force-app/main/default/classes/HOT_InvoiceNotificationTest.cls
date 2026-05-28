@isTest
private class HOT_InvoiceNotificationTest {
    @isTest
    static void testInvoiceNotificationNew() {
        OperatingHours operatingHours = HOT_TestDataFactory.createOperatingHours();
        insert operatingHours;
        ServiceTerritory serviceTerritory = HOT_TestDataFactory.createServiceTerritory(operatingHours);
        insert serviceTerritory;

        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' OR Name = 'Standardbruker' LIMIT 1];
        User user = HOT_TestDataFactory.createUser('user', profile);
        insert user;

        ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(user.Id);
        serviceResource.HOT_IsEmployedInterpreter__c = true;
        serviceResource.HOT_IsFreelanceInterpreter__c = false;
        serviceResource.CRM_Domain__c = 'HOT';
        serviceResource.CRM_SubDomain__c = 'Tolketjenesten';
        insert serviceResource;

        ServiceTerritoryMember serviceTerritoryMember = HOT_TestDataFactory.createServiceTerritoryMember(
            serviceResource,
            serviceTerritory
        );
        insert serviceTerritoryMember;

        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert WorkType;

        HOT_Request__c request = HOT_TestDataFactory.createRequest('HOT_InterestedResourceHandler', workType);
        request.NumberOfInterpreters__c = 3;
        request.IsOtherEconomicProvicer__c = true;
        insert request;
        request.Status__c = 'Godkjent';
        update request;

        ServiceAppointment serviceAppointment = [
            SELECT Id, HOT_WorkOrderLineItem__r.WorkOrderId
            FROM ServiceAppointment
            LIMIT 1
        ];
        serviceAppointment.EarliestStartTime = System.now().addDays(-5);
        serviceAppointment.DueDate = System.now().addDays(-5);
        update serviceAppointment;

        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(
            serviceAppointment.Id,
            serviceResource.Id
        );
        serviceAppointment.Status = 'Dispatched';
        update serviceAppointment;

        HOT_Invoice__c invoice = new HOT_Invoice__c();
        invoice.ServiceAppointment__c = serviceAppointment.Id;
        invoice.ServiceResource__c = serviceResource.Id;
        invoice.WorkOrder__c = serviceAppointment.HOT_WorkOrderLineItem__r.WorkOrderId;
        invoice.Status__c = 'New';
        insert invoice;

        Test.startTest();
        HOT_InvoiceNotification.sendInvoiceNotification(new List<HOT_Invoice__c>{ invoice }, 'New');
        Test.stopTest();

        List<HOT_Notification__c> notifications = [
            SELECT Id, HOT_RelatedObject__c
            FROM HOT_Notification__c
            WHERE HOT_RelatedObject__c = :invoice.Id
        ];

        System.assert(notifications.size() > 0, 'Det skulle blitt opprettet minst én notification for invoice');
    }
    @isTest
    static void testInvoiceNotificationNone() {
        Test.startTest();
        HOT_InvoiceNotification.sendInvoiceNotification(new List<HOT_Invoice__c>{}, 'New');
        Test.stopTest();

        List<HOT_Notification__c> notifications = [SELECT Id, HOT_RelatedObject__c FROM HOT_Notification__c];

        System.assert(notifications.size() == 0, 'Det skulle blitt opprettet minst én notification for invoice');
    }
    @isTest
    static void testInvoiceNotificationSentInReturn() {
        OperatingHours operatingHours = HOT_TestDataFactory.createOperatingHours();
        insert operatingHours;
        ServiceTerritory serviceTerritory = HOT_TestDataFactory.createServiceTerritory(operatingHours);
        insert serviceTerritory;

        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' OR Name = 'Standardbruker' LIMIT 1];
        User user = HOT_TestDataFactory.createUser('user', profile);
        insert user;

        ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(user.Id);
        serviceResource.HOT_IsEmployedInterpreter__c = true;
        serviceResource.HOT_IsFreelanceInterpreter__c = false;
        serviceResource.CRM_Domain__c = 'HOT';
        serviceResource.CRM_SubDomain__c = 'Tolketjenesten';
        insert serviceResource;

        ServiceTerritoryMember serviceTerritoryMember = HOT_TestDataFactory.createServiceTerritoryMember(
            serviceResource,
            serviceTerritory
        );
        insert serviceTerritoryMember;

        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert WorkType;

        HOT_Request__c request = HOT_TestDataFactory.createRequest('HOT_InterestedResourceHandler', workType);
        request.NumberOfInterpreters__c = 3;
        request.IsOtherEconomicProvicer__c = true;
        insert request;
        request.Status__c = 'Godkjent';
        update request;

        ServiceAppointment serviceAppointment = [
            SELECT Id, HOT_WorkOrderLineItem__r.WorkOrderId
            FROM ServiceAppointment
            LIMIT 1
        ];
        serviceAppointment.EarliestStartTime = System.now().addDays(-5);
        serviceAppointment.DueDate = System.now().addDays(-5);
        update serviceAppointment;

        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(
            serviceAppointment.Id,
            serviceResource.Id
        );
        serviceAppointment.Status = 'Dispatched';
        update serviceAppointment;

        HOT_Invoice__c invoice = new HOT_Invoice__c();
        invoice.ServiceAppointment__c = serviceAppointment.Id;
        invoice.ServiceResource__c = serviceResource.Id;
        invoice.WorkOrder__c = serviceAppointment.HOT_WorkOrderLineItem__r.WorkOrderId;
        invoice.Status__c = 'Sent In Return';
        insert invoice;

        Test.startTest();
        HOT_InvoiceNotification.sendInvoiceNotification(new List<HOT_Invoice__c>{ invoice }, 'Sent In Return');
        Test.stopTest();

        List<HOT_Notification__c> notifications = [
            SELECT Id, HOT_RelatedObject__c
            FROM HOT_Notification__c
            WHERE HOT_RelatedObject__c = :invoice.Id
        ];

        System.assert(notifications.size() > 0, 'Det skulle blitt opprettet minst én notification for invoice');
    }
    @isTest
    static void testInvoiceNotificationReminder() {
        OperatingHours operatingHours = HOT_TestDataFactory.createOperatingHours();
        insert operatingHours;
        ServiceTerritory serviceTerritory = HOT_TestDataFactory.createServiceTerritory(operatingHours);
        insert serviceTerritory;

        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' OR Name = 'Standardbruker' LIMIT 1];
        User user = HOT_TestDataFactory.createUser('user', profile);
        insert user;

        ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(user.Id);
        serviceResource.HOT_IsEmployedInterpreter__c = true;
        serviceResource.HOT_IsFreelanceInterpreter__c = false;
        serviceResource.CRM_Domain__c = 'HOT';
        serviceResource.CRM_SubDomain__c = 'Tolketjenesten';
        insert serviceResource;

        ServiceTerritoryMember serviceTerritoryMember = HOT_TestDataFactory.createServiceTerritoryMember(
            serviceResource,
            serviceTerritory
        );
        insert serviceTerritoryMember;

        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert WorkType;

        HOT_Request__c request = HOT_TestDataFactory.createRequest('HOT_InterestedResourceHandler', workType);
        request.NumberOfInterpreters__c = 3;
        request.IsOtherEconomicProvicer__c = true;
        insert request;
        request.Status__c = 'Godkjent';
        update request;

        ServiceAppointment serviceAppointment = [
            SELECT Id, HOT_WorkOrderLineItem__r.WorkOrderId
            FROM ServiceAppointment
            LIMIT 1
        ];
        serviceAppointment.EarliestStartTime = System.now().addDays(-5);
        serviceAppointment.DueDate = System.now().addDays(-5);
        update serviceAppointment;

        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(
            serviceAppointment.Id,
            serviceResource.Id
        );
        serviceAppointment.Status = 'Dispatched';
        update serviceAppointment;

        HOT_Invoice__c invoice = new HOT_Invoice__c();
        invoice.ServiceAppointment__c = serviceAppointment.Id;
        invoice.ServiceResource__c = serviceResource.Id;
        invoice.WorkOrder__c = serviceAppointment.HOT_WorkOrderLineItem__r.WorkOrderId;
        invoice.Status__c = 'New';
        insert invoice;

        Test.startTest();
        HOT_InvoiceNotification.sendInvoiceNotification(new List<HOT_Invoice__c>{ invoice }, 'Reminder');
        Test.stopTest();

        List<HOT_Notification__c> notifications = [
            SELECT Id, HOT_RelatedObject__c
            FROM HOT_Notification__c
            WHERE HOT_RelatedObject__c = :invoice.Id
        ];

        System.assert(notifications.size() > 0, 'Det skulle blitt opprettet minst én notification for invoice');
    }
}
