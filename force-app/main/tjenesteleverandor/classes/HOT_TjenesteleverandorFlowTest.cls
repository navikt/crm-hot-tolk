@IsTest
private class HOT_TjenesteleverandorFlowTest {
    @IsTest
    static void transferredSetsTransferDateAndDeadline() {
        ServiceAppointment serviceAppointment = createServiceAppointment();
        insert serviceAppointment;

        Test.startTest();
        serviceAppointment.HOT_TjenesteleverandorStatus__c = 'Transferred';
        update serviceAppointment;
        Test.stopTest();

        ServiceAppointment actual = getServiceAppointment(serviceAppointment.Id);
        System.assertNotEquals(null, actual.HOT_TjenesteleverandorTransferDate__c);
        System.assertNotEquals(null, actual.HOT_TjenesteleverandorDeadline__c);
        System.assert(actual.HOT_TjenesteleverandorDeadline__c > actual.HOT_TjenesteleverandorTransferDate__c);
    }

    @IsTest
    static void acceptedSetsAcceptanceDateAndClearsDeadline() {
        ServiceAppointment serviceAppointment = createServiceAppointment();
        insert serviceAppointment;

        serviceAppointment.HOT_TjenesteleverandorStatus__c = 'Transferred';
        update serviceAppointment;
        System.assertNotEquals(null, getServiceAppointment(serviceAppointment.Id).HOT_TjenesteleverandorDeadline__c);

        Test.startTest();
        serviceAppointment.HOT_TjenesteleverandorStatus__c = 'Accepted';
        update serviceAppointment;
        Test.stopTest();

        ServiceAppointment actual = getServiceAppointment(serviceAppointment.Id);
        System.assertNotEquals(null, actual.HOT_TjenesteleverandorAcceptDate__c);
        System.assertEquals(null, actual.HOT_TjenesteleverandorDeadline__c);
        System.assertEquals('Accepted', actual.HOT_TjenesteleverandorStatus__c);
    }

    @IsTest
    static void massDeclineOpensAppointmentsAndClearsDeadlines() {
        Group queue = createOwnerQueueAndFormidlerGroup('999010');
        List<ServiceAppointment> serviceAppointments = new List<ServiceAppointment>();

        for (Integer index = 0; index < 10; index++) {
            ServiceAppointment serviceAppointment = createServiceAppointment();
            serviceAppointment.OwnerId = queue.Id;
            serviceAppointments.add(serviceAppointment);
        }
        insert serviceAppointments;

        for (ServiceAppointment serviceAppointment : serviceAppointments) {
            serviceAppointment.HOT_TjenesteleverandorStatus__c = 'Transferred';
        }
        update serviceAppointments;

        Test.startTest();
        for (ServiceAppointment serviceAppointment : serviceAppointments) {
            serviceAppointment.HOT_TjenesteleverandorStatus__c = 'Declined';
        }
        update serviceAppointments;
        Test.stopTest();

        Set<Id> serviceAppointmentIds = new Map<Id, ServiceAppointment>(serviceAppointments).keySet();
        for (ServiceAppointment actual : [
            SELECT Status, HOT_TjenesteleverandorStatus__c, HOT_TjenesteleverandorDeadline__c
            FROM ServiceAppointment
            WHERE Id IN :serviceAppointmentIds
        ]) {
            System.assertEquals('None', actual.Status);
            System.assertEquals('Declined', actual.HOT_TjenesteleverandorStatus__c);
            System.assertEquals(null, actual.HOT_TjenesteleverandorDeadline__c);
        }
    }

    private static ServiceAppointment getServiceAppointment(Id serviceAppointmentId) {
        return [
            SELECT
                Status,
                HOT_TjenesteleverandorStatus__c,
                HOT_TjenesteleverandorTransferDate__c,
                HOT_TjenesteleverandorAcceptDate__c,
                HOT_TjenesteleverandorDeadline__c
            FROM ServiceAppointment
            WHERE Id = :serviceAppointmentId
        ];
    }

    private static Group createOwnerQueueAndFormidlerGroup(String region) {
        Group formidlerGroup = new Group(
            Name = 'HOT group ' + region + ' formidler',
            DeveloperName = 'HOT_group_' + region + '_formidler',
            Type = 'Regular'
        );
        Group queue = new Group(Name = 'Queue ' + region, DeveloperName = 'queue_' + region, Type = 'Queue');
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert new List<Group>{ formidlerGroup, queue };
            insert new QueueSobject(QueueID = queue.Id, SobjectType = 'ServiceAppointment');
        }
        return queue;
    }

    private static ServiceAppointment createServiceAppointment() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('supplier flow', workType);
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder;
        WorkOrderLineItem workOrderLineItem = HOT_TestDataFactory.createWorkOrderLineItem(workOrder, workType);
        insert workOrderLineItem;
        return HOT_TestDataFactory.createServiceAppointment(workOrderLineItem);
    }
}
