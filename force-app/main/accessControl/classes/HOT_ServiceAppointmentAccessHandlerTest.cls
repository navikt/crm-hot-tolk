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
    private static void testChangingFromTransferredToAcceptedGrantsEditAccess() {
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
                WHERE
                    UserOrGroupId = :tjenesteleverandorGroup.Id
                    AND ParentId = :serviceAppointment.Id
                    AND AccessLevel = 'Edit'
                    AND RowCause = 'Manual'
            ],
            'Accepted appointments should grant edit access to the tjenesteleverandor group'
        );
    }

    @IsTest
    private static void testTransferredRestoresReadAccess() {
        Group tjenesteleverandorGroup = getTjenesteleverandorGroup();
        ServiceAppointment serviceAppointment = createServiceAppointment();
        serviceAppointment.HOT_TjenesteleverandorStatus__c = 'Accepted';
        update serviceAppointment;

        System.Test.startTest();
        serviceAppointment.HOT_TjenesteleverandorStatus__c = 'Transferred';
        update serviceAppointment;
        System.Test.stopTest();

        List<ServiceAppointmentShare> shares = [
            SELECT AccessLevel
            FROM ServiceAppointmentShare
            WHERE
                UserOrGroupId = :tjenesteleverandorGroup.Id
                AND ParentId = :serviceAppointment.Id
                AND RowCause = 'Manual'
        ];
        System.assertEquals(1, shares.size(), 'The group should retain one share');
        System.assertEquals('Read', shares[0].AccessLevel, 'Transferred appointments must not retain edit access');
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

    @IsTest
    private static void testRepairAcceptedShare() {
        Group tjenesteleverandorGroup = getTjenesteleverandorGroup();
        ServiceAppointment appointment = createServiceAppointment();
        appointment.HOT_TjenesteleverandorStatus__c = 'Accepted';
        update appointment;
        ServiceAppointmentShare existingShare = [
            SELECT Id, AccessLevel
            FROM ServiceAppointmentShare
            WHERE ParentId = :appointment.Id AND UserOrGroupId = :tjenesteleverandorGroup.Id AND RowCause = 'Manual'
        ];
        existingShare.AccessLevel = 'Read';
        update existingShare;

        System.Test.startTest();
        HOT_ServiceAppointmentsSharingService.grantAccessToTjenesteleverandorGroup(new Set<Id>{ appointment.Id });
        HOT_ServiceAppointmentsSharingService.grantAccessToTjenesteleverandorGroup(new Set<Id>{ appointment.Id });
        System.Test.stopTest();

        List<ServiceAppointmentShare> shares = [
            SELECT Id, AccessLevel
            FROM ServiceAppointmentShare
            WHERE ParentId = :appointment.Id AND UserOrGroupId = :tjenesteleverandorGroup.Id AND RowCause = 'Manual'
        ];
        System.assertEquals(1, shares.size(), 'Repairing access must not create duplicate shares');
        System.assertEquals(existingShare.Id, shares[0].Id, 'The existing share should be upgraded');
        System.assertEquals('Edit', shares[0].AccessLevel, 'Accepted appointments require edit access');
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
