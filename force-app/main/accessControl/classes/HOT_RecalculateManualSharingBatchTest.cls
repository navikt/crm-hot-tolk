@IsTest
private class HOT_RecalculateManualSharingBatchTest {
    @TestSetup
    static void setup() {
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' OR Name = 'Standardbruker' LIMIT 1];
        User user = HOT_TestDataFactory.createUser('user', profile);
        insert user;
        ServiceResource resource = HOT_TestDataFactory.createServiceResource(user.Id);
        insert resource;
    }

    @IsTest
    static void batchableTest() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder;
        WorkOrderLineItem workOrderLineItem = HOT_TestDataFactory.createWorkOrderLineItem(workOrder, workType);
        insert workOrderLineItem;
        ServiceAppointment serviceAppointment = HOT_TestDataFactory.createServiceAppointment(workOrderLineItem);
        serviceAppointment.HOT_Request__c = request.Id;
        insert serviceAppointment;

        List<ServiceResource> serviceResources = [SELECT Id, RelatedRecordId FROM ServiceResource];

        AssignedResource assignedResource = new AssignedResource(
            ServiceAppointmentId = serviceAppointment.Id,
            ServiceResourceId = serviceResources[0].Id
        );
        insert assignedResource;

        serviceAppointment = [
            SELECT Id, HOT_IsRecalculateManualSharing__c, HOT_ServiceResource__c, HOT_ServiceResource__r.RelatedRecordId
            FROM ServiceAppointment
            WHERE Id = :serviceAppointment.Id
        ];
        serviceAppointment.HOT_IsRecalculateManualSharing__c = true;
        serviceAppointment.HOT_ServiceResource__c = null;
        update serviceAppointment;

        HOT_RecalculateManualSharingBatch instance = new HOT_RecalculateManualSharingBatch();
        Test.startTest();
        database.executebatch(instance);
        Test.stopTest();
    }

    @IsTest
    static void schedulableTest() {
        String cron_exp = '0 0 0 3 9 ? 2024';
        Test.startTest();
        String jobId = System.schedule(
            'HOT_RecalculateManualSharingBatch',
            cron_exp,
            new HOT_RecalculateManualSharingBatch()
        );
        Test.stopTest();
        System.assert(jobId != null);
    }
}
