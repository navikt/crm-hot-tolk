@isTest
private class HOT_InterestedResourceHandlerTest {
    @testSetup
    static void setup() {
        Account testAcc = new Account(Name='Test');

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

        HOT_Resource__c resource = new HOT_Resource__c();
        resource.Name = 'Test';
        resource.Service_Resource__c = serviceResource.Id;
        insert resource;

        HOT_ResourceMember__c resourceMember = new HOT_ResourceMember__c();
        resourceMember.Resource__c = resource.Id;
        resourceMember.Service_Resource__c = serviceResource.Id;
        insert resourceMember;

        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert WorkType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('HOT_ServiceAppointmentHandler', workType);
        request.PreferredResource1__c = resource.Id;
        request.NumberOfInterpreters__c = 3;
        insert request;

        ServiceAppointment serviceAppointment = new ServiceAppointment(
            OwnerId = user.Id,
            ParentRecordId = testAcc.Id,
            HOT_Request__c = request.Id,
            ServiceTerritoryId = serviceTerritory.Id,
            Status = 'In Progress',
            EarliestStartTime = DateTime.now().addDays(1),
            DueDate = DateTime.now().addDays(1)
        );

        HOT_InterestedResource__c interestedResource = new HOT_InterestedResource__c(
            ServiceResource__c = serviceResource.Id,
            Status__c = 'Interested',
            ServiceAppointment__c = serviceAppointment.Id
        );
    }

    @isTest
    static void changeStatusOfInterestedResource() {
        ServiceAppointment serviceAppointment = [
            SELECT Id
            FROM ServiceAppointment
        ];

        HOT_InterestedResource__c interestedResource = [
            SELECT Status__c
            FROM HOT_InterestedResource__c
            WHERE ServiceAppointment__c = :serviceAppointment.Id
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

        System.assertEquals(serviceAppointment.HOT_InterestedResourceNames__c, '');
    }

    @isTest
    static void addInterestedResourceToSA() {
        ServiceAppointment serviceAppointment = [
            SELECT Id
            FROM ServiceAppointment
        ];

        ServiceResource serviceResource = [
            SELECT Id
            FROM ServiceResource
        ];

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

        System.assertEquals(serviceAppointment.HOT_InterestedResourceNames__c, serviceResource.Name+', '+serviceResource.Name);
    }
    

    @isTest
    static void add255CharsOfInterestedResources() {
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' OR Name = 'Standardbruker' LIMIT 1];
        ServiceAppointment serviceAppointment = [SELECT Id FROM ServiceAppointment LIMIT 1];

        List<User> userList = new List<User>();
        List<ServiceResource> serviceResourceList = new List<ServiceResource>();
        List<HOT_InterestedResource__c> interestedResourcesList = new List<HOT_InterestedResource__c>();
        for (Integer i = 0; i < 12; i++) { // 12 iterations should exceed 255 chars when ServiceResource.name == 'Service Resource Name'
            User user = HOT_TestDataFactory.createUser('user'+i, profile);
            userList.add(user);
            ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(user.Id);
            serviceResourceList.add(serviceResource);
            interestedResourcesList.add(new HOT_InterestedResource__c(
                ServiceResource__c = serviceResource.Id,
                Status__c = 'Interested',
                ServiceAppointment__c = serviceAppointment.Id
            ));
        }
        insert userList;
        insert serviceResourceList;

        Test.startTest();
            insert interestedResourcesList;
        Test.stopTest();

        serviceAppointment = [
            SELECT HOT_InterestedResourceNames__c
            FROM ServiceAppointment
            WHERE Id = :serviceAppointment.Id
        ];

        String names = serviceAppointment.HOT_InterestedResourceNames__c;
        System.assertEquals(names.substring(names.length()-3, names.length()), '...');
    }
}
