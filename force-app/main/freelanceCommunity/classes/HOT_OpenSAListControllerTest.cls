@IsTest(IsParallel=true)
private class HOT_OpenSAListControllerTest {
    @testSetup
    static void setup() {
        OperatingHours operatingHours = HOT_TestDataFactory.createOperatingHours();
        insert operatingHours;
        ServiceTerritory serviceTerritory = HOT_TestDataFactory.createServiceTerritory(operatingHours);
        insert serviceTerritory;

        Serviceresource serviceResource = HOT_TestDataFactory.createServiceResource(UserInfo.getUserId());
        insert serviceResource;
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('Bestilling', workType);
        request.ServiceTerritory__c = serviceTerritory.Id;
        request.NumberOfInterpreters__c = 2;
        insert request;
        request.Status__c = 'Godkjent';
        update request;

        List<ServiceAppointment> serviceAppointments = [
            SELECT Id, HOT_IsReleasedToFreelance__c, Status
            FROM ServiceAppointment
        ];
        for (ServiceAppointment serviceAppointment : serviceAppointments) {
            serviceAppointment.HOT_IsReleasedToFreelance__c = true;
            serviceAppointment.Status = 'Released To Freelance';
            serviceAppointment.HOT_DeadlineDate__c = Date.today().addDays(3);
        }
        update serviceAppointments;
    }

    //As Skill is not supported by Apex Metadata API or DML operations, we cannot make a proper test for the class
    @IsTest
    static void getOpenServiceAppointmentsTest() {
        List<ServiceAppointment> serviceAppointments = HOT_OpenServiceAppointmentListController.getOpenServiceAppointments();
        System.assertEquals(2, serviceAppointments.size(), 'Could not get released ServiceAppointments');
    }

    @IsTest
    static void createInterestedResourcesTest() {
        List<ServiceAppointment> serviceAppointments = [SELECT Id, AppointmentNumber FROM ServiceAppointment];
        List<String> serviceAppointmentIds = new List<String>();
        List<String> comments = new List<String>();
        for (ServiceAppointment sa : serviceAppointments) {
            serviceAppointmentIds.add(sa.Id);
            comments.add('Comment 1');
        }
        HOT_OpenServiceAppointmentListController.createInterestedResources(serviceAppointmentIds, comments);

        List<HOT_InterestedResource__c> interestedResources = [SELECT Id FROM HOT_InterestedResource__c];
        System.assertEquals(2, interestedResources.size(), 'Could not createInterestedResources');
    }
    @IsTest
    static void createInterestedResourceByUpdatingExistingTest() {
        ServiceResource serviceResource = [SELECT Id FROM ServiceResource LIMIT 1];
        ServiceAppointment serviceAppointment = [SELECT Id, AppointmentNumber FROM ServiceAppointment LIMIT 1];
        HOT_InterestedResource__c interestedResource = new HOT_InterestedResource__c();
        interestedResource.Status__c = null;
        interestedResource.ServiceResource__c = serviceResource.Id;
        interestedResource.ServiceAppointment__c = serviceAppointment.Id;
        insert interestedResource;

        List<String> serviceAppointmentIds = new List<String>();
        List<String> comments = new List<String>();
        serviceAppointmentIds.add(serviceAppointment.Id);
        comments.add('Comment 1');
        Test.startTest();
        HOT_OpenServiceAppointmentListController.createInterestedResources(serviceAppointmentIds, comments);
        Test.stopTest();
        List<HOT_InterestedResource__c> interestedResources = [
            SELECT Id
            FROM HOT_InterestedResource__c
            WHERE ServiceAppointment__c = :serviceAppointment.Id
        ];
        List<Thread__c> threads = [
            SELECT Id
            FROM Thread__c
            WHERE CRM_Related_Object__c = :interestedResource.Id AND CRM_Number_of_Messages__c = 1
        ];
        System.assertEquals(1, interestedResources.size(), 'Could not createInterestedResources');
        System.assertEquals(1, threads.size(), 'Could not thread');
    }
    @IsTest
    static void createInterestedResourceByUpdatingExistingAndExtistingThreadTest() {
        ServiceResource serviceResource = [SELECT Id FROM ServiceResource LIMIT 1];
        ServiceAppointment serviceAppointment = [SELECT Id, AppointmentNumber FROM ServiceAppointment LIMIT 1];
        HOT_InterestedResource__c interestedResource = new HOT_InterestedResource__c();
        interestedResource.Status__c = null;
        interestedResource.ServiceResource__c = serviceResource.Id;
        interestedResource.ServiceAppointment__c = serviceAppointment.Id;
        insert interestedResource;

        Thread__c thread = new Thread__c();
        thread.CRM_Related_Object__c = interestedResource.Id;
        insert thread;

        Message__c message = new Message__c();
        message.CRM_Thread__c = thread.Id;
        message.CRM_Message_Text__c = 'Dette er en testmelding';
        insert message;

        List<String> serviceAppointmentIds = new List<String>();
        List<String> comments = new List<String>();
        serviceAppointmentIds.add(serviceAppointment.Id);
        comments.add('Comment 1');
        Test.startTest();
        HOT_OpenServiceAppointmentListController.createInterestedResources(serviceAppointmentIds, comments);
        Test.stopTest();
        List<HOT_InterestedResource__c> interestedResources = [
            SELECT Id
            FROM HOT_InterestedResource__c
            WHERE ServiceAppointment__c = :serviceAppointment.Id
        ];
        List<Thread__c> threads = [
            SELECT Id
            FROM Thread__c
            WHERE CRM_Related_Object__c = :interestedResource.Id AND CRM_Number_of_Messages__c = 2
        ];
        System.assertEquals(1, interestedResources.size(), 'Could not createInterestedResources');
        System.assertEquals(1, threads.size(), 'Should continue on existing thread');
    }
}
