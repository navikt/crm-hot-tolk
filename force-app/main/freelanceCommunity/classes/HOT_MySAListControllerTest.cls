@IsTest
private class HOT_MySAListControllerTest {
    @testSetup
    static void setup() {
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
    }
    @IsTest
    static void getMyServiceAppointmentsTest() {
        List<ServiceAppointment> myServiceAppointment = [SELECT Id, Status FROM ServiceAppointment];
        System.assertEquals(1, myServiceAppointment.size(), 'Could not fetch my ServiceAppointment ');

        for (ServiceAppointment sa : myServiceAppointment) {
            sa.Status = 'Dispatched';
        }
        update myServiceAppointment;

        Test.startTest();
        myServiceAppointment = HOT_MyServiceAppointmentListController.getMyServiceAppointments();

        System.assertEquals(
            1,
            myServiceAppointment.size(),
            'Could not fetch my ServiceAppointment with status "Dispatched"'
        );

        for (ServiceAppointment sa : myServiceAppointment) {
            sa.Status = 'Completed';
        }
        update myServiceAppointment;

        myServiceAppointment = HOT_MyServiceAppointmentListController.getMyServiceAppointments();

        System.assertEquals(
            1,
            myServiceAppointment.size(),
            'Could not fetch my ServiceAppointment with status "Completed"'
        );

        for (ServiceAppointment sa : myServiceAppointment) {
            sa.Status = 'Canceled';
        }
        update myServiceAppointment;

        myServiceAppointment = HOT_MyServiceAppointmentListController.getMyServiceAppointments();

        System.assertEquals(
            0,
            myServiceAppointment.size(),
            'Could not fetch my ServiceAppointment with status "Cancelled"'
        );

        for (ServiceAppointment sa : myServiceAppointment) {
            sa.Status = 'Cannot Complete';
        }
        update myServiceAppointment;

        myServiceAppointment = HOT_MyServiceAppointmentListController.getMyServiceAppointments();

        Test.stopTest();

        System.assertEquals(
            0,
            myServiceAppointment.size(),
            'Could not fetch my ServiceAppointment with status "Cannot Completed"'
        );
    }
    @IsTest
    static void getParentWorkOrderLineItemsTest() {
        Test.startTest();
        List<WorkOrderLineItem> workOrderLineItem = HOT_MyServiceAppointmentListController.getParentWorkOrderLineItems();
        Test.stopTest();
        System.assertEquals(1, workOrderLineItem.size(), 'Could not fetch parent WorkOrderLineItems');
    }

