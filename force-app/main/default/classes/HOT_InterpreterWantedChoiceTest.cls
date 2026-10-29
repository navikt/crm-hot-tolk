@IsTest
private class HOT_InterpreterWantedChoiceTest {
    @TestSetup
    static void setup() {
        Profile profile = [SELECT Id FROM Profile WHERE Id = :UserInfo.getProfileId()];
        System.runAs(new User(Id = UserInfo.getUserId())) {
            User otherUser = HOT_TestDataFactory.createUser('wantedch', profile);
            otherUser.Username = 'wantedchoice.' + System.now().getTime() + '@example.invalid';
            insert otherUser;
            PermissionSet permissions = [SELECT Id FROM PermissionSet WHERE Name = 'HOT_Tolk_Formidler'];
            insert new PermissionSetAssignment(AssigneeId = otherUser.Id, PermissionSetId = permissions.Id);
        }
        ServiceResource resource = HOT_TestDataFactory.createServiceResource(UserInfo.getUserId());
        insert resource;
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('Wanted choice', workType);
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder;
        WorkOrderLineItem lineItem = HOT_TestDataFactory.createWorkOrderLineItem(workOrder, workType);
        insert lineItem;
        ServiceAppointment appointment = HOT_TestDataFactory.createServiceAppointment(lineItem);
        insert appointment;
        insert new HOT_InterestedResource__c(
            ServiceResource__c = resource.Id,
            ServiceAppointment__c = appointment.Id,
            Status__c = 'Wanted',
            HOT_Wanted_by__c = 'Formidler'
        );
    }

    @IsTest
    static void findsWantedResourceForCurrentUser() {
        HOT_InterestedResource__c resource = getResource();
        Test.startTest();
        List<HOT_InterestedResource__c> results = HOT_InterpreterWantedChoiceController.getWantedResource(
            resource.ServiceAppointment__c
        );
        System.assertEquals(1, results.size());
        System.assertEquals('Formidler', results[0].HOT_Wanted_by__c);
        System.assertEquals(0, HOT_InterpreterWantedChoiceController.getWantedResource(null).size());
        Test.stopTest();
    }

    @IsTest
    static void registersInterest() {
        assertResponse('Interested');
    }

    @IsTest
    static void declines() {
        assertResponse('Declined');
    }

    private static void assertResponse(String status) {
        HOT_InterestedResource__c resource = getResource();
        Test.startTest();
        HOT_InterpreterWantedChoiceController.respond(resource.Id, status);
        Test.stopTest();
        System.assertEquals(status, getResource().Status__c);
        System.assertEquals(
            0,
            HOT_InterpreterWantedChoiceController.getWantedResource(resource.ServiceAppointment__c).size()
        );
    }

    @IsTest
    static void rejectsInvalidStatus() {
        assertRejected(getResource().Id, 'Assigned');
        System.assertEquals('Wanted', getResource().Status__c);
    }

    @IsTest
    static void rejectsStaleResponse() {
        HOT_InterestedResource__c resource = getResource();
        resource.Status__c = 'Interested';
        update resource;
        assertRejected(resource.Id, 'Declined');
        System.assertEquals('Interested', getResource().Status__c);
    }

    @IsTest
    static void rejectsAnotherUsersResource() {
        HOT_InterestedResource__c interestedResource = getResource();
        User otherUser = [SELECT Id FROM User WHERE Id != :UserInfo.getUserId() AND Alias = 'wantedch' LIMIT 1];
        System.runAs(otherUser) {
            System.assertEquals(
                0,
                HOT_InterpreterWantedChoiceController.getWantedResource(interestedResource.ServiceAppointment__c).size()
            );
            assertRejected(interestedResource.Id, 'Interested');
        }
        System.assertEquals('Wanted', getResource().Status__c);
    }

    private static void assertRejected(Id resourceId, String status) {
        Boolean rejected = false;
        try {
            HOT_InterpreterWantedChoiceController.respond(resourceId, status);
        } catch (AuraHandledException error) {
            rejected = true;
        }
        System.assert(rejected, 'The invalid response must be rejected');
    }

    private static HOT_InterestedResource__c getResource() {
        return [SELECT Id, Status__c, ServiceAppointment__c FROM HOT_InterestedResource__c LIMIT 1];
    }
}
