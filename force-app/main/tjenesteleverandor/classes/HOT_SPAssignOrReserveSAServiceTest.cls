@IsTest
private class HOT_SPAssignOrReserveSAServiceTest {
    @TestSetup
    static void setup() {
        Type stubType = Type.forName('FSL_TestStub');
        if (stubType != null) {
            Callable stub = (Callable) stubType.newInstance();
            Map<String, Set<String>> transitions = new Map<String, Set<String>>{
                'None' => new Set<String>{ 'Scheduled', 'Dispatched', 'Released to Freelance', 'Cannot Complete' },
                'Scheduled' => new Set<String>{ 'Dispatched', 'None' },
                'Dispatched' => new Set<String>{ 'None' },
                'Released to Freelance' => new Set<String>{ 'None', 'Scheduled', 'Dispatched' },
                'Cannot Complete' => new Set<String>{ 'None' }
            };
            for (String fromStatus : transitions.keySet()) {
                for (String toStatus : transitions.get(fromStatus)) {
                    stub.call(
                        'addStatusTransition',
                        new Map<String, Object>{ 'fromStatus' => fromStatus, 'toStatus' => toStatus }
                    );
                }
            }
        }
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('SPAssignOrReserve', workType);
        insert request;
        request.Status__c = 'Godkjent';
        update request;

        OperatingHours operatingHours = HOT_TestDataFactory.createOperatingHours();
        insert operatingHours;
        ServiceTerritory serviceTerritory = HOT_TestDataFactory.createServiceTerritory(operatingHours);
        insert serviceTerritory;
        Profile profile = [
            SELECT Id
            FROM Profile
            WHERE Name = 'System Administrator' OR Name = 'Systemadministrator'
            LIMIT 1
        ];
        User secondUser = HOT_TestDataFactory.createUser('SecUser', profile);
        insert secondUser;

        ServiceResource firstResource = HOT_TestDataFactory.createServiceResource(UserInfo.getUserId());
        firstResource.HOT_IsFreelanceInterpreter__c = true;
        firstResource.HOT_IsEmployedInterpreter__c = false;
        firstResource.HOT_ServiceTerritory__c = serviceTerritory.Id;
        ServiceResource secondResource = HOT_TestDataFactory.createServiceResource(secondUser.Id);
        secondResource.Name = 'Another Resource';
        secondResource.HOT_IsFreelanceInterpreter__c = true;
        secondResource.HOT_IsEmployedInterpreter__c = false;
        secondResource.HOT_ServiceTerritory__c = serviceTerritory.Id;
        insert new List<ServiceResource>{ firstResource, secondResource };
        List<ServiceTerritoryMember> territoryMembers = new List<ServiceTerritoryMember>{
            HOT_TestDataFactory.createServiceTerritoryMember(firstResource, serviceTerritory),
            HOT_TestDataFactory.createServiceTerritoryMember(secondResource, serviceTerritory)
        };
        for (ServiceTerritoryMember member : territoryMembers) {
            member.EffectiveStartDate = Datetime.now().addDays(-1);
        }
        insert territoryMembers;

        ServiceAppointment appointment = getServiceAppointment();
        update new ServiceAppointment(
            Id = appointment.Id,
            ServiceTerritoryId = serviceTerritory.Id,
            HOT_IsEmployedInterpreter__c = false,
            HOT_IsReleasedToFreelance__c = false
        );
        insert new List<HOT_InterestedResource__c>{
            HOT_TestDataFactory.createInterestedResource(appointment.Id, firstResource.Id),
            HOT_TestDataFactory.createInterestedResource(appointment.Id, secondResource.Id)
        };
        createReleasedToFreelanceServiceAppointment();
    }

    @IsTest
    static void serviceProviderReservesFromNone() {
        assertServiceProviderAssignment(getServiceAppointment(), 'Scheduled');
    }

    @IsTest
    static void serviceProviderAssignsFromNone() {
        assertServiceProviderAssignment(getServiceAppointment(), 'Dispatched');
    }

    @IsTest
    static void serviceProviderReservesFromReleased() {
        assertServiceProviderAssignment(createReleasedToFreelanceServiceAppointment(), 'Scheduled');
    }