    @IsTest
    static void getMyServiceAppointmentsTestOldSA() {
        WorkType workType = [SELECT Id FROM WorkType LIMIT 1];
        HOT_Request__c request = HOT_TestDataFactory.createRequest('HOT_MySAListControllerTestnewSA', workType);
        insert request;
        request.StartTime__c = System.today() + 24;
        request.EndTime__c = System.today() + 25;
        request.Status__c = 'Godkjent';
        update request;

        HOT_Request__c request2 = HOT_TestDataFactory.createRequest('HOT_MySAListControllerTestOldSA', workType);
        insert request2;
        request2.StartTime__c = System.today() - (365 * 3 + 8);
        request2.EndTime__c = System.today() - (365 * 3 + 7);
        request2.Status__c = 'Godkjent';
        update request2;

        Test.startTest();
        List<ServiceAppointment> allSAs = [
            SELECT Id, Status, HOT_DelPol_ToHideRecord__c, SchedEndTime
            FROM ServiceAppointment
        ];

        for (ServiceAppointment sa : allSAs) {
            sa.Status = 'Dispatched';
        }

        update allSAs;

        List<ServiceAppointment> myServiceAppointmentsafter = HOT_MyServiceAppointmentListController.getMyServiceAppointments();
        Test.stopTest();

        System.assertEquals(
            1,
            myServiceAppointmentsafter.size(),
            'Expected one service appointment after inserting another with a date older than 3 years.'
        );
    }
    @IsTest
    static void getServiceAppointmentTest() {
        ServiceAppointment serviceAppointment = [SELECT Id FROM ServiceAppointment LIMIT 1];
        ServiceAppointment saResult = HOT_MyServiceAppointmentListController.getServiceAppointment(
            serviceAppointment.Id
        );
        System.assertEquals('None', saResult.Status, 'Did not get expected status.');
    }
    @IsTest
    static void checkAccessToSA() {
        ServiceAppointment serviceAppointment = [SELECT Id FROM ServiceAppointment];
        Boolean access = HOT_MyServiceAppointmentListController.checkAccessToSA(serviceAppointment.Id);
        System.assertEquals(true, access, 'Should have access to this sa');
    }
    @IsTest
    static void getOwnerName() {
        ServiceAppointment serviceAppointment = [SELECT Id FROM ServiceAppointment];
        String owner = HOT_MyServiceAppointmentListController.getOwnerName(serviceAppointment.Id);
        System.assertEquals('HoT Tolk Admin', owner, 'Could not get owner name');
    }
    @IsTest
    static void getServiceAppointmentDetailsTest() {
        ServiceAppointment serviceAppointment = [SELECT Id FROM ServiceAppointment LIMIT 1];
        User admin = [SELECT Id, UserRoleId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

        ServiceResource serviceResource = [SELECT Id FROM ServiceResource WHERE RelatedRecordId = :admin.Id];

        HOT_InterestedResource__c ir = HOT_TestDataFactory.createInterestedResource(
            serviceAppointment.Id,
            serviceResource.Id
        );
        ir.Status__c = 'Interested';
        insert ir;
        ServiceAppointment saResult = HOT_MyServiceAppointmentListController.getServiceAppointmentDetails(
            serviceAppointment.Id
        );
        System.assertEquals('None', saResult.Status, 'Did not get expected status.');
    }
    @IsTest
    static void getThreadFreelanceIdTest() {
        ServiceAppointment serviceAppointment = [
            SELECT Id, HOT_WorkOrderLineItem__r.WorkOrder.Id
            FROM ServiceAppointment
            LIMIT 1
        ];

        Thread__c t = new Thread__c();
        t.CRM_Related_Object__c = serviceAppointment.HOT_WorkOrderLineItem__r.WorkOrder.Id;
        t.CRM_Thread_Type__c = 'HOT_BRUKER-TOLK';
        insert t;

        String threadFreelanceId = HOT_MyServiceAppointmentListController.getThreadFreelanceId(serviceAppointment.Id);
        System.assertEquals(t.Id, threadFreelanceId, 'Did not get the expected thread');
    }
    @IsTest
    static void getThreadFreelanceIdNoThreadTest() {
        ServiceAppointment serviceAppointment = [SELECT Id FROM ServiceAppointment LIMIT 1];

        String threadFreelanceId = HOT_MyServiceAppointmentListController.getThreadFreelanceId(serviceAppointment.Id);
        System.assertEquals('', threadFreelanceId, 'Was supposed to be blank');
    }
    @IsTest
    static void getThreadServiceAppointmentIdTest() {
        ServiceAppointment serviceAppointment = [SELECT Id FROM ServiceAppointment LIMIT 1];

        Thread__c t = new Thread__c();
        t.CRM_Related_Object__c = serviceAppointment.Id;
        insert t;

        String threadSAId = HOT_MyServiceAppointmentListController.getThreadServiceAppointmentId(serviceAppointment.Id);
        System.assertEquals('', threadSAId, 'Did not get the expected thread');
    }
    @IsTest
    static void getThreadServiceAppointmentIdNoThreadTest() {
        ServiceAppointment serviceAppointment = [SELECT Id FROM ServiceAppointment LIMIT 1];

        String threadSAId = HOT_MyServiceAppointmentListController.getThreadServiceAppointmentId(serviceAppointment.Id);
        System.assertEquals('', threadSAId, 'Was supposed to be null');
    }
    @IsTest
    static void getThreadInterpretersIdTest() {
        ServiceAppointment serviceAppointment = [
            SELECT Id, HOT_WorkOrderLineItem__r.WorkOrder.Id
            FROM ServiceAppointment
            LIMIT 1
        ];

        Thread__c t = new Thread__c();
        t.CRM_Related_Object__c = serviceAppointment.HOT_WorkOrderLineItem__r.WorkOrder.Id;
        t.CRM_Thread_Type__c = 'HOT_TOLK-TOLK';
        insert t;

        String threadInterpretersId = HOT_MyServiceAppointmentListController.getThreadInterpretersId(
            serviceAppointment.Id
        );
        System.assertEquals(t.Id, threadInterpretersId, 'Did not get the expected thread');
    }
}
