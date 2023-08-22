@isTest
private class HOT_WantedSRListControllerTest {
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
        request.NumberOfInterpreters__c = 1;
        insert request;
        request.Status__c = 'Godkjent';
        update request;

        ServiceAppointment serviceAppointment = [
            SELECT Id, HOT_IsReleasedToFreelance__c, Status
            FROM ServiceAppointment WHERE HOT_Request__c =:request.Id
        ];
            serviceAppointment.HOT_IsReleasedToFreelance__c = true;
            serviceAppointment.Status = 'Released To Freelance';
            serviceAppointment.HOT_DeadlineDate__c = Date.today().addDays(3);

        update serviceAppointment;

         HOT_InterestedResource__c interestedResource=HOT_TestDataFactory.createInterestedResource(serviceAppointment.Id, serviceResource.Id);
         interestedResource.Status__c='Wanted';
        insert interestedResource;
    }
    @isTest
    static void getWantedSTListTest() {
        Profile profile = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User user1 = new User(alias = 'TestUser', email='HOT_testaccount@nav.hot.no',
        emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
        localesidkey='en_US', profileid = profile.Id , country='Norway',IsActive =true, timezonesidkey='Europe/Paris', username='HOT_testaccount@nav.hot.no');
        System.runAs(new User(Id = UserInfo.getUserId())){ 
            insert user1;

        List<ServiceAppointment> serviceAppointments = HOT_WantedSRListController.getWantedServiceAppointments();
        System.assertEquals(1, serviceAppointments.size(), 'Could not get the wanted appointments');

        }
    }
    @isTest
    static void updateIRTest() {
        ServiceAppointment sa = [SELECT Id FROM ServiceAppointment WHERE Subject ='Bestilling'];
        HOT_InterestedResource__c ir=[SELECT Id FROM HOT_InterestedResource__c WHERE ServiceAppointment__c=:sa.Id];
        ServiceResource sr =[SELECT Id, RelatedRecordId FROM ServiceResource WHERE RelatedRecordId=:UserInfo.getUserId()];
        HOT_WantedSRListController.updateInterestedResource(sa.Id, sr.Id);

        HOT_InterestedResource__c irToCheck=[SELECT Id FROM HOT_InterestedResource__c WHERE ServiceAppointment__c=:sa.Id];
        List <AssignedResource> arList = [SELECT Id FROM AssignedResource WHERE ServiceAppointmentId=:sa.Id AND ServiceResourceId=:sr.Id];


        System.assertEquals('Assigned', irToCheck.Status__c='Assigned', 'Could not change the ir status');
        System.assertEquals(1, arList.size(), 'Could not add assign resource');
    }
     @isTest
    static void declineIRTest() {
        ServiceAppointment sa = [SELECT Id FROM ServiceAppointment WHERE Subject ='Bestilling'];
        HOT_InterestedResource__c ir=[SELECT Id FROM HOT_InterestedResource__c WHERE ServiceAppointment__c=:sa.Id];
        ServiceResource sr =[SELECT Id, RelatedRecordId FROM ServiceResource WHERE RelatedRecordId=:UserInfo.getUserId()];
        HOT_WantedSRListController.declineInterestedResource(sa.Id, sr.Id);

        HOT_InterestedResource__c irToCheck=[SELECT Id FROM HOT_InterestedResource__c WHERE ServiceAppointment__c=:sa.Id];
        List <AssignedResource> arList = [SELECT Id FROM AssignedResource WHERE ServiceAppointmentId=:sa.Id AND ServiceResourceId=:sr.Id];


        System.assertEquals('Declined', irToCheck.Status__c='Declined', 'Could not change the ir status');
    }
}
