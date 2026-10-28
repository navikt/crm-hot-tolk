@IsTest
private class HOT_SPTransferSADispatcherTest {
    @TestSetup
    static void setup() {
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User dispatcher = HOT_TestDataFactory.createUser('tlswap', profile);
        dispatcher.Username = 'tlswap-' + UserInfo.getOrganizationId() + '@test.nav.no';
        myTriggers.disable(UserPermissionSetAssignmentHandler.class);
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert dispatcher;
        }
        ServiceResource resource = HOT_TestDataFactory.createServiceResource(dispatcher.Id);
        resource.HOT_IsTjenesteleverandorDispatcher__c = true;
        resource.CRM_Domain__c = 'HOT';
        myTriggers.disable(HOT_ServiceResourceAccessHandler.class);
        insert resource;

        WorkType workType = HOT_TestDataFactory.createWorkType('dispatcher transfer');
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('dispatcher transfer', workType);
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder;
        WorkOrderLineItem lineItem = HOT_TestDataFactory.createWorkOrderLineItem(workOrder, workType);
        insert lineItem;
        List<ServiceAppointment> appointments = new List<ServiceAppointment>();
        for (Integer index = 0; index < 3; index++) {
            ServiceAppointment appointment = HOT_TestDataFactory.createServiceAppointment(lineItem);
            appointment.EarliestStartTime = Datetime.now().addDays(7);
            appointment.DueDate = appointment.EarliestStartTime.addHours(2);
            appointments.add(appointment);
        }
        insert appointments;
        for (ServiceAppointment appointment : appointments) {
            appointment.Status = 'None';
            appointment.HOT_IsReleasedToTjenesteleverandor__c = true;
            appointment.HOT_TjenesteleverandorStatus__c = 'Transferred';
        }
        update appointments;
        List<ServiceAppointment> acceptances = new List<ServiceAppointment>();
        for (ServiceAppointment appointment : appointments) {
            acceptances.add(new ServiceAppointment(Id = appointment.Id, HOT_TjenesteleverandorStatus__c = 'Accepted'));
        }
        update acceptances;
        List<ServiceAppointment> releases = new List<ServiceAppointment>();
        for (ServiceAppointment appointment : appointments) {
            releases.add(new ServiceAppointment(Id = appointment.Id, HOT_IsReleasedToTjenesteleverandor__c = true));
        }
        update releases;
    }

    private static HOT_ServiceProviderTransferSADispatcher.Request request(List<Id> ids) {
        HOT_ServiceProviderTransferSADispatcher.Request input = new HOT_ServiceProviderTransferSADispatcher.Request();
        input.recordIds = ids;
        input.dispatcherId = [
            SELECT RelatedRecordId
            FROM ServiceResource
            WHERE HOT_IsTjenesteleverandorDispatcher__c = TRUE
            LIMIT 1
        ]
        .RelatedRecordId;
        return input;
    }

    @IsTest
    static void transfersOnlySelectedAppointments() {
        prepareAppointments();
        List<ServiceAppointment> appointments = [SELECT Id, HOT_TLDispatcher__c FROM ServiceAppointment ORDER BY Id];
        for (ServiceAppointment appointment : [
            SELECT Status, HOT_IsReleasedToTjenesteleverandor__c, HOT_TjenesteleverandorStatus__c
            FROM ServiceAppointment
        ]) {
            Assert.areEqual('None', appointment.Status);
            Assert.isTrue(appointment.HOT_IsReleasedToTjenesteleverandor__c);
            Assert.areEqual('Accepted', appointment.HOT_TjenesteleverandorStatus__c);
        }
        HOT_ServiceProviderTransferSADispatcher.Request input = request(
            new List<Id>{ appointments[0].Id, appointments[1].Id }
        );
        Test.startTest();
        HOT_ServiceProviderTransferSADispatcher.transfer(
            new List<HOT_ServiceProviderTransferSADispatcher.Request>{ input }
        );
        Test.stopTest();
        Map<Id, ServiceAppointment> actual = new Map<Id, ServiceAppointment>(
            [
                SELECT Id, HOT_TLDispatcher__c, Status, HOT_TjenesteleverandorStatus__c
                FROM ServiceAppointment
            ]
        );
        for (Id appointmentId : input.recordIds) {
            Assert.areEqual(input.dispatcherId, actual.get(appointmentId).HOT_TLDispatcher__c);
            Assert.areEqual('None', actual.get(appointmentId).Status);
            Assert.areEqual('Accepted', actual.get(appointmentId).HOT_TjenesteleverandorStatus__c);
        }
        Assert.areEqual(appointments[2].HOT_TLDispatcher__c, actual.get(appointments[2].Id).HOT_TLDispatcher__c);
    }

    @IsTest
    static void transfersToRunningUser() {
        prepareAppointments();
        myTriggers.disable(HOT_ServiceResourceAccessHandler.class);
        ServiceResource resource = HOT_TestDataFactory.createServiceResource(UserInfo.getUserId());
        resource.HOT_IsTjenesteleverandorDispatcher__c = true;
        resource.CRM_Domain__c = 'HOT';
        insert resource;
        List<ServiceAppointment> appointments = [SELECT Id, HOT_TLDispatcher__c FROM ServiceAppointment ORDER BY Id];
        HOT_ServiceProviderTransferSADispatcher.Request input = request(new List<Id>{ appointments[0].Id });
        input.dispatcherId = UserInfo.getUserId();
        Test.startTest();
        HOT_ServiceProviderTransferSADispatcher.transfer(
            new List<HOT_ServiceProviderTransferSADispatcher.Request>{ input }
        );
        Test.stopTest();
        Assert.areEqual(
            UserInfo.getUserId(),
            [SELECT HOT_TLDispatcher__c FROM ServiceAppointment WHERE Id = :appointments[0].Id].HOT_TLDispatcher__c
        );
        Assert.areEqual(
            appointments[1].HOT_TLDispatcher__c,
            [SELECT HOT_TLDispatcher__c FROM ServiceAppointment WHERE Id = :appointments[1].Id].HOT_TLDispatcher__c
        );
    }

    @IsTest
    static void rejectsInvalidSelectionsAndDispatcher() {
        ServiceAppointment appointment = [SELECT Id FROM ServiceAppointment LIMIT 1];
        Test.startTest();
        assertRejected(null);
        assertRejected(new List<HOT_ServiceProviderTransferSADispatcher.Request>());
        HOT_ServiceProviderTransferSADispatcher.Request input = request(new List<Id>{ appointment.Id });
        input.dispatcherId = UserInfo.getUserId();
        assertRejected(new List<HOT_ServiceProviderTransferSADispatcher.Request>{ input });
        input = request(new List<Id>{ appointment.Id, appointment.Id });
        assertRejected(new List<HOT_ServiceProviderTransferSADispatcher.Request>{ input });
        input = request(new List<Id>{ UserInfo.getUserId() });
        assertRejected(new List<HOT_ServiceProviderTransferSADispatcher.Request>{ input });
        Test.stopTest();
    }

    @IsTest
    static void rejectsIneligibleAppointmentWithoutPartialUpdate() {
        prepareAppointments();
        List<ServiceAppointment> appointments = [SELECT Id, HOT_TLDispatcher__c FROM ServiceAppointment ORDER BY Id];
        update new ServiceAppointment(Id = appointments[1].Id, HOT_IsReleasedToTjenesteleverandor__c = false);
        HOT_ServiceProviderTransferSADispatcher.Request input = request(
            new List<Id>{ appointments[0].Id, appointments[1].Id }
        );
        Test.startTest();
        assertRejected(new List<HOT_ServiceProviderTransferSADispatcher.Request>{ input });
        Test.stopTest();
        Assert.areEqual(
            appointments[0].HOT_TLDispatcher__c,
            [SELECT HOT_TLDispatcher__c FROM ServiceAppointment WHERE Id = :appointments[0].Id].HOT_TLDispatcher__c
        );
    }

    @IsTest
    static void rejectsInvalidDispatcherResource() {
        ServiceResource resource = [
            SELECT Id
            FROM ServiceResource
            WHERE HOT_IsTjenesteleverandorDispatcher__c = TRUE
            LIMIT 1
        ];
        HOT_ServiceProviderTransferSADispatcher.Request input = request(
            new List<Id>{ [SELECT Id FROM ServiceAppointment LIMIT 1].Id }
        );
        update new ServiceResource(Id = resource.Id, HOT_IsTjenesteleverandorDispatcher__c = false);
        Test.startTest();
        assertRejected(new List<HOT_ServiceProviderTransferSADispatcher.Request>{ input });
        Test.stopTest();
    }

    private static void assertRejected(List<HOT_ServiceProviderTransferSADispatcher.Request> requests) {
        try {
            HOT_ServiceProviderTransferSADispatcher.transfer(requests);
            Assert.fail('Invalid transfer must fail');
        } catch (HOT_ServiceProviderTransferSADispatcher.TransferException expected) {
            Assert.isNotNull(expected.getMessage());
        }
    }

    private static void prepareAppointments() {
        List<ServiceAppointment> appointments = [SELECT Id FROM ServiceAppointment];
        for (ServiceAppointment appointment : appointments) {
            appointment.HOT_IsReleasedToTjenesteleverandor__c = true;
        }
        update appointments;
        List<ServiceAppointment> acceptances = new List<ServiceAppointment>();
        for (ServiceAppointment appointment : appointments) {
            acceptances.add(new ServiceAppointment(Id = appointment.Id, HOT_TjenesteleverandorStatus__c = 'Accepted'));
        }
        update acceptances;
    }
}
