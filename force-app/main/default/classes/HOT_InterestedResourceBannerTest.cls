@IsTest
public with sharing class HOT_InterestedResourceBannerTest {
    @TestSetup
    static void makeData() {
        Test.startTest();
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User user1 = new User(
            alias = 'TestUser',
            email = 'HOT_testaccount@nav.hot.no',
            emailencodingkey = 'UTF-8',
            lastname = 'Testing',
            languagelocalekey = 'en_US',
            localesidkey = 'en_US',
            profileid = profile.Id,
            country = 'Norway',
            IsActive = true,
            timezonesidkey = 'Europe/Paris',
            username = 'HOT_testaccount@nav.hot.no'
        );

        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert user1;

            PermissionSet permissionSet = [SELECT Id, Name FROM PermissionSet WHERE Name = 'HOT_Tolk_Formidler'];
            insert new PermissionSetAssignment(AssigneeId = user1.id, PermissionSetId = permissionSet.Id);
        }
        Test.stopTest();
    }
    @IsTest
    static void OneOverlap() {
        User user1 = [SELECT Id FROM User WHERE email = 'HOT_testaccount@nav.hot.no' LIMIT 1];

        ServiceResource resource1 = HOT_TestDataFactory.createServiceResource(user1.Id);
        insert resource1;

        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;

        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;

        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder;
        WorkOrderLineItem WorkOrderLineItem = HOT_TestDataFactory.createWorkOrderLineItem(workOrder, workType);
        insert WorkOrderLineItem;
        ServiceAppointment ServiceAppointment = HOT_TestDataFactory.createServiceAppointment(WorkOrderLineItem);
        ServiceAppointment.EarliestStartTime = Datetime.now().addDays(50);
        ServiceAppointment.DueDate = ServiceAppointment.EarliestStartTime.addHours(2);
        ServiceAppointment.SchedStartTime = Datetime.now().addDays(50);
        ServiceAppointment.SchedEndTime = ServiceAppointment.SchedStartTime.addHours(2);
        insert ServiceAppointment;
        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(
            ServiceAppointment.Id,
            resource1.Id
        );
        insert assignedResource;

        HOT_Request__c request4 = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request4;
        Test.startTest();
        WorkOrder workOrder4 = HOT_TestDataFactory.createWorkOrder(request4, workType);
        insert workOrder4;
        WorkOrderLineItem WorkOrderLineItem4 = HOT_TestDataFactory.createWorkOrderLineItem(workOrder4, workType);
        insert WorkOrderLineItem4;

        ServiceAppointment ServiceAppointment3 = HOT_TestDataFactory.createServiceAppointment(WorkOrderLineItem4);
        ServiceAppointment3.EarliestStartTime = Datetime.now().addDays(52);
        ServiceAppointment3.DueDate = ServiceAppointment3.EarliestStartTime.addHours(2);
        ServiceAppointment3.SchedStartTime = Datetime.now().addDays(52);
        ServiceAppointment3.SchedEndTime = ServiceAppointment3.SchedStartTime.addHours(2);
        insert ServiceAppointment3;
        AssignedResource assignedResource3 = HOT_TestDataFactory.createAssignedResource(
            ServiceAppointment3.Id,
            resource1.Id
        );
        insert assignedResource3;

        HOT_Request__c request3 = HOT_TestDataFactory.createRequest('TEST', workType);
        request3.StartTime__c = Datetime.now().addDays(52);
        request3.EndTime__c = request3.StartTime__c.addHours(2);
        insert request3;

        WorkOrder workOrder3 = HOT_TestDataFactory.createWorkOrder(request3, workType);
        insert workOrder3;
        WorkOrderLineItem WorkOrderLineItem3 = HOT_TestDataFactory.createWorkOrderLineItem(workOrder3, workType);
        insert WorkOrderLineItem3;

        ServiceAppointment ServiceAppointment2 = HOT_TestDataFactory.createServiceAppointment(WorkOrderLineItem3);
        ServiceAppointment2.EarliestStartTime = Datetime.now().addDays(52);
        ServiceAppointment2.DueDate = ServiceAppointment2.EarliestStartTime.addHours(2);
        ServiceAppointment2.SchedStartTime = Datetime.now().addDays(52);
        ServiceAppointment2.SchedEndTime = ServiceAppointment2.SchedStartTime.addHours(2);
        insert ServiceAppointment2;
        HOT_InterestedResource__c interestedResource = HOT_TestDataFactory.createInterestedResource(
            ServiceAppointment2.Id,
            resource1.Id
        );
        insert interestedResource;

        List<ServiceAppointment> result = HOT_InterestedResourceBannerController.checkForOverlap(interestedResource.Id);
        System.assertEquals(1, result.size(), 'Er 1 oppdrag som skal vises som overlappende');
        Test.stopTest();
    }
    @IsTest
    static void NoOverlap() {
        User user1 = [SELECT Id FROM User WHERE email = 'HOT_testaccount@nav.hot.no' LIMIT 1];

        ServiceResource resource1 = HOT_TestDataFactory.createServiceResource(user1.Id);
        insert resource1;

        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;

        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder;
        WorkOrderLineItem WorkOrderLineItem = HOT_TestDataFactory.createWorkOrderLineItem(workOrder, workType);
        insert WorkOrderLineItem;
        ServiceAppointment ServiceAppointment = HOT_TestDataFactory.createServiceAppointment(WorkOrderLineItem);
        ServiceAppointment.EarliestStartTime = Datetime.now().addDays(52);
        ServiceAppointment.DueDate = ServiceAppointment.EarliestStartTime.addHours(2);
        ServiceAppointment.SchedStartTime = Datetime.now().addDays(52);
        ServiceAppointment.SchedEndTime = ServiceAppointment.SchedStartTime.addHours(2);
        insert ServiceAppointment;
        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(
            ServiceAppointment.Id,
            resource1.Id
        );
        insert assignedResource;

        HOT_Request__c request2 = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request2;
        WorkOrder workOrder2 = HOT_TestDataFactory.createWorkOrder(request2, workType);
        insert workOrder2;
        WorkOrderLineItem WorkOrderLineItem2 = HOT_TestDataFactory.createWorkOrderLineItem(workOrder2, workType);
        insert WorkOrderLineItem2;

        ServiceAppointment ServiceAppointment2 = HOT_TestDataFactory.createServiceAppointment(WorkOrderLineItem2);
        ServiceAppointment2.EarliestStartTime = Datetime.now().addDays(53);
        ServiceAppointment2.DueDate = ServiceAppointment2.EarliestStartTime.addHours(2);
        ServiceAppointment2.SchedStartTime = Datetime.now().addDays(53);
        ServiceAppointment2.SchedEndTime = ServiceAppointment2.SchedStartTime.addHours(2);
        insert ServiceAppointment2;
        HOT_InterestedResource__c interestedResource = HOT_TestDataFactory.createInterestedResource(
            ServiceAppointment2.Id,
            resource1.Id
        );
        insert interestedResource;

        List<ServiceAppointment> result = HOT_InterestedResourceBannerController.checkForOverlap(interestedResource.Id);
        Test.startTest();
        System.assertEquals(0, result.size(), 'Er 0 oppdrag som skal vises som overlappende');
        Test.stopTest();
    }
    @IsTest
    static void checkTwoOverlap() {
        User user1 = [SELECT Id FROM User WHERE email = 'HOT_testaccount@nav.hot.no' LIMIT 1];

        ServiceResource resource1 = HOT_TestDataFactory.createServiceResource(user1.Id);
        insert resource1;

        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;

        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;

        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder;

        WorkOrderLineItem WorkOrderLineItem = HOT_TestDataFactory.createWorkOrderLineItem(workOrder, workType);
        insert WorkOrderLineItem;
        ServiceAppointment ServiceAppointment = HOT_TestDataFactory.createServiceAppointment(WorkOrderLineItem);
        ServiceAppointment.EarliestStartTime = Datetime.now().addHours(1);
        ServiceAppointment.DueDate = ServiceAppointment.EarliestStartTime.addHours(3);
        ServiceAppointment.SchedStartTime = Datetime.now().addHours(1);
        ServiceAppointment.SchedEndTime = ServiceAppointment.SchedStartTime.addHours(3);
        insert ServiceAppointment;
        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(
            ServiceAppointment.Id,
            resource1.Id
        );
        insert assignedResource;

        HOT_Request__c request2 = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request2;
        Test.startTest();
        WorkOrder workOrder2 = HOT_TestDataFactory.createWorkOrder(request2, workType);
        insert workOrder2;
        WorkOrderLineItem WorkOrderLineItem2 = HOT_TestDataFactory.createWorkOrderLineItem(workOrder2, workType);
        insert WorkOrderLineItem2;

        ServiceAppointment ServiceAppointment2 = HOT_TestDataFactory.createServiceAppointment(WorkOrderLineItem2);
        ServiceAppointment2.EarliestStartTime = Datetime.now().addHours(6);
        ServiceAppointment2.DueDate = ServiceAppointment2.EarliestStartTime.addHours(8);
        ServiceAppointment2.SchedStartTime = Datetime.now().addHours(6);
        ServiceAppointment2.SchedEndTime = ServiceAppointment2.SchedStartTime.addHours(8);
        insert ServiceAppointment2;
        AssignedResource assignedResource2 = HOT_TestDataFactory.createAssignedResource(
            ServiceAppointment2.Id,
            resource1.Id
        );
        insert assignedResource2;

        HOT_Request__c request3 = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request3;

        WorkOrder workOrder3 = HOT_TestDataFactory.createWorkOrder(request3, workType);
        insert workOrder3;
        WorkOrderLineItem WorkOrderLineItem3 = HOT_TestDataFactory.createWorkOrderLineItem(workOrder3, workType);
        insert WorkOrderLineItem3;

        ServiceAppointment ServiceAppointment3 = HOT_TestDataFactory.createServiceAppointment(WorkOrderLineItem3);
        ServiceAppointment3.EarliestStartTime = Datetime.now().addHours(2);
        ServiceAppointment3.DueDate = ServiceAppointment3.EarliestStartTime.addHours(7);
        ServiceAppointment3.SchedStartTime = Datetime.now().addHours(2);
        ServiceAppointment3.SchedEndTime = ServiceAppointment3.SchedStartTime.addHours(7);
        insert ServiceAppointment3;
        HOT_InterestedResource__c interestedResource = HOT_TestDataFactory.createInterestedResource(
            ServiceAppointment3.Id,
            resource1.Id
        );
        insert interestedResource;

        List<ServiceAppointment> result = HOT_InterestedResourceBannerController.checkForOverlap(interestedResource.Id);
        System.assertEquals(2, result.size(), 'Er 2 oppdrag som skal vises som overlappende');
        Test.stopTest();
    }
}
