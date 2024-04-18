@IsTest
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
}
