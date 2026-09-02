@IsTest
private class HOT_MobileThreadListcontrollerTest {
    @TestSetup
    static void setup() {
        User admin = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

        OperatingHours operatingHours = HOT_TestDataFactory.createOperatingHours();
        insert operatingHours;
        ServiceTerritory serviceTerritory = HOT_TestDataFactory.createServiceTerritory(operatingHours);
        insert serviceTerritory;

        ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(admin.Id);
        insert serviceResource;

        ServiceTerritoryMember serviceTerritoryMember = HOT_TestDataFactory.createServiceTerritoryMember(
            serviceResource,
            serviceTerritory
        );
        insert serviceTerritoryMember;
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder;
        WorkOrderLineItem woli = HOT_TestDataFactory.createWorkOrderLineItem(workOrder, workType);
        insert woli;
        ServiceAppointment sa = HOT_TestDataFactory.createServiceAppointment(woli);
        sa.Subject = 'TEST';
        insert sa;

        HOT_InterestedResource__c ir = HOT_TestDataFactory.createInterestedResource(sa.Id, serviceResource.Id);

        insert ir;

        AssignedResource ar = HOT_TestDataFactory.createAssignedResource(sa.Id, serviceResource.Id);
        insert ar;
        ir.Status__c = 'Assigned';
        update ir;

        Thread__c t = new Thread__c();
        t.RecordTypeId = HOT_MessageHelper.getHOTThreadRecordType();
        t.CRM_Related_Object__c = workOrder.Id;
        t.HOT_IsEmployeeThread__c = true;
        insert t;
        Message__c message = new Message__c();
        message.CRM_Thread__c = t.Id;
        message.CRM_Message_Text__c = 'Dette er en testmelding';
        insert message;
    }

    @IsTest
    public static void getThreads() {
        List<Thread__c> threadList = HOT_MobileThreadListcontroller.getThreads();
        System.assertEquals(1, threadList.size(), 'Could not get my threads'); // Can't get current running user in test
    }
}