    @IsTest
    static void serviceProviderAssignsFromReleased() {
        assertServiceProviderAssignment(createReleasedToFreelanceServiceAppointment(), 'Dispatched');
    }

    @IsTest
    static void serviceProviderReservesFutureUncoveredAppointment() {
        ServiceAppointment appointment = getServiceAppointment();
        update new ServiceAppointment(Id = appointment.Id, Status = 'Cannot Complete');
        assertServiceProviderAssignment(appointment, 'Scheduled');
    }

    @IsTest
    static void serviceProviderAssignsFutureUncoveredAppointment() {
        ServiceAppointment appointment = getServiceAppointment();
        update new ServiceAppointment(Id = appointment.Id, Status = 'Cannot Complete');
        assertServiceProviderAssignment(appointment, 'Dispatched');
    }

    @IsTest
    static void serviceProviderRejectsPastScheduledEndTime() {
        assertEndTimeBlocksNewAssignment(Datetime.now().addSeconds(-1));
    }

    @IsTest
    static void serviceProviderRejectsScheduledEndTimeAtCurrentTime() {
        assertEndTimeBlocksNewAssignment(Datetime.now());
    }

    private static void assertEndTimeBlocksNewAssignment(Datetime endTime) {
        ServiceAppointment appointment = getServiceAppointment();
        ServiceResource resource = getServiceResources()[0];
        update new ServiceAppointment(
            Id = appointment.Id,
            SchedStartTime = endTime.addHours(-2),
            SchedEndTime = endTime,
            HOT_TjenesteleverandorStatus__c = 'Accepted'
        );
        Assert.isTrue(
            [SELECT DueDate FROM ServiceAppointment WHERE Id = :appointment.Id].DueDate > Datetime.now(),
            'The scheduled end time, not the ordered end time, must control eligibility'
        );

        Test.startTest();
        for (String targetStatus : new List<String>{ 'Scheduled', 'Dispatched' }) {
            HOT_SPAssignOrReserveSAService.Result result = HOT_SPAssignOrReserveSAService.assignOrReserve(
                new List<HOT_SPAssignOrReserveSAService.Input>{
                    createRequest(appointment.Id, resource.Id, targetStatus)
                }
            )[0];
            Assert.isFalse(result.success);
            Assert.areEqual(
                'Oppdragets sluttid er passert. Du kan ikke reservere eller tildele en tolk.',
                result.message
            );
        }
        Test.stopTest();

        Assert.areEqual('None', [SELECT Status FROM ServiceAppointment WHERE Id = :appointment.Id].Status);
        Assert.areEqual(0, [SELECT COUNT() FROM AssignedResource WHERE ServiceAppointmentId = :appointment.Id]);
    }

    @IsTest
    static void serviceProviderRejectsDispatchOfEndedReservation() {
        ServiceAppointment appointment = getServiceAppointment();
        ServiceResource resource = getServiceResources()[0];
        AssignedResource reservation = new AssignedResource(
            ServiceAppointmentId = appointment.Id,
            ServiceResourceId = resource.Id
        );
        insert reservation;
        update new ServiceAppointment(
            Id = appointment.Id,
            Status = 'Scheduled',
            SchedStartTime = Datetime.now().addHours(-2),
            SchedEndTime = Datetime.now().addSeconds(-1),
            HOT_TjenesteleverandorStatus__c = 'Accepted'
        );

        Test.startTest();
        HOT_SPAssignOrReserveSAService.Result result = HOT_SPAssignOrReserveSAService.assignOrReserve(
            new List<HOT_SPAssignOrReserveSAService.Input>{ createRequest(appointment.Id, resource.Id, 'Dispatched') }
        )[0];
        Test.stopTest();

        Assert.isFalse(result.success);
        Assert.areEqual('Oppdragets sluttid er passert. Du kan ikke reservere eller tildele en tolk.', result.message);
        Assert.areEqual('Scheduled', [SELECT Status FROM ServiceAppointment WHERE Id = :appointment.Id].Status);
        AssignedResource actual = [
            SELECT Id, ServiceResourceId
            FROM AssignedResource
            WHERE ServiceAppointmentId = :appointment.Id
        ];
        Assert.areEqual(reservation.Id, actual.Id);
        Assert.areEqual(resource.Id, actual.ServiceResourceId);
    }

