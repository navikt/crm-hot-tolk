@isTest
private class HOT_InvoiceControllerTest {
    @TestSetup
    static void makeData() {
        OperatingHours operatingHours = HOT_TestDataFactory.createOperatingHours();
        insert operatingHours;
        ServiceTerritory serviceTerritory = HOT_TestDataFactory.createServiceTerritory(operatingHours);
        insert serviceTerritory;

        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' OR Name = 'Standardbruker' LIMIT 1];
        User user = HOT_TestDataFactory.createUser('user', profile);
        insert user;
        Account acc = new Account();
        acc.Name = 'Test account';
        insert acc;
        ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(user.Id);
        serviceResource.Name = 'Test Service Resource';
        serviceResource.HOT_IsFreelanceInterpreter__c = false;
        serviceResource.HOT_IsEmployedInterpreter__c = true;
        serviceResource.AccountId = acc.Id;
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
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        request.PreferredResource1__c = resource.Id;
        request.IsOtherEconomicProvicer__c = true;
        insert request;
        request.Status__c = 'Godkjent';
        update request;

        //sr 2

        User user2 = HOT_TestDataFactory.createUser('user2', profile);
        insert user2;
        Account acc2 = new Account();
        acc2.Name = 'Test account 2';
        insert acc2;
        ServiceResource serviceResource2 = HOT_TestDataFactory.createServiceResource(user2.Id);
        serviceResource2.Name = 'Test Service Resource 2';
        serviceResource2.HOT_IsFreelanceInterpreter__c = false;
        serviceResource2.HOT_IsEmployedInterpreter__c = true;
        serviceResource2.AccountId = acc2.Id;
        insert serviceResource2;
        ServiceTerritoryMember serviceTerritoryMember2 = HOT_TestDataFactory.createServiceTerritoryMember(
            serviceResource2,
            serviceTerritory
        );
        insert serviceTerritoryMember2;

        HOT_Resource__c resource2 = new HOT_Resource__c();
        resource2.Name = 'Test';
        resource2.Service_Resource__c = serviceResource2.Id;
        insert resource2;

        HOT_ResourceMember__c resourceMember2 = new HOT_ResourceMember__c();
        resourceMember2.Resource__c = resource2.Id;
        resourceMember2.Service_Resource__c = serviceResource2.Id;
        insert resourceMember2;
    }
    @IsTest
    static void createInvoiceOnDispatchTest() {
        ServiceResource serviceResource = [SELECT Id FROM ServiceResource LIMIT 1];
        ServiceAppointment serviceAppointment = [SELECT Id FROM ServiceAppointment LIMIT 1];
        AssignedResource ar = HOT_TestDataFactory.createAssignedResource(serviceAppointment.Id, serviceResource.Id);
        insert ar;
        Test.startTest();
        serviceAppointment.Status = 'Dispatched';
        update serviceAppointment;
        Test.stopTest();
        List<HOT_Invoice__c> invoices = [
            SELECT Id
            FROM HOT_Invoice__c
            WHERE ServiceAppointment__c = :serviceAppointment.Id
        ];
        System.assertEquals(
            1,
            invoices.size(),
            'Det skulle blitt opprettet én invoice når en Service Appointment blir dispatched'
        );
    }
    @IsTest
    static void updateInvoiceOnChangedDispatchTest() {
        ServiceResource serviceResource = [SELECT Id FROM ServiceResource WHERE Name = 'Test Service Resource' LIMIT 1];
        ServiceAppointment serviceAppointment = [SELECT Id FROM ServiceAppointment LIMIT 1];
        AssignedResource ar = HOT_TestDataFactory.createAssignedResource(serviceAppointment.Id, serviceResource.Id);
        insert ar;
        // Test.startTest();
        serviceAppointment.Status = 'Dispatched';
        update serviceAppointment;
        //Test.stopTest();
        List<HOT_Invoice__c> invoices = [
            SELECT Id
            FROM HOT_Invoice__c
            WHERE ServiceAppointment__c = :serviceAppointment.Id AND ServiceResource__c = :serviceResource.Id
        ];
        System.assertEquals(
            1,
            invoices.size(),
            'Det skulle blitt opprettet én invoice når en Service Appointment blir dispatched'
        );
        //

        Test.startTest();
        ServiceResource serviceResource2 = [
            SELECT Id
            FROM ServiceResource
            WHERE Name = 'Test Service Resource 2'
            LIMIT 1
        ];

        ar.ServiceResourceId = serviceResource2.Id;
        update ar;
        Test.stopTest();

        List<HOT_Invoice__c> updatedInvoices = [
            SELECT Id
            FROM HOT_Invoice__c
            WHERE ServiceAppointment__c = :serviceAppointment.Id AND ServiceResource__c = :serviceResource2.Id
        ];
        System.assertEquals(1, updatedInvoices.size(), 'Invoice skulle blitt oppdatert med ny tjenesteressurs.');
    }
    @IsTest
    static void notifyAboutInvoiceOnSaStatusChangedTest() {
        ServiceResource serviceResource = [SELECT Id FROM ServiceResource LIMIT 1];
        ServiceAppointment serviceAppointment = [SELECT Id FROM ServiceAppointment LIMIT 1];
        AssignedResource ar = HOT_TestDataFactory.createAssignedResource(serviceAppointment.Id, serviceResource.Id);
        insert ar;

        serviceAppointment.Status = 'Dispatched';
        update serviceAppointment;

        Test.startTest();
        serviceAppointment.Status = 'Completed';
        update serviceAppointment;
        Test.stopTest();
        List<HOT_Invoice__c> invoice = [
            SELECT Id
            FROM HOT_Invoice__c
            WHERE ServiceAppointment__c = :serviceAppointment.Id
        ];
        List<HOT_Notification__c> notifications = [
            SELECT Id
            FROM HOT_Notification__c
            WHERE HOT_RelatedObject__c = :invoice[0].Id
        ];
        System.assertEquals(
            1,
            notifications.size(),
            'Det skulle blitt opprettet en notification for invoice når en Service Appointment blir completed'
        );
    }
}
