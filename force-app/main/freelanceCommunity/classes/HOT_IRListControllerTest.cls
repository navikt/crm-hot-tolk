@IsTest
private class HOT_IRListControllerTest {
    @testSetup
    static void setup() {
        Serviceresource serviceResource = HOT_TestDataFactory.createServiceResource(UserInfo.getUserId());
        insert serviceResource;
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('Bestilling', workType);
        insert request;
        request.Status__c = 'Godkjent';
        update request;

        ServiceAppointment serviceAppointment = [SELECT Id FROM ServiceAppointment];
        Hot_interestedresource__c interestedResource = new Hot_interestedresource__c(
            ServiceAppointment__c = serviceAppointment.Id,
            ServiceResource__c = serviceResource.Id,
            Comments__c = 'Test Value',
            Status__c = 'Interested'
        );
        insert interestedResource;
    }

    @IsTest
    static void getInterestedResourcesTest() {
        List<HOT_InterestedResource__c> interestedResources = HOT_InterestedResourcesListController.getInterestedResources();
        System.assertEquals(1, interestedResources.size(), 'Could not get list of interested resources');
    }
    @IsTest
    static void checkAccessToSA() {
        ServiceAppointment serviceAppointment = [SELECT Id FROM ServiceAppointment];
        Boolean access = HOT_InterestedResourcesListController.checkAccessToSA(serviceAppointment.Id);
        System.assertEquals(true, access, 'Should have access to this sa');
    }

    @IsTest
    static void getThreadDispatcherIdSATest() {
        ServiceAppointment serviceAppointment = [SELECT Id FROM ServiceAppointment];
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' OR Name = 'Standardbruker' LIMIT 1];
        User user = HOT_TestDataFactory.createUser('user', profile);
        insert user;
        ServiceResource resource = HOT_TestDataFactory.createServiceResource(user.Id);
        insert resource;

        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(
            serviceAppointment.Id,
            resource.Id
        );
        insert assignedResource;
        Thread__c thread = HOT_TestDataFactory.createThread();
        thread.CRM_Related_Object__c = serviceAppointment.Id;
        insert thread;
        String threadId = HOT_InterestedResourcesListController.getThreadDispatcherIdSA(serviceAppointment.Id);
        System.assertNotEquals(null, threadId, 'Could not get SA Thread');
    }
    @IsTest
    static void getThreadDispatcherIdTest() {
        HOT_InterestedResource__c ir = [SELECT Id FROM HOT_InterestedResource__c];
        Thread__c thread = HOT_TestDataFactory.createThread();
        thread.CRM_Related_Object__c = ir.Id;
        insert thread;
        String threadId = HOT_InterestedResourcesListController.getThreadDispatcherId(ir.Id);
        System.assertNotEquals(null, threadId, 'Could not get SA Thread');
    }

    @IsTest
    static void retractInterestsTest() {
        HOT_InterestedResource__c interestedResource = [SELECT Id, Status__c FROM HOT_InterestedResource__c];
        List<Id> retractionIds = new List<Id>{ interestedResource.Id };
        HOT_InterestedResourcesListController.retractInterests(retractionIds);
        HOT_InterestedResource__c updatedInterestedResource = [
            SELECT Id, Status__c
            FROM HOT_InterestedResource__c
            WHERE Id = :interestedResource.Id
        ];
        System.assertEquals('Retracted Interest', updatedInterestedResource.Status__c, 'Status was not updated');
    }
    @IsTest
    static void resendInterestTest() {
        HOT_InterestedResource__c interestedResource = [SELECT Id, Status__c FROM HOT_InterestedResource__c];
        List<Id> retractionIds = new List<Id>{ interestedResource.Id };
        HOT_InterestedResourcesListController.retractInterests(retractionIds);
        HOT_InterestedResourcesListController.resendInterest(interestedResource.Id);
        HOT_InterestedResource__c updatedInterestedResource = [
            SELECT Id, Status__c
            FROM HOT_InterestedResource__c
            WHERE Id = :interestedResource.Id
        ];
        System.assertEquals('Interested', updatedInterestedResource.Status__c, 'Status was not updated');
    }

    @IsTest
    static void testRetractInterest() {
        HOT_InterestedResource__c interestedResource = [SELECT Id, Status__c FROM HOT_InterestedResource__c];
        interestedResource.Status__c = 'Interested';
        update interestedResource;

        HOT_InterestedResourcesListController.retractInterest(interestedResource.Id);

        HOT_InterestedResource__c updatedInterestedResource = [
            SELECT Id, Status__c
            FROM HOT_InterestedResource__c
            WHERE Id = :interestedResource.Id
        ];
        System.assertEquals(updatedInterestedResource.Status__c, 'Retracted Interest');
    }
    @IsTest
    static void startAThreadAndAddCommentTest() {
        HOT_InterestedResource__c interestedResource = [SELECT Id, Status__c FROM HOT_InterestedResource__c];

        String newComment = 'This is a test comment';

        Test.startTest();
        Thread__c thread = HOT_InterestedResourcesListController.startAThreadAndAddComment(
            interestedResource.Id,
            newComment,
            null
        );
        Test.stopTest();

        System.assertNotEquals(null, thread, 'Thread was not made');
    }
    @IsTest
    static void getIRDetails() {
        ServiceResource serviceResource = [
            SELECT Id
            FROM ServiceResource
            WHERE RelatedRecordId = :UserInfo.getUserId()
        ];

        HOT_InterestedResource__c interestedResource = [
            SELECT Id, Status__c, AppointmentNumber__c, ServiceResource__c, ServiceAppointment__c
            FROM HOT_InterestedResource__c
        ];
        interestedResource.ServiceResource__c = serviceResource.Id;
        update interestedResource;
        Test.startTest();

        HOT_InterestedResource__c irResult = HOT_InterestedResourcesListController.getInterestedResourceDetails(
            interestedResource.ServiceAppointment__c
        );
        System.assertEquals(
            irResult.AppointmentNumber__c,
            interestedResource.AppointmentNumber__c,
            'Did not get the correct IR details'
        );

        Test.stopTest();
    }
}