    @IsTest
    static void removingReservedInterpreterPreservesProviderAcceptance() {
        assertRemovingInterpreterPreservesProviderAcceptance('Scheduled');
    }

    @IsTest
    static void removingAssignedInterpreterPreservesProviderAcceptance() {
        assertRemovingInterpreterPreservesProviderAcceptance('Dispatched');
    }

    private static void assertRemovingInterpreterPreservesProviderAcceptance(String targetStatus) {
        ServiceAppointment appointment = getServiceAppointment();
        AssignedResource assignment = new AssignedResource(
            ServiceAppointmentId = appointment.Id,
            ServiceResourceId = getServiceResources()[0].Id
        );
        insert assignment;
        update new ServiceAppointment(
            Id = appointment.Id,
            Status = targetStatus,
            HOT_IsReleasedToTjenesteleverandor__c = true,
            HOT_IsReleasedToFreelance__c = true,
            HOT_TjenesteleverandorStatus__c = 'Accepted',
            HOT_TjenesteleverandorTransferDate__c = System.now().addHours(-1)
        );
        ServiceAppointment beforeRemoval = [
            SELECT HOT_TjenesteleverandorTransferDate__c, HOT_TjenesteleverandorAcceptDate__c
            FROM ServiceAppointment
            WHERE Id = :appointment.Id
        ];

        Test.startTest();
        delete assignment;
        Test.stopTest();

        ServiceAppointment actual = [
            SELECT
                Status,
                HOT_TjenesteleverandorStatus__c,
                HOT_IsReleasedToTjenesteleverandor__c,
                HOT_TjenesteleverandorTransferDate__c,
                HOT_TjenesteleverandorAcceptDate__c,
                HOT_TjenesteleverandorDeadline__c,
                HOT_ServiceResource__c,
                HOT_AssignedResourceId__c
            FROM ServiceAppointment
            WHERE Id = :appointment.Id
        ];
        Assert.areEqual('None', actual.Status);
        Assert.areEqual('Accepted', actual.HOT_TjenesteleverandorStatus__c);
        Assert.isTrue(actual.HOT_IsReleasedToTjenesteleverandor__c);
        Assert.areEqual(
            beforeRemoval.HOT_TjenesteleverandorTransferDate__c,
            actual.HOT_TjenesteleverandorTransferDate__c
        );
        Assert.areEqual(beforeRemoval.HOT_TjenesteleverandorAcceptDate__c, actual.HOT_TjenesteleverandorAcceptDate__c);
        Assert.isNull(actual.HOT_TjenesteleverandorDeadline__c);
        Assert.isNull(actual.HOT_ServiceResource__c);
        Assert.isNull(actual.HOT_AssignedResourceId__c);
        Assert.areEqual(0, [SELECT COUNT() FROM AssignedResource WHERE ServiceAppointmentId = :appointment.Id]);
    }

    private static void assertServiceProviderAssignment(ServiceAppointment appointment, String targetStatus) {
        update new ServiceAppointment(Id = appointment.Id, HOT_TjenesteleverandorStatus__c = 'Accepted');
        ServiceResource resource = getServiceResources()[0];

        Test.startTest();
        HOT_SPAssignOrReserveSAService.Result result = HOT_SPAssignOrReserveSAService.assignOrReserve(
            new List<HOT_SPAssignOrReserveSAService.Input>{ createRequest(appointment.Id, resource.Id, targetStatus) }
        )[0];
        Test.stopTest();

        ServiceAppointment actual = [
            SELECT
                Status,
                HOT_TjenesteleverandorStatus__c,
                HOT_ServiceResource__c,
                HOT_AssignedResourceId__c,
                HOT_IsReleasedToFreelance__c
            FROM ServiceAppointment
            WHERE Id = :appointment.Id
        ];
        Assert.isTrue(result.success, result.message);
        Assert.areEqual(targetStatus, actual.Status);
        Assert.isTrue(actual.HOT_IsReleasedToFreelance__c, 'Reserving or assigning must release to freelance');
        Assert.areEqual('Accepted', actual.HOT_TjenesteleverandorStatus__c, 'Provider status must be preserved');
        Assert.areEqual(resource.Id, actual.HOT_ServiceResource__c);
        Assert.areEqual(resource.RelatedRecordId, actual.HOT_AssignedResourceId__c);
        Assert.areEqual(1, [SELECT COUNT() FROM AssignedResource WHERE ServiceAppointmentId = :appointment.Id]);
    }

