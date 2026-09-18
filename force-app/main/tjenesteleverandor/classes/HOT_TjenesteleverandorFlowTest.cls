@IsTest
private class HOT_TjenesteleverandorFlowTest {
    @IsTest
    static void transferredSetsTransferDateAndDeadline() {
        ServiceAppointment serviceAppointment = createServiceAppointment();
        serviceAppointment.Status = 'Released to Freelance';

        Test.startTest();
        insert serviceAppointment;
        Test.stopTest();

        ServiceAppointment actual = getServiceAppointment(serviceAppointment.Id);
        System.assertEquals('Transferred', actual.HOT_TjenesteleverandorStatus__c);
        System.assertNotEquals(null, actual.HOT_TjenesteleverandorTransferDate__c);
        System.assertNotEquals(null, actual.HOT_TjenesteleverandorDeadline__c);
        System.assert(actual.HOT_TjenesteleverandorDeadline__c > actual.HOT_TjenesteleverandorTransferDate__c);
    }

    @IsTest
    static void acceptedSetsAcceptanceDateAndClearsDeadline() {
        ServiceAppointment serviceAppointment = createServiceAppointment();
        serviceAppointment.Status = 'Released to Freelance';
        insert serviceAppointment;

        System.assertNotEquals(null, getServiceAppointment(serviceAppointment.Id).HOT_TjenesteleverandorDeadline__c);

        Test.startTest();
        update new ServiceAppointment(Id = serviceAppointment.Id, HOT_TjenesteleverandorStatus__c = 'Accepted');
        Test.stopTest();

        ServiceAppointment actual = getServiceAppointment(serviceAppointment.Id);
        System.assertNotEquals(null, actual.HOT_TjenesteleverandorAcceptDate__c);
        System.assertEquals(null, actual.HOT_TjenesteleverandorDeadline__c);
        System.assertEquals('Accepted', actual.HOT_TjenesteleverandorStatus__c);
    }

    @IsTest
    static void massDeclineOpensAndRetractsAppointments() {
        Group queue = createOwnerQueueAndFormidlerGroup('999010');
        List<ServiceAppointment> serviceAppointments = createServiceAppointments(10);

        for (ServiceAppointment serviceAppointment : serviceAppointments) {
            serviceAppointment.OwnerId = queue.Id;
            serviceAppointment.Status = 'Released to Freelance';
        }
        insert serviceAppointments;

        Test.startTest();
        List<ServiceAppointment> declinedAppointments = new List<ServiceAppointment>();
        for (ServiceAppointment serviceAppointment : serviceAppointments) {
            declinedAppointments.add(
                new ServiceAppointment(Id = serviceAppointment.Id, HOT_TjenesteleverandorStatus__c = 'Declined')
            );
        }
        update declinedAppointments;
        Test.stopTest();

        Set<Id> serviceAppointmentIds = new Map<Id, ServiceAppointment>(serviceAppointments).keySet();
        for (ServiceAppointment actual : [
            SELECT
                Status,
                HOT_IsReleasedToFreelance__c,
                HOT_TjenesteleverandorStatus__c,
                HOT_TjenesteleverandorDeadline__c
            FROM ServiceAppointment
            WHERE Id IN :serviceAppointmentIds
        ]) {
            System.assertEquals('None', actual.Status);
            System.assertEquals(false, actual.HOT_IsReleasedToFreelance__c);
            System.assertEquals('Declined', actual.HOT_TjenesteleverandorStatus__c);
            System.assertEquals(null, actual.HOT_TjenesteleverandorDeadline__c);
        }
    }

    @IsTest
    static void declinedAppointmentIsNotTransferredAgain() {
        Group queue = createOwnerQueueAndFormidlerGroup('999011');
        ServiceAppointment serviceAppointment = createServiceAppointment();
        serviceAppointment.OwnerId = queue.Id;
        serviceAppointment.Status = 'Released to Freelance';
        insert serviceAppointment;

        Test.startTest();
        update new ServiceAppointment(Id = serviceAppointment.Id, HOT_TjenesteleverandorStatus__c = 'Declined');

        ServiceAppointment declinedAppointment = getServiceAppointment(serviceAppointment.Id);
        System.assertEquals('None', declinedAppointment.Status);
        System.assertEquals(false, declinedAppointment.HOT_IsReleasedToFreelance__c);

        declinedAppointment.Status = 'Released to Freelance';
        update declinedAppointment;
        Test.stopTest();

        ServiceAppointment actual = getServiceAppointment(serviceAppointment.Id);
        System.assertEquals('Released to Freelance', actual.Status);
        System.assertEquals(true, actual.HOT_IsReleasedToFreelance__c);
        System.assertEquals('Declined', actual.HOT_TjenesteleverandorStatus__c);
        System.assertEquals(null, actual.HOT_TjenesteleverandorDeadline__c);
    }

    private static ServiceAppointment getServiceAppointment(Id serviceAppointmentId) {
        return [
            SELECT
                Status,
                HOT_IsReleasedToFreelance__c,
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
        return createServiceAppointments(1)[0];
    }

    private static List<ServiceAppointment> createServiceAppointments(Integer count) {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('supplier flow', workType);
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder;
        WorkOrderLineItem workOrderLineItem = HOT_TestDataFactory.createWorkOrderLineItem(workOrder, workType);
        insert workOrderLineItem;

        List<ServiceAppointment> serviceAppointments = new List<ServiceAppointment>();
        for (Integer index = 0; index < count; index++) {
            serviceAppointments.add(HOT_TestDataFactory.createServiceAppointment(workOrderLineItem));
        }
        return serviceAppointments;
    }
}
