@IsTest(IsParallel=true)
public class HOT_ProcessBuilderMigrationTest {
    @IsTest
    public static void personProcessorTest() {
        Person__c person = HOT_TestDataFactory.createPerson();
        person.HOT_DailyLifeInterpreter__c = true;
        person.INT_KrrEmail__c = 'test.test@test.test';
        person.INT_KrrMobilePhone__c = '+4744444444';
        person.INT_LastUpdatedFromKRR__c = Datetime.now();
        insert person;

        Account account = [SELECT PersonEmail, PersonMobilePhone FROM Account WHERE CRM_Person__c = :person.Id];
        System.assertEquals(null, account.PersonEmail, 'Email was set too early');
        System.assertEquals(null, account.PersonMobilePhone, 'Phone was set too early');

        person.INT_LastUpdatedFromKRR__c = Datetime.now().addHours(1);
        Test.startTest();
        update person;
        Test.stopTest();

        account = [SELECT PersonEmail, PersonMobilePhone FROM Account WHERE CRM_Person__c = :person.Id];
        System.assertEquals(person.INT_KrrEmail__c, account.PersonEmail, 'Email was NOT set correctly');
        System.assertEquals(person.INT_KrrMobilePhone__c, account.PersonMobilePhone, 'Phone was NOT set correctly');
    }

    @IsTest
    public static void requestInitiatorTest() {
        //Test manually. Not critical functionality
    }

    @IsTest
    public static void requestProcessorSetAccountPerson() {
        Person__c person = HOT_TestDataFactory.createPerson();
        person.HOT_DailyLifeInterpreter__c = true;
        person.INT_KrrEmail__c = 'test.test@test.test';
        person.INT_KrrMobilePhone__c = '+4744444444';
        person.INT_LastUpdatedFromKRR__c = Datetime.now();
        insert person;

        Account account = [SELECT Id FROM Account WHERE CRM_Person__c = :person.Id];

        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('subject', workType);
        request.Account__c = account.Id;
        insert request;

        request = [SELECT Person__c, Account__c FROM HOT_Request__c WHERE Id = :request.Id];
        System.assertEquals(account.Id, request.Account__c, 'Could not set account field on request');
        System.assertEquals(person.Id, request.Person__c, 'Could not set person field on request');

        //Remove person
        request.Account__c = null;
        update request;

        request = [SELECT Person__c, Account__c FROM HOT_Request__c WHERE Id = :request.Id];
        System.assertEquals(null, request.Account__c, 'Could not remove account field on request');
        System.assertEquals(null, request.Person__c, 'Could not remove person field on request');

        //set person
        request.Account__c = account.Id;
        update request;

        request = [SELECT Person__c, Account__c FROM HOT_Request__c WHERE Id = :request.Id];
        System.assertEquals(account.Id, request.Account__c, 'Could not set account field on request');
        System.assertEquals(person.Id, request.Person__c, 'Could not set person field on request');

        //Status annullert
        request.Status__c = 'Annullert';
        update request;

        request = [SELECT Status__c, Person__c, Account__c FROM HOT_Request__c WHERE Id = :request.Id];
        System.assertEquals('Annullert', request.Status__c, 'Could not set Status field on request');
        System.assertEquals(null, request.Account__c, 'Could not remove account field on request');
        System.assertEquals(null, request.Person__c, 'Could not remove person field on request');
    }

    @IsTest
    public static void serviceTerritoryMemberTest() {
        OperatingHours operatingHours = HOT_TestDataFactory.createOperatingHours();
        insert operatingHours;
        ServiceTerritory serviceTerritory = HOT_TestDataFactory.createServiceTerritory(operatingHours);
        serviceTerritory.HOT_DeveloperName__c = 'Territory';
        insert serviceTerritory;
        ServiceTerritory newServiceTerritory = HOT_TestDataFactory.createServiceTerritory(operatingHours);
        newServiceTerritory.HOT_DeveloperName__c = 'newServiceTerritory';
        insert newServiceTerritory;

        ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(USerInfo.getUserId());
        insert serviceResource;

        ServiceTerritoryMember serviceTerritoryMember = HOT_TestDataFactory.createServiceTerritoryMember(
            serviceResource,
            serviceTerritory
        );
        serviceTerritoryMember.TerritoryType = 'P';

        insert serviceTerritoryMember;

        serviceResource = [SELECT HOT_ServiceTerritory__c FROM ServiceResource WHERE Id = :serviceResource.Id];
        System.assertEquals(
            serviceTerritory.Id,
            serviceResource.HOT_ServiceTerritory__c,
            'Could not set service territory field on Service resource'
        );

        ServiceTerritoryMember newServiceTerritoryMember = HOT_TestDataFactory.createServiceTerritoryMember(
            serviceResource,
            newServiceTerritory
        );
        newServiceTerritoryMember.TerritoryType = 'P';
        serviceTerritoryMember.TerritoryType = 'S';
        update serviceTerritoryMember;

        Test.startTest();
        insert newServiceTerritoryMember;
        Test.stopTest();
        serviceResource = [SELECT HOT_ServiceTerritory__c FROM ServiceResource WHERE Id = :serviceResource.Id];
        System.assertEquals(
            newServiceTerritory.Id,
            serviceResource.HOT_ServiceTerritory__c,
            'Could not update service territory field on Service resource'
        );
    }

    @IsTest
    public static void workOrderLineItemTest() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('subject', workType);
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder;
        WorkOrderLineItem workOrderLineItem = HOT_TestDataFactory.createWorkOrderLineItem(workOrder, workType);
        workOrderLineItem.StartDate = Datetime.now().addDays(1);
        workOrderLineItem.EndDate = workOrderLineItem.StartDate.addHours(1);
        insert workOrderLineItem;

        workOrderLineItem = [
            SELECT Duration, StartDate, EndDate
            FROM workOrderLineItem
            WHERE Id = :workOrderLineItem.Id
        ];
        System.assertEquals(1, workOrderLineItem.Duration, 'Could not correctly calculate Duration');

        workOrderLineItem.StartDate = workOrderLineItem.StartDate.addMinutes(30);
        update workOrderLineItem;
        workOrderLineItem = [
            SELECT Duration, StartDate, EndDate
            FROM workOrderLineItem
            WHERE Id = :workOrderLineItem.Id
        ];
        System.assertEquals(0.5, workOrderLineItem.Duration, 'Could not correctly calculate Duration');
        workOrderLineItem.EndDate = workOrderLineItem.EndDate.addHours(23);
        update workOrderLineItem;
        workOrderLineItem = [
            SELECT Duration, StartDate, EndDate
            FROM workOrderLineItem
            WHERE Id = :workOrderLineItem.Id
        ];
        System.assertEquals(23.5, workOrderLineItem.Duration, 'Could not correctly calculate Duration');
    }
}