    @IsTest
    static void serviceProviderRejectsUnacceptedAppointment() {
        ServiceAppointment appointment = getServiceAppointment();
        ServiceResource resource = getServiceResources()[0];
        update new ServiceAppointment(Id = appointment.Id, HOT_TjenesteleverandorStatus__c = 'Transferred');

        Test.startTest();
        for (String targetStatus : new List<String>{ 'Scheduled', 'Dispatched' }) {
            HOT_SPAssignOrReserveSAService.Result result = HOT_SPAssignOrReserveSAService.assignOrReserve(
                new List<HOT_SPAssignOrReserveSAService.Input>{
                    createRequest(appointment.Id, resource.Id, targetStatus)
                }
            )[0];
            Assert.isFalse(result.success);
            Assert.areEqual('Oppdraget må være bekreftet av tjenesteleverandør.', result.message);
        }
        Test.stopTest();

        Assert.areEqual(0, [SELECT COUNT() FROM AssignedResource WHERE ServiceAppointmentId = :appointment.Id]);
    }

    @IsTest
    static void serviceProviderRejectsNonFreelanceAndInactiveResources() {
        ServiceAppointment appointment = getServiceAppointment();
        update new ServiceAppointment(Id = appointment.Id, HOT_TjenesteleverandorStatus__c = 'Accepted');
        List<ServiceResource> resources = getServiceResources();
        resources[0].HOT_IsFreelanceInterpreter__c = false;
        resources[1].IsActive = false;
        update resources;

        Test.startTest();
        for (ServiceResource resource : resources) {
            HOT_SPAssignOrReserveSAService.Result result = HOT_SPAssignOrReserveSAService.assignOrReserve(
                new List<HOT_SPAssignOrReserveSAService.Input>{
                    createRequest(appointment.Id, resource.Id, 'Dispatched')
                }
            )[0];
            Assert.isFalse(result.success);
            Assert.areEqual('Du må velge en aktiv tolk.', result.message);
        }
        Test.stopTest();

        Assert.areEqual(0, [SELECT COUNT() FROM AssignedResource WHERE ServiceAppointmentId = :appointment.Id]);
    }

    @IsTest
    static void serviceProviderRejectsRepeatedAssignmentInSameBatch() {
        ServiceAppointment appointment = getServiceAppointment();
        update new ServiceAppointment(Id = appointment.Id, HOT_TjenesteleverandorStatus__c = 'Accepted');
        HOT_SPAssignOrReserveSAService.Input input = createRequest(
            appointment.Id,
            getServiceResources()[0].Id,
            'Scheduled'
        );

        Test.startTest();
        List<HOT_SPAssignOrReserveSAService.Result> results = HOT_SPAssignOrReserveSAService.assignOrReserve(
            new List<HOT_SPAssignOrReserveSAService.Input>{ input, input }
        );
        Test.stopTest();

        Assert.isTrue(results[0].success, results[0].message);
        Assert.isFalse(results[1].success, 'The same appointment cannot receive a second interpreter');
        Assert.areEqual(1, [SELECT COUNT() FROM AssignedResource WHERE ServiceAppointmentId = :appointment.Id]);
    }

