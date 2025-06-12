@isTest
private class HOT_InterestedResourceNotificationTest {

    @testSetup
    static void setup() {
        OperatingHours operatingHours = HOT_TestDataFactory.createOperatingHours();
        insert operatingHours;
        ServiceTerritory serviceTerritory = HOT_TestDataFactory.createServiceTerritory(operatingHours);
        insert serviceTerritory;

        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' OR Name = 'Standardbruker' LIMIT 1];
        User user = HOT_TestDataFactory.createUser('user', profile);
        insert user;

        ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(user.Id);
        serviceResource.HOT_IsFreelanceInterpreter__c = true;
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
        insert request;
        request.Status__c = 'Godkjent';
        update request;

        ServiceAppointment serviceAppointment = [SELECT Id FROM ServiceAppointment LIMIT 1];

        HOT_InterestedResource__c interestedResource = new HOT_InterestedResource__c(
            ServiceResource__c = serviceResource.Id,
            Status__c = 'Interested',
            ServiceAppointment__c = serviceAppointment.Id
        );
        insert interestedResource;

        /*HOT_InterestedResource__c errResource = new HOT_InterestedResource__c(
            ServiceResource__c = serviceResource.Id,
            Status__c = 'Interested',
            ServiceAppointment__c = serviceAppointment.Id
        );
        insert errResource;*/
    }

    @isTest
    static void CustomNotificationTypeTest() {

        String devName = [SELECT DeveloperName FROM CustomNotificationType LIMIT 1].DeveloperName;

        Test.startTest();
        HOT_InterestedResourceNotification.getCustomNotificationType(devName);
        Test.stopTest();
    }

    @isTest
    static void InterestedUserIdTest() {

        list<id> ids = new List<id>{[SELECT id FROM HOT_InterestedResource__c LIMIT 1].id};

        Test.startTest();
        HOT_InterestedResourceNotification.newWantedServiceResource(ids);
        Test.stopTest();
    }

    /* //Nothing gives an error on the insert, so its impossible to catch
    @isTest
    static void InterestedPushTestErr() {

        list<id> ids = new List<id>{[SELECT id FROM HOT_InterestedResource__c].id};

        Test.startTest();
        HOT_InterestedResourceNotification.newWantedServiceResource(ids);
        Test.stopTest();
    }*/
}