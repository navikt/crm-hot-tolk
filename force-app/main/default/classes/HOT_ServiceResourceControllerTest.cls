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
        List<ServiceResource> resources = HOT_ServiceResourceController.getAllServiceResources(false, false);
        List<HOT_InterestedResource__c> interestedResources = HOT_ServiceResourceController.interestedResourcesOfServiceAppointment(
            null
        );
        Test.stopTest();

        System.assertEquals(0, resources.size(), 'No interpreter types selected should return no resources.');
        System.assertEquals(0, interestedResources.size(), 'No appointment should return no interested resources.');
    }
}