    @IsTest
    static void serviceProviderDispatchesReservedInterpreter() {
        ServiceAppointment appointment = getServiceAppointment();
        ServiceResource resource = getServiceResources()[0];
        reserveForServiceProvider(appointment.Id, resource.Id);
        update new ServiceAppointment(Id = appointment.Id, HOT_IsReleasedToFreelance__c = false);
        AssignedResource reservation = [
            SELECT Id
            FROM AssignedResource
            WHERE ServiceAppointmentId = :appointment.Id
        ];

        Test.startTest();
        HOT_SPAssignOrReserveSAService.Result result = HOT_SPAssignOrReserveSAService.assignOrReserve(
            new List<HOT_SPAssignOrReserveSAService.Input>{ createRequest(appointment.Id, resource.Id, 'Dispatched') }
        )[0];
        Test.stopTest();

        ServiceAppointment actual = [
            SELECT
                Status,
                HOT_TjenesteleverandorStatus__c,
                HOT_ServiceResource__c,
                HOT_AssignedResourceId__c,
                HOT_IsReleasedToFreelance__c
            FROM ServiceAppointment
            WHERE Id = :appointment.Id
        ];
        Assert.isTrue(result.success, result.message);
        Assert.areEqual('Dispatched', actual.Status);
        Assert.isTrue(actual.HOT_IsReleasedToFreelance__c, 'Dispatching a reservation must release to freelance');
        Assert.areEqual('Accepted', actual.HOT_TjenesteleverandorStatus__c);
        Assert.areEqual(resource.Id, actual.HOT_ServiceResource__c);
        Assert.areEqual(resource.RelatedRecordId, actual.HOT_AssignedResourceId__c);
        List<AssignedResource> assignments = [
            SELECT Id
            FROM AssignedResource
            WHERE ServiceAppointmentId = :appointment.Id
        ];
        Assert.areEqual(1, assignments.size(), 'Dispatch must reuse the existing reservation');
        Assert.areEqual(reservation.Id, assignments[0].Id);
    }

    @IsTest
    static void serviceProviderRejectsChangedReservedInterpreter() {
        ServiceAppointment appointment = getServiceAppointment();
        List<ServiceResource> resources = getServiceResources();
        reserveForServiceProvider(appointment.Id, resources[0].Id);

        Test.startTest();
        HOT_SPAssignOrReserveSAService.Result result = HOT_SPAssignOrReserveSAService.assignOrReserve(
            new List<HOT_SPAssignOrReserveSAService.Input>{
                createRequest(appointment.Id, resources[1].Id, 'Dispatched')
            }
        )[0];
        Test.stopTest();

        Assert.isFalse(result.success);
        Assert.areEqual(
            'Den reserverte tolken finnes ikke eller er endret. Last inn oppdraget på nytt.',
            result.message
        );
        Assert.areEqual('Scheduled', [SELECT Status FROM ServiceAppointment WHERE Id = :appointment.Id].Status);
        Assert.areEqual(
            resources[0].Id,
            [SELECT ServiceResourceId FROM AssignedResource WHERE ServiceAppointmentId = :appointment.Id]
            .ServiceResourceId
        );
    }

    @IsTest
    static void serviceProviderRejectsDispatchWithoutReservation() {
        ServiceAppointment appointment = getServiceAppointment();
        update new ServiceAppointment(
            Id = appointment.Id,
            Status = 'Scheduled',
            HOT_TjenesteleverandorStatus__c = 'Accepted'
        );

        Test.startTest();
        HOT_SPAssignOrReserveSAService.Result result = HOT_SPAssignOrReserveSAService.assignOrReserve(
            new List<HOT_SPAssignOrReserveSAService.Input>{
                createRequest(appointment.Id, getServiceResources()[0].Id, 'Dispatched')
            }
        )[0];
        Test.stopTest();

        Assert.isFalse(result.success);
        Assert.areEqual('Scheduled', [SELECT Status FROM ServiceAppointment WHERE Id = :appointment.Id].Status);
        Assert.areEqual(0, [SELECT COUNT() FROM AssignedResource WHERE ServiceAppointmentId = :appointment.Id]);
    }

    private static void reserveForServiceProvider(Id appointmentId, Id resourceId) {
        update new ServiceAppointment(Id = appointmentId, HOT_TjenesteleverandorStatus__c = 'Accepted');
        HOT_SPAssignOrReserveSAService.Result result = HOT_SPAssignOrReserveSAService.assignOrReserve(
            new List<HOT_SPAssignOrReserveSAService.Input>{ createRequest(appointmentId, resourceId, 'Scheduled') }
        )[0];
        Assert.isTrue(result.success, result.message);
    }

    @IsTest
    static void changesReservedInterpreterAndKeepsReservation() {
        assertInterpreterChange('Scheduled', 'Scheduled');
    }

    @IsTest
    static void changesReservedInterpreterAndDispatches() {
        assertInterpreterChange('Scheduled', 'Dispatched');
    }

    @IsTest
    static void changesDispatchedInterpreterAndReserves() {
        assertInterpreterChange('Dispatched', 'Scheduled');
    }

