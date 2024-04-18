@IsTest
private class HOT_InterestedResourceHandlerTest {
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
    }

    @IsTest
    static void changeStatusOfInterestedResource() {
        ServiceAppointment serviceAppointment = [SELECT Id FROM ServiceAppointment LIMIT 1];

        HOT_InterestedResource__c interestedResource = [
            SELECT Status__c
            FROM HOT_InterestedResource__c
            WHERE ServiceAppointment__c = :serviceAppointment.Id
            LIMIT 1
        ];

        interestedResource.Status__c = 'Assigned';
        Test.startTest();
        update interestedResource;
        Test.stopTest();

        serviceAppointment = [
            SELECT HOT_InterestedResourceNames__c
            FROM ServiceAppointment
            WHERE Id = :serviceAppointment.Id
        ];

        System.assertEquals(null, serviceAppointment.HOT_InterestedResourceNames__c);
    }

    @IsTest
    static void addInterestedResourceToSA() {
        ServiceAppointment serviceAppointment = [SELECT Id FROM ServiceAppointment LIMIT 1];

        ServiceResource serviceResource = [SELECT Id, Name FROM ServiceResource LIMIT 1];

        HOT_InterestedResource__c interestedResource = new HOT_InterestedResource__c(
            ServiceResource__c = serviceResource.Id,
            Status__c = 'Interested',
            ServiceAppointment__c = serviceAppointment.Id
        );

        Test.startTest();
        insert interestedResource;
        Test.stopTest();

        serviceAppointment = [
            SELECT HOT_InterestedResourceNames__c
            FROM ServiceAppointment
            WHERE Id = :serviceAppointment.Id
        ];

        System.assertEquals(
            serviceResource.Name +
            ', ' +
            serviceResource.Name,
            serviceAppointment.HOT_InterestedResourceNames__c
        );
    }

    @IsTest
    static void add255CharsOfInterestedResources() {
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' OR Name = 'Standardbruker' LIMIT 1];
        ServiceAppointment serviceAppointment = [SELECT Id FROM ServiceAppointment LIMIT 1];

        List<User> userList = new List<User>();
        for (Integer i = 0; i < 12; i++) {
            // 12 iterations should exceed 255 chars when ServiceResource.name == 'Service Resource Name'
            User user = HOT_TestDataFactory.createUser('user' + i, profile);
            userList.add(user);
        }
        insert userList;

        List<ServiceResource> serviceResourceList = new List<ServiceResource>();
        for (Integer i = 0; i < 12; i++) {
            ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(userList.get(i).Id);
            serviceResourceList.add(serviceResource);
        }
        insert serviceResourceList;

        List<HOT_InterestedResource__c> interestedResourcesList = new List<HOT_InterestedResource__c>();
        for (Integer i = 0; i < 12; i++) {
            interestedResourcesList.add(
                new HOT_InterestedResource__c(
                    ServiceResource__c = serviceResourceList.get(i).Id,
                    Status__c = 'Interested',
                    ServiceAppointment__c = serviceAppointment.Id
                )
            );
        }

        Test.startTest();
        insert interestedResourcesList;
        Test.stopTest();

        serviceAppointment = [
            SELECT HOT_InterestedResourceNames__c
            FROM ServiceAppointment
            WHERE Id = :serviceAppointment.Id
        ];

        String names = serviceAppointment.HOT_InterestedResourceNames__c;
        System.assertEquals(names.substring(names.length() - 3, names.length()), '...');
    }
    @IsTest
    static void changeStatusOfInterestedResourceWhenAnIrIsAlreadyAssigned() {
        ServiceAppointment serviceAppointment = [SELECT Id FROM ServiceAppointment LIMIT 1];

        HOT_InterestedResource__c interestedResource = [
            SELECT Status__c
            FROM HOT_InterestedResource__c
            WHERE ServiceAppointment__c = :serviceAppointment.Id
            LIMIT 1
        ];

        interestedResource.Status__c = 'Assigned';
        Test.startTest();
        update interestedResource;

        User admin = [SELECT Id, UserRoleId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

        ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(admin.Id);
        insert serviceResource;

        HOT_InterestedResource__c interestedResource2 = HOT_TestDataFactory.createInterestedResource(
            ServiceAppointment.Id,
            serviceResource.Id
        );
        insert interestedResource2;
        Test.stopTest();

        HOT_InterestedResource__c irToCheck = [
            SELECT Status__c, ServiceResource__c
            FROM HOT_InterestedResource__c
            WHERE Id = :interestedResource2.Id
        ];

        System.assertEquals('Not Assigned', irToCheck.Status__c);
    }
}
