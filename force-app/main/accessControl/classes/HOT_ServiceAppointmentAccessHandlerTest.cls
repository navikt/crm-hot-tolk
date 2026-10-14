@IsTest
private class HOT_ServiceAppointmentAccessHandlerTest {
    @IsTest
    private static void testTransferredStatusSharesServiceAppointmentWithTjenesteleverandorGroup() {
        Group tjenesteleverandorGroup = getTjenesteleverandorGroup();
        ServiceAppointment serviceAppointment = createServiceAppointment();

        Test.startTest();
        serviceAppointment.HOT_TjenesteleverandorStatus__c = 'Transferred';
        update serviceAppointment;
        Test.stopTest();

        System.assertEquals(
            1,
            [
                SELECT COUNT()
                FROM ServiceAppointmentShare
                WHERE
                    UserOrGroupId = :tjenesteleverandorGroup.Id
                    AND ParentId = :serviceAppointment.Id
                    AND AccessLevel = 'Read'
                    AND RowCause = 'Manual'
            ],
            'Service Appointment should be shared with tjenesteleverandor group'
        );
    }

    @IsTest
    private static void testChangingFromTransferredToAcceptedKeepsTjenesteleverandorGroupShare() {
        Group tjenesteleverandorGroup = getTjenesteleverandorGroup();
        ServiceAppointment serviceAppointment = createServiceAppointment();

        serviceAppointment.HOT_TjenesteleverandorStatus__c = 'Transferred';
        update serviceAppointment;

        Test.startTest();
        serviceAppointment.HOT_TjenesteleverandorStatus__c = 'Accepted';
        update serviceAppointment;
        Test.stopTest();

        System.assertEquals(
            1,
            [
                SELECT COUNT()
                FROM ServiceAppointmentShare
                WHERE UserOrGroupId = :tjenesteleverandorGroup.Id AND ParentId = :serviceAppointment.Id
            ],
            'Tjenesteleverandor group share should be kept when status is accepted'
        );
    }

    @IsTest
    private static void testChangingFromAcceptedToDeclinedRemovesTjenesteleverandorGroupShare() {
        Group tjenesteleverandorGroup = getTjenesteleverandorGroup();
        ServiceAppointment serviceAppointment = createServiceAppointment();

        serviceAppointment.HOT_TjenesteleverandorStatus__c = 'Accepted';
        update serviceAppointment;

        Test.startTest();
        serviceAppointment.HOT_TjenesteleverandorStatus__c = 'Declined';
        update serviceAppointment;
        Test.stopTest();

        System.assertEquals(
            0,
            [
                SELECT COUNT()
                FROM ServiceAppointmentShare
                WHERE UserOrGroupId = :tjenesteleverandorGroup.Id AND ParentId = :serviceAppointment.Id
            ],
            'Tjenesteleverandor group share should be removed when status is no longer transferred or accepted'
        );
    }

    private static Group getTjenesteleverandorGroup() {
        List<Group> groups = [
            SELECT Id
            FROM Group
            WHERE DeveloperName = 'HOT_Tolk_Tjenesteleverandor' AND Type = 'Regular'
            LIMIT 1
        ];
        System.assertEquals(1, groups.size(), 'Tjenesteleverandor group metadata must be deployed');
        return groups[0];
    }

    private static ServiceAppointment createServiceAppointment() {
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
        return serviceAppointment;
    }
}