    @IsTest
    static void changesDispatchedInterpreterAndKeepsDispatch() {
        assertInterpreterChange('Dispatched', 'Dispatched');
    }

    private static void assertInterpreterChange(String sourceStatus, String targetStatus) {
        ServiceAppointment appointment = getServiceAppointment();
        List<ServiceResource> resources = getServiceResources();
        ServiceAppointment beforeChange = [
            SELECT SchedStartTime, SchedEndTime
            FROM ServiceAppointment
            WHERE Id = :appointment.Id
        ];
        update new ServiceAppointment(
            Id = appointment.Id,
            SchedStartTime = beforeChange.SchedStartTime.addMinutes(15),
            SchedEndTime = beforeChange.SchedEndTime.addMinutes(15)
        );
        AssignedResource original = assignOriginalInterpreter(appointment.Id, resources[0].Id, sourceStatus);

        Test.startTest();
        HOT_SPAssignOrReserveSAService.Result result = HOT_SPAssignOrReserveSAService.assignOrReserve(
            new List<HOT_SPAssignOrReserveSAService.Input>{
                createChangeRequest(original, resources[1].Id, targetStatus)
            }
        )[0];

        Assert.isTrue(result.success, result.message);
        ServiceAppointment actual = [
            SELECT
                Status,
                HOT_TjenesteleverandorStatus__c,
                HOT_ServiceResource__c,
                HOT_AssignedResourceId__c,
                HOT_IsReleasedToFreelance__c,
                HOT_IsEmployedInterpreter__c,
                SchedStartTime,
                SchedEndTime
            FROM ServiceAppointment
            WHERE Id = :appointment.Id
        ];
        Assert.areEqual(targetStatus, actual.Status);
        Assert.areEqual('Accepted', actual.HOT_TjenesteleverandorStatus__c);
        Assert.areEqual(resources[1].Id, actual.HOT_ServiceResource__c);
        Assert.areEqual(resources[1].RelatedRecordId, actual.HOT_AssignedResourceId__c);
        Assert.isTrue(actual.HOT_IsReleasedToFreelance__c);
        Assert.isFalse(actual.HOT_IsEmployedInterpreter__c);
        Assert.areEqual(beforeChange.SchedStartTime.addMinutes(15), actual.SchedStartTime);
        Assert.areEqual(beforeChange.SchedEndTime.addMinutes(15), actual.SchedEndTime);
        List<AssignedResource> assignments = [
            SELECT Id, ServiceResourceId
            FROM AssignedResource
            WHERE ServiceAppointmentId = :appointment.Id
        ];
        Assert.areEqual(1, assignments.size());
        Assert.areEqual(resources[1].Id, assignments[0].ServiceResourceId);
        Assert.areNotEqual(original.Id, assignments[0].Id);
        Map<Id, String> interestedStatuses = new Map<Id, String>();
        for (HOT_InterestedResource__c resource : [
            SELECT ServiceResource__c, Status__c
            FROM HOT_InterestedResource__c
            WHERE ServiceAppointment__c = :appointment.Id
        ]) {
            interestedStatuses.put(resource.ServiceResource__c, resource.Status__c);
        }
        Assert.areEqual('Withdrawn', interestedStatuses.get(resources[0].Id));
        Assert.areEqual(
            targetStatus == 'Dispatched' ? 'Assigned' : 'Reserved',
            interestedStatuses.get(resources[1].Id)
        );
        Test.stopTest();
    }

    @IsTest
    static void rejectsSameInterpreterAndStaleAssignment() {
        ServiceAppointment appointment = getServiceAppointment();
        List<ServiceResource> resources = getServiceResources();
        AssignedResource original = assignOriginalInterpreter(appointment.Id, resources[0].Id, 'Scheduled');
        HOT_SPAssignOrReserveSAService.Input sameInterpreter = createChangeRequest(
            original,
            resources[0].Id,
            'Scheduled'
        );
        HOT_SPAssignOrReserveSAService.Input staleInterpreter = createChangeRequest(
            original,
            resources[1].Id,
            'Dispatched'
        );
        staleInterpreter.originalServiceResourceId = resources[1].Id;

        Test.startTest();
        List<HOT_SPAssignOrReserveSAService.Result> results = HOT_SPAssignOrReserveSAService.assignOrReserve(
            new List<HOT_SPAssignOrReserveSAService.Input>{ sameInterpreter, staleInterpreter }
        );
        Test.stopTest();

        Assert.isFalse(results[0].success);
        Assert.areEqual('Du må velge en annen tolk.', results[0].message);
        Assert.isFalse(results[1].success);
        Assert.areEqual('Tildelingen er endret. Last inn oppdraget på nytt.', results[1].message);
        assertOriginalAssignment(original, 'Scheduled');
    }

