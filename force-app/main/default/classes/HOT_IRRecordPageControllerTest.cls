@isTest
private class HOT_IRRecordPageControllerTest {
    @TestSetup
    static void makeData() {
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
    }

    @isTest
    static void getRelevantServiceAppointmentsTest() {
        ID id = [SELECT id FROM HOT_InterestedResource__c LIMIT 1].id;
        Test.startTest();
        try {
            HOT_IRRecordPageController.getRelevantServiceAppointments(id);
        } catch (AurahandledException e) {
            System.assertEquals('Script-thrown exception', e.getMessage());
        }
        Test.stopTest();
    }
    @isTest
    static void getRelevantInterestedResourcesTest() {
        ServiceAppointment serviceAppointment = [
            SELECT Id
            FROM ServiceAppointment
            WHERE HOT_NumberOfInterestedResources__c = 0
            LIMIT 1
        ];
        Test.startTest();
        List<HOT_InterestedResource__c> relevantInterestedResources = HOT_IRRecordPageController.getRelevantInterestedResources(
            serviceAppointment.Id
        );
        System.assertEquals(relevantInterestedResources.size(), 1, 'Should be 1 relevant interested resource');
        Test.stopTest();
    }
}
