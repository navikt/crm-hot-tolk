@IsTest
private class HOT_ServiceResourceControllerTest {
    @TestSetup
    static void setupUser() {
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Minimum Access - Salesforce' LIMIT 1];
        User formidler = HOT_TestDataFactory.createUser('overlap', profile);
        formidler.Username = 'overlap.' + System.now().getTime() + '@example.invalid';
        insert formidler;

        PermissionSet permissions = [SELECT Id FROM PermissionSet WHERE Name = 'HOT_Tolk_Formidler' LIMIT 1];
        insert new PermissionSetAssignment(AssigneeId = formidler.Id, PermissionSetId = permissions.Id);
    }

    @IsTest
    static void returnsNoResourcesWhenNoInterpreterTypesAreSelected() {
        Test.startTest();
        List<ServiceResource> resources = HOT_ServiceResourceController.getAllServiceResources(false, false, false);
        List<ServiceResource> resourcesWithNullFlags = HOT_ServiceResourceController.getAllServiceResources(
            null,
            null,
            null
        );
        List<HOT_InterestedResource__c> interestedResources = HOT_ServiceResourceController.interestedResourcesOfServiceAppointment(
            null
        );
        Test.stopTest();

        System.assertEquals(0, resources.size(), 'No interpreter types selected should return no resources.');
        System.assertEquals(0, resourcesWithNullFlags.size(), 'Null search flags should return no resources.');
        System.assertEquals(0, interestedResources.size(), 'No appointment should return no interested resources.');
    }

    @IsTest
    static void dispatcherSearchIsStandaloneAndFiltersResources() {
        ServiceResource dispatcher = createResource(UserInfo.getUserId(), 'Dispatcher');
        dispatcher.HOT_IsTjenesteleverandorDispatcher__c = true;
        User interpreterUser = [SELECT Id FROM User WHERE Alias = 'overlap' LIMIT 1];
        ServiceResource interpreter = createResource(interpreterUser.Id, 'Interpreter');
        interpreter.HOT_IsEmployedInterpreter__c = true;
        interpreter.HOT_IsFreelanceInterpreter__c = true;
        myTriggers.disable(HOT_ServiceResourceAccessHandler.class);
        insert new List<ServiceResource>{ dispatcher, interpreter };

        Test.startTest();
        for (Boolean searchFreelances : new List<Boolean>{ false, true }) {
            for (Boolean searchEmployees : new List<Boolean>{ false, true }) {
                List<ServiceResource> resources = HOT_ServiceResourceController.getAllServiceResources(
                    searchFreelances,
                    searchEmployees,
                    true
                );
                System.assertEquals(1, resources.size(), 'Dispatcher mode must not include other interpreters.');
                System.assertEquals(dispatcher.Id, resources[0].Id);
                System.assertEquals(true, resources[0].HOT_IsTjenesteleverandorDispatcher__c);
            }
        }

        dispatcher.IsActive = false;
        update dispatcher;
        System.assertEquals(0, HOT_ServiceResourceController.getAllServiceResources(false, false, true).size());

        dispatcher.IsActive = true;
        dispatcher.CRM_Subdomain__c = null;
        update dispatcher;
        System.assertEquals(0, HOT_ServiceResourceController.getAllServiceResources(false, false, true).size());

        dispatcher.CRM_Subdomain__c = 'Tolketjenesten';
        dispatcher.CRM_Domain__c = null;
        update dispatcher;
        System.assertEquals(0, HOT_ServiceResourceController.getAllServiceResources(false, false, true).size());
        Test.stopTest();
    }

    @IsTest
    static void preservesInterpreterSearchesWhenDispatcherSearchIsDisabled() {
        ServiceResource interpreter = createResource(UserInfo.getUserId(), 'Interpreter');
        interpreter.HOT_IsEmployedInterpreter__c = true;
        myTriggers.disable(HOT_ServiceResourceAccessHandler.class);
        insert interpreter;

        Test.startTest();
        System.assertEquals(1, HOT_ServiceResourceController.getAllServiceResources(false, true, false).size());
        System.assertEquals(1, HOT_ServiceResourceController.getAllServiceResources(true, true, false).size());
        System.assertEquals(1, HOT_ServiceResourceController.getAllServiceResources(false, true, null).size());
        System.assertEquals(1, HOT_ServiceResourceController.getAllServiceResources(null, true, false).size());
        System.assertEquals(0, HOT_ServiceResourceController.getAllServiceResources(true, false, false).size());
        System.assertEquals(0, HOT_ServiceResourceController.getAllServiceResources(true, null, false).size());

        interpreter.HOT_IsEmployedInterpreter__c = false;
        interpreter.HOT_IsFreelanceInterpreter__c = true;
        update interpreter;
        System.assertEquals(1, HOT_ServiceResourceController.getAllServiceResources(true, false, false).size());
        System.assertEquals(1, HOT_ServiceResourceController.getAllServiceResources(true, true, false).size());
        System.assertEquals(1, HOT_ServiceResourceController.getAllServiceResources(true, null, false).size());
        System.assertEquals(0, HOT_ServiceResourceController.getAllServiceResources(false, true, false).size());
        System.assertEquals(0, HOT_ServiceResourceController.getAllServiceResources(null, true, false).size());
        Test.stopTest();
    }

    private static ServiceResource createResource(Id userId, String name) {
        ServiceResource resource = HOT_TestDataFactory.createServiceResource(userId);
        resource.Name = name;
        resource.CRM_Domain__c = 'HOT';
        resource.CRM_Subdomain__c = 'Tolketjenesten';
        return resource;
    }
}