    @IsTest
    static void rejectsInterpreterChangeWhenProviderHasNotAccepted() {
        ServiceAppointment appointment = getServiceAppointment();
        List<ServiceResource> resources = getServiceResources();
        AssignedResource original = assignOriginalInterpreter(appointment.Id, resources[0].Id, 'Scheduled');
        update new ServiceAppointment(Id = appointment.Id, HOT_TjenesteleverandorStatus__c = 'Transferred');

        Test.startTest();
        HOT_SPAssignOrReserveSAService.Result result = HOT_SPAssignOrReserveSAService.assignOrReserve(
            new List<HOT_SPAssignOrReserveSAService.Input>{
                createChangeRequest(original, resources[1].Id, 'Dispatched')
            }
        )[0];
        Test.stopTest();

        Assert.isFalse(result.success);
        Assert.areEqual('Oppdraget må være bekreftet av tjenesteleverandør.', result.message);
        assertOriginalAssignment(original, 'Scheduled');
    }

    @IsTest
    static void rejectsInterpreterChangeToInactiveResource() {
        ServiceAppointment appointment = getServiceAppointment();
        List<ServiceResource> resources = getServiceResources();
        AssignedResource original = assignOriginalInterpreter(appointment.Id, resources[0].Id, 'Dispatched');
        update new ServiceResource(Id = resources[1].Id, IsActive = false);

        Test.startTest();
        HOT_SPAssignOrReserveSAService.Result result = HOT_SPAssignOrReserveSAService.assignOrReserve(
            new List<HOT_SPAssignOrReserveSAService.Input>{
                createChangeRequest(original, resources[1].Id, 'Scheduled')
            }
        )[0];

        Assert.isFalse(result.success);
        Assert.areEqual('Du må velge en aktiv tolk.', result.message);
        assertOriginalAssignment(original, 'Dispatched');
        Test.stopTest();
    }

    @IsTest
    static void rollsBackInterpreterChangeWhenNewInterpreterHasOverlap() {
        ServiceAppointment appointment = getServiceAppointment();
        List<ServiceResource> resources = getServiceResources();
        AssignedResource original = assignOriginalInterpreter(appointment.Id, resources[0].Id, 'Dispatched');
        Test.startTest();
        ServiceAppointment overlappingAppointment = [
            SELECT Id
            FROM ServiceAppointment
            WHERE Subject = 'ReleasedSPAssignOrReserve'
            LIMIT 1
        ];
        insert new AssignedResource(
            ServiceAppointmentId = overlappingAppointment.Id,
            ServiceResourceId = resources[1].Id
        );
        HOT_SPAssignOrReserveSAService.Result result = HOT_SPAssignOrReserveSAService.assignOrReserve(
            new List<HOT_SPAssignOrReserveSAService.Input>{
                createChangeRequest(original, resources[1].Id, 'Scheduled')
            }
        )[0];

        Assert.isFalse(result.success, 'Overlap must reject the replacement after deletion of the old assignment');
        assertOriginalAssignment(original, 'Dispatched');
        ServiceAppointment actual = [
            SELECT HOT_ServiceResource__c, HOT_TjenesteleverandorStatus__c
            FROM ServiceAppointment
            WHERE Id = :appointment.Id
        ];
        Assert.areEqual(resources[0].Id, actual.HOT_ServiceResource__c);
        Assert.areEqual('Accepted', actual.HOT_TjenesteleverandorStatus__c);
        Test.stopTest();
    }

