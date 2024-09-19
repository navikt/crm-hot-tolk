@isTest
private class HOT_FullCalendarControllerTest {
    @testSetup
    static void setup() {
        Profile otherUserProfile = [
            SELECT Id
            FROM Profile
            WHERE Name = 'HOT Tolk Formidler'
        ];

        User otherUser = HOT_TestDataFactory.createUser('Bruker', otherUserProfile);
        insert otherUser;

        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;

        HOT_Request__c request = HOT_TestDataFactory.createRequest('HOT_MySAListControllerTest', workType);
        insert request;
        request.Status__c = 'Godkjent';
        update request;

        ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(UserInfo.getUserId());
        insert serviceResource;

        ServiceAppointment serviceAppointment = [SELECT Id FROM ServiceAppointment LIMIT 1];
        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(
            serviceAppointment.Id,
            serviceResource.Id
        );
        insert assignedResource;

        HOT_WageClaim__c openClaim = HOT_TestDataFactory.createWageClaim(serviceResource);
        openClaim.Status__c = 'Open';
        insert openClaim;

        HOT_WageClaim__c retractedClaim = HOT_TestDataFactory.createWageClaim(serviceResource);
        retractedClaim.Status__c = 'Retracted Availability';
        insert retractedClaim;
    }

    @isTest
    static void getCalendarEventsTest() {
        ServiceAppointment appointment = [SELECT Id FROM ServiceAppointment LIMIT 1];
        Test.startTest();
        List<HOT_FullCalendarController.CalendarEvent> events = HOT_FullCalendarController.getCalendarEvents();
        Test.stopTest();
        System.assert(
            events.size() == 2 && events[0].id == appointment.Id,
            'Should return one event with same Id as ServiceAppointment'
        );
    }

    @isTest
    static void getCalendarEventsAsOtherUser() {
        User otherUser = [SELECT Id FROM User WHERE LastName = 'Bruker'];

        Test.startTest();
        List<HOT_FullCalendarController.CalendarEvent> events = new List<HOT_FullCalendarController.CalendarEvent>();
        Test.stopTest();
        System.runAs(otherUser) {
            events = HOT_FullCalendarController.getCalendarEvents();
        }

        System.assert(events.isEmpty(), 'Should not return any ServiceAppointment');
    }

    @isTest
    static void getUserServiceAppointments() {
        Test.startTest();
        List<ServiceAppointment> appointments = HOT_FullCalendarController.getUserServiceAppointments();
        Test.stopTest();
        System.assertEquals(1, appointments.size(), 'Should retrieve one ServiceAppointment');
    }

    @isTest
    static void getUserOpenWageClaims() {
        Test.startTest();
        List<HOT_WageClaim__c> claims = HOT_FullCalendarController.getUserOpenWageClaims();
        Test.stopTest();
        System.assertEquals(1, claims.size(), 'Should only retrieve wage claims with Status__c == \'Open\'');
    }
}