    @IsTest
    static void rejectsRepeatedInterpreterChangeInSameBatch() {
        ServiceAppointment appointment = getServiceAppointment();
        List<ServiceResource> resources = getServiceResources();
        AssignedResource original = assignOriginalInterpreter(appointment.Id, resources[0].Id, 'Scheduled');
        HOT_SPAssignOrReserveSAService.Input input = createChangeRequest(original, resources[1].Id, 'Scheduled');

        Test.startTest();
        List<HOT_SPAssignOrReserveSAService.Result> results = HOT_SPAssignOrReserveSAService.assignOrReserve(
            new List<HOT_SPAssignOrReserveSAService.Input>{ input, input }
        );
        Test.stopTest();

        Assert.isTrue(results[0].success, results[0].message);
        Assert.isFalse(results[1].success);
        Assert.areEqual('Tildelingen er endret. Last inn oppdraget på nytt.', results[1].message);
        Assert.areEqual(1, [SELECT COUNT() FROM AssignedResource WHERE ServiceAppointmentId = :appointment.Id]);
    }

    private static AssignedResource assignOriginalInterpreter(Id appointmentId, Id resourceId, String status) {
        AssignedResource original = new AssignedResource(
            ServiceAppointmentId = appointmentId,
            ServiceResourceId = resourceId
        );
        insert original;
        update new ServiceAppointment(
            Id = appointmentId,
            Status = status,
            HOT_IsReleasedToTjenesteleverandor__c = true,
            HOT_IsReleasedToFreelance__c = true,
            HOT_TjenesteleverandorStatus__c = 'Accepted'
        );
        return original;
    }

    private static HOT_SPAssignOrReserveSAService.Input createChangeRequest(
        AssignedResource original,
        Id newResourceId,
        String targetStatus
    ) {
        HOT_SPAssignOrReserveSAService.Input input = createRequest(
            original.ServiceAppointmentId,
            newResourceId,
            targetStatus
        );
        input.assignedResourceId = original.Id;
        input.originalServiceResourceId = original.ServiceResourceId;
        return input;
    }

    private static void assertOriginalAssignment(AssignedResource original, String expectedStatus) {
        AssignedResource actual = [
            SELECT Id, ServiceResourceId
            FROM AssignedResource
            WHERE ServiceAppointmentId = :original.ServiceAppointmentId
        ];
        Assert.areEqual(original.Id, actual.Id);
        Assert.areEqual(original.ServiceResourceId, actual.ServiceResourceId);
        Assert.areEqual(
            expectedStatus,
            [SELECT Status FROM ServiceAppointment WHERE Id = :original.ServiceAppointmentId].Status
        );
    }

    private static HOT_SPAssignOrReserveSAService.Input createRequest(
        Id serviceAppointmentId,
        Id serviceResourceId,
        String targetStatus
    ) {
        HOT_SPAssignOrReserveSAService.Input requestItem = new HOT_SPAssignOrReserveSAService.Input();
        requestItem.serviceAppointmentId = serviceAppointmentId;
        requestItem.serviceResourceId = serviceResourceId;
        requestItem.targetStatus = targetStatus;
        return requestItem;
    }

    private static ServiceAppointment getServiceAppointment() {
        return [SELECT Id, Status FROM ServiceAppointment WHERE Subject = 'SPAssignOrReserve' LIMIT 1];
    }

    private static List<ServiceResource> getServiceResources() {
        return [SELECT Id, RelatedRecordId FROM ServiceResource ORDER BY Name ASC];
    }

    private static ServiceAppointment createReleasedToFreelanceServiceAppointment() {
        WorkOrderLineItem workOrderLineItem = [
            SELECT Id
            FROM WorkOrderLineItem
            WHERE WorkOrder.HOT_Request__r.Subject__c = 'SPAssignOrReserve'
            LIMIT 1
        ];
        ServiceTerritory serviceTerritory = [SELECT Id FROM ServiceTerritory LIMIT 1];
        ServiceAppointment serviceAppointment = HOT_TestDataFactory.createServiceAppointment(workOrderLineItem);
        serviceAppointment.Subject = 'ReleasedSPAssignOrReserve';
        serviceAppointment.Status = 'Released to Freelance';
        serviceAppointment.ServiceTerritoryId = serviceTerritory.Id;
        serviceAppointment.HOT_IsReleasedToFreelance__c = true;
        serviceAppointment.HOT_FreelanceSubject__c = 'Test release';
        serviceAppointment.HOT_DeadlineDate__c = Date.today();
        insert serviceAppointment;
        return serviceAppointment;
    }
}
