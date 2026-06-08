@IsTest
private class HOT_ThreadReplyPolicyTest {
    private class TestContext {
        WorkType workType;
        HOT_Request__c request;
        WorkOrder workOrder;
        WorkOrderLineItem workOrderLineItem;
    }

    private static TestContext createContext() {
        TestContext context = new TestContext();
        context.workType = HOT_TestDataFactory.createWorkType('Reply policy work type');
        insert context.workType;

        Account account = HOT_TestDataFactory.createAccount(true);
        insert account;

        context.request = HOT_TestDataFactory.createRequest('Reply policy request', context.workType);
        context.request.Account__c = account.Id;
        context.request.Orderer__c = account.Id;
        insert context.request;

        context.workOrder = HOT_TestDataFactory.createWorkOrder(context.request, context.workType);
        context.workOrder.AccountId = account.Id;
        insert context.workOrder;

        context.workOrderLineItem = HOT_TestDataFactory.createWorkOrderLineItem(context.workOrder, context.workType);
        insert context.workOrderLineItem;
        annulExistingServiceAppointments(context);

        return context;
    }

    private static void annulExistingServiceAppointments(TestContext context) {
        List<ServiceAppointment> serviceAppointments = [
            SELECT Id
            FROM ServiceAppointment
            WHERE HOT_Request__c = :context.request.Id OR ParentRecordId = :context.workOrderLineItem.Id
        ];
        for (ServiceAppointment serviceAppointment : serviceAppointments) {
            serviceAppointment.Status = 'Annul';
        }
        update serviceAppointments;
    }

    private static ServiceAppointment createServiceAppointment(TestContext context, Datetime endTime, String status) {
        ServiceAppointment serviceAppointment = HOT_TestDataFactory.createServiceAppointment(context.workOrderLineItem);
        serviceAppointment.HOT_Request__c = context.request.Id;
        serviceAppointment.EarliestStartTime = endTime.addHours(-1);
        serviceAppointment.DueDate = endTime;
        serviceAppointment.SchedStartTime = endTime.addHours(-1);
        serviceAppointment.SchedEndTime = endTime;
        serviceAppointment.Status = status;
        insert serviceAppointment;
        update new ServiceAppointment(
            Id = serviceAppointment.Id,
            DueDate = endTime,
            SchedStartTime = endTime.addHours(-1),
            SchedEndTime = endTime,
            Status = status
        );
        return serviceAppointment;
    }

    private static void setRequestEndTime(HOT_Request__c request, Datetime endTime) {
        request.StartTime__c = endTime.addHours(-1);
        request.EndTime__c = endTime;
        update request;
    }

    private static void setWorkOrderEndTime(WorkOrder workOrder, Datetime endTime) {
        workOrder.StartDate = endTime.addHours(-1);
        workOrder.EndDate = endTime;
        update workOrder;
    }

    private static Thread__c createThread(Id relatedObjectId, String threadType) {
        Thread__c thread = HOT_TestDataFactory.createThread(threadType);
        thread.CRM_Related_Object__c = relatedObjectId;
        if (relatedObjectId.getSObjectType() == HOT_Request__c.SObjectType) {
            thread.HOT_Request__c = relatedObjectId;
        }
        if (relatedObjectId.getSObjectType() == WorkOrder.SObjectType) {
            thread.HOT_WorkOrder__c = relatedObjectId;
        }
        if (relatedObjectId.getSObjectType() == ServiceAppointment.SObjectType) {
            thread.HOT_ServiceAppointment__c = relatedObjectId;
        }
        if (relatedObjectId.getSObjectType() == HOT_InterestedResource__c.SObjectType) {
            thread.HOT_InterestedResource__c = relatedObjectId;
        }
        if (relatedObjectId.getSObjectType() == HOT_WageClaim__c.SObjectType) {
            thread.HOT_WageClaim__c = relatedObjectId;
        }
        insert thread;
        return thread;
    }

    @IsTest
    static void canReplyBeforeFortyEightHours() {
        TestContext context = createContext();
        setRequestEndTime(context.request, System.now().addHours(-47));
        Thread__c thread = createThread(context.request.Id, 'HOT_BRUKER-FORMIDLER');

        Test.startTest();
        HOT_ThreadReplyPolicy.ReplyPolicy policy = HOT_ThreadReplyPolicy.getReplyPolicies(new Set<Id>{ thread.Id })
            .get(thread.Id);
        Test.stopTest();

        System.assertEquals(true, policy.canReply, 'Thread should remain open inside the 48 hour reply window.');
    }

    @IsTest
    static void cannotReplyAfterFortyEightHours() {
        TestContext context = createContext();
        setRequestEndTime(context.request, System.now().addHours(-49));
        Thread__c thread = createThread(context.request.Id, 'HOT_BRUKER-FORMIDLER');

        Test.startTest();
        HOT_ThreadReplyPolicy.ReplyPolicy policy = HOT_ThreadReplyPolicy.getReplyPolicies(new Set<Id>{ thread.Id })
            .get(thread.Id);
        Test.stopTest();

        System.assertEquals(false, policy.canReply, 'Thread should close after the 48 hour reply window.');
    }

    @IsTest
    static void resourceOfficeThreadCanReplyAfterFortyEightHours() {
        TestContext context = createContext();
        setRequestEndTime(context.request, System.now().addHours(-49));
        Thread__c thread = createThread(context.request.Id, 'HOT_TOLK-RESSURSKONTOR');

        Test.startTest();
        HOT_ThreadReplyPolicy.ReplyPolicy policy = HOT_ThreadReplyPolicy.getReplyPolicies(new Set<Id>{ thread.Id })
            .get(thread.Id);
        Test.stopTest();

        System.assertEquals(true, policy.canReply, 'Resource office threads are exempt from the 48 hour rule.');
    }

    @IsTest
    static void directMessageInsertIsRejectedWhenThreadIsClosed() {
        TestContext context = createContext();
        setRequestEndTime(context.request, System.now().addHours(-49));
        Thread__c thread = createThread(context.request.Id, 'HOT_BRUKER-FORMIDLER');

        Message__c message = new Message__c(
            CRM_Thread__c = thread.Id,
            CRM_Message_Text__c = 'Dette skal ikke lagres',
            HOT_User_Role__c = 'Test, Formidler'
        );

        Test.startTest();
        Database.SaveResult saveResult = Database.insert(message, false);
        Test.stopTest();

        System.assertEquals(false, saveResult.isSuccess(), 'Direct Message__c insert should be blocked.');
        System.assert(
            saveResult.getErrors()[0].getMessage().contains('stengt for videre dialog'),
            'The user-facing validation message should explain that the conversation is closed.'
        );
    }

    @IsTest
    static void requestThreadUsesFormulaEndTime() {
        TestContext context = createContext();
        Datetime requestEndTime = System.now().addHours(-100);
        setRequestEndTime(context.request, requestEndTime);
        Thread__c thread = createThread(context.request.Id, 'HOT_BRUKER-FORMIDLER');

        Test.startTest();
        HOT_ThreadReplyPolicy.ReplyPolicy policy = HOT_ThreadReplyPolicy.getReplyPolicies(new Set<Id>{ thread.Id })
            .get(thread.Id);
        Test.stopTest();

        System.assertEquals(
            false,
            policy.canReply,
            'Request threads should use the formula field on Thread__c, which resolves HOT_Request__r.EndTime__c.'
        );
        System.assertEquals(
            requestEndTime,
            policy.appointmentEndTime,
            'The reply policy should not query child ServiceAppointments when the thread formula has an end time.'
        );
    }

    @IsTest
    static void seriesRequestThreadUsesLatestServiceAppointmentEndTime() {
        TestContext context = createContext();
        Datetime requestEndTime = System.now().addHours(-100);
        Datetime firstAppointmentEndTime = System.now().addHours(-49);
        Datetime latestAppointmentEndTime = System.now().addHours(-1);
        setRequestEndTime(context.request, requestEndTime);
        context.request.NumberOfWorkOrders__c = 2;
        update context.request;
        createServiceAppointment(context, firstAppointmentEndTime, 'Completed');
        createServiceAppointment(context, latestAppointmentEndTime, 'Completed');
        Thread__c thread = createThread(context.request.Id, 'HOT_BRUKER-FORMIDLER');

        Test.startTest();
        Integer queriesBefore = Limits.getQueries();
        HOT_ThreadReplyPolicy.ReplyPolicy policy = HOT_ThreadReplyPolicy.getReplyPolicies(new Set<Id>{ thread.Id })
            .get(thread.Id);
        Integer queriesUsed = Limits.getQueries() - queriesBefore;
        Test.stopTest();

        System.assertEquals(
            2,
            queriesUsed,
            'Series request threads should use one thread query and one grouped ServiceAppointment query.'
        );
        System.assertEquals(
            true,
            policy.canReply,
            'Series request threads should stay open until 48 hours after the last ServiceAppointment ends.'
        );
        System.assertEquals(
            latestAppointmentEndTime,
            policy.appointmentEndTime,
            'Series request threads should use the latest ServiceAppointment end time instead of HOT_Request__r.EndTime__c.'
        );
    }

    @IsTest
    static void nonSeriesRequestThreadDoesNotUseServiceAppointmentEndTime() {
        TestContext context = createContext();
        Datetime requestEndTime = System.now().addHours(-49);
        Datetime latestAppointmentEndTime = System.now().addHours(-1);
        setRequestEndTime(context.request, requestEndTime);
        context.request.NumberOfWorkOrders__c = 1;
        update context.request;
        createServiceAppointment(context, latestAppointmentEndTime, 'Completed');
        Thread__c thread = createThread(context.request.Id, 'HOT_BRUKER-FORMIDLER');

        Test.startTest();
        Integer queriesBefore = Limits.getQueries();
        HOT_ThreadReplyPolicy.ReplyPolicy policy = HOT_ThreadReplyPolicy.getReplyPolicies(new Set<Id>{ thread.Id })
            .get(thread.Id);
        Integer queriesUsed = Limits.getQueries() - queriesBefore;
        Test.stopTest();

        System.assertEquals(1, queriesUsed, 'Non-series request threads should only use the thread query.');
        System.assertEquals(
            false,
            policy.canReply,
            'Non-series request threads should keep using the formula close date.'
        );
        System.assertEquals(
            requestEndTime,
            policy.appointmentEndTime,
            'Non-series request threads should not use child ServiceAppointment end times.'
        );
    }

    @IsTest
    static void helperCreateMessageReturnsFalseWhenThreadIsClosed() {
        TestContext context = createContext();
        ServiceAppointment serviceAppointment = createServiceAppointment(
            context,
            System.now().addHours(-49),
            'Completed'
        );

        ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(UserInfo.getUserId());
        insert serviceResource;

        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(
            serviceAppointment.Id,
            serviceResource.Id
        );
        insert assignedResource;

        Thread__c thread = HOT_TestDataFactory.createThread('HOT_TOLK-FORMIDLER');
        thread.CRM_Related_Object__c = serviceAppointment.Id;
        thread.HOT_ServiceAppointment__c = serviceAppointment.Id;
        insert thread;

        Test.startTest();
        Boolean result = HOT_MessageHelper.createMessage(thread.Id, 'Dette skal avvises', null);
        Test.stopTest();

        System.assertEquals(false, result, 'Apex helper should return false when the reply policy closes the thread.');
    }

    @IsTest
    static void requestFallbackUsesRequestEndTimeWhenNoServiceAppointmentExists() {
        TestContext context = createContext();
        setRequestEndTime(context.request, System.now().addHours(-49));
        Thread__c thread = createThread(context.request.Id, 'HOT_BRUKER-FORMIDLER');

        Test.startTest();
        HOT_ThreadReplyPolicy.ReplyPolicy policy = HOT_ThreadReplyPolicy.getReplyPolicies(new Set<Id>{ thread.Id })
            .get(thread.Id);
        Test.stopTest();

        System.assertEquals(false, policy.canReply, 'Request EndTime__c should be fallback when no SA end exists.');
    }

    @IsTest
    static void workOrderFallbackUsesWorkOrderEndDateWhenNoServiceAppointmentExists() {
        TestContext context = createContext();
        setWorkOrderEndTime(context.workOrder, System.now().addHours(-49));
        Thread__c thread = createThread(context.workOrder.Id, 'HOT_BRUKER-TOLK');

        Test.startTest();
        HOT_ThreadReplyPolicy.ReplyPolicy policy = HOT_ThreadReplyPolicy.getReplyPolicies(new Set<Id>{ thread.Id })
            .get(thread.Id);
        Test.stopTest();

        System.assertEquals(false, policy.canReply, 'WorkOrder EndDate should be fallback when no SA end exists.');
    }

    @IsTest
    static void serviceAppointmentThreadUsesScheduledEndTime() {
        TestContext context = createContext();
        Datetime appointmentEndTime = System.now().addHours(-49);
        ServiceAppointment serviceAppointment = createServiceAppointment(context, appointmentEndTime, 'Completed');
        Thread__c thread = createThread(serviceAppointment.Id, 'HOT_TOLK-FORMIDLER');

        Test.startTest();
        HOT_ThreadReplyPolicy.ReplyPolicy policy = HOT_ThreadReplyPolicy.getReplyPolicies(new Set<Id>{ thread.Id })
            .get(thread.Id);
        Test.stopTest();

        System.assertEquals(false, policy.canReply, 'ServiceAppointment threads should close from SchedEndTime.');
        System.assertEquals(
            appointmentEndTime,
            policy.appointmentEndTime,
            'The policy should expose the ServiceAppointment SchedEndTime from the formula.'
        );
    }

    @IsTest
    static void serviceAppointmentThreadFallsBackToDueDate() {
        TestContext context = createContext();
        Datetime dueDate = System.now().addHours(-49);
        ServiceAppointment serviceAppointment = createServiceAppointment(context, dueDate, 'Completed');
        update new ServiceAppointment(Id = serviceAppointment.Id, SchedEndTime = null, DueDate = dueDate);
        Thread__c thread = createThread(serviceAppointment.Id, 'HOT_TOLK-FORMIDLER');

        Test.startTest();
        HOT_ThreadReplyPolicy.ReplyPolicy policy = HOT_ThreadReplyPolicy.getReplyPolicies(new Set<Id>{ thread.Id })
            .get(thread.Id);
        Test.stopTest();

        System.assertEquals(
            false,
            policy.canReply,
            'ServiceAppointment threads should close from DueDate if SchedEndTime is blank.'
        );
        System.assertEquals(
            dueDate,
            policy.appointmentEndTime,
            'The formula should fall back to ServiceAppointment DueDate.'
        );
    }

    @IsTest
    static void interestedResourceThreadUsesServiceAppointmentEndTime() {
        TestContext context = createContext();
        Datetime appointmentEndTime = System.now().addHours(-49);
        ServiceAppointment serviceAppointment = createServiceAppointment(context, appointmentEndTime, 'Completed');
        ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(UserInfo.getUserId());
        insert serviceResource;
        HOT_InterestedResource__c interestedResource = HOT_TestDataFactory.createInterestedResource(
            serviceAppointment.Id,
            serviceResource.Id
        );
        insert interestedResource;
        Thread__c thread = createThread(interestedResource.Id, 'HOT_TOLK-FORMIDLER');

        Test.startTest();
        HOT_ThreadReplyPolicy.ReplyPolicy policy = HOT_ThreadReplyPolicy.getReplyPolicies(new Set<Id>{ thread.Id })
            .get(thread.Id);
        Test.stopTest();

        System.assertEquals(
            false,
            policy.canReply,
            'InterestedResource threads should close from the related ServiceAppointment.'
        );
        System.assertEquals(
            appointmentEndTime,
            policy.appointmentEndTime,
            'The formula should traverse InterestedResource to ServiceAppointment end time.'
        );
    }

    @IsTest
    static void threadWithoutCloseDateStaysOpen() {
        Thread__c thread = HOT_TestDataFactory.createThread('HOT_BRUKER-FORMIDLER');
        insert thread;

        Test.startTest();
        HOT_ThreadReplyPolicy.ReplyPolicy policy = HOT_ThreadReplyPolicy.getReplyPolicies(new Set<Id>{ thread.Id })
            .get(thread.Id);
        Test.stopTest();

        System.assertEquals(true, policy.canReply, 'Threads with no formula close datetime should stay open.');
        System.assertEquals(
            null,
            policy.appointmentEndTime,
            'No close datetime should be exposed when the formula is blank.'
        );
    }

    @IsTest
    static void wageClaimDoesNotPopulateCloseDate() {
        TestContext context = createContext();
        ServiceAppointment serviceAppointment = createServiceAppointment(
            context,
            System.now().addHours(-49),
            'Completed'
        );
        ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(UserInfo.getUserId());
        insert serviceResource;
        HOT_WageClaim__c wageClaim = HOT_TestDataFactory.createWageClaim(serviceResource);
        wageClaim.ServiceAppointment__c = serviceAppointment.Id;
        wageClaim.StartTime__c = System.now().addHours(-50);
        wageClaim.EndTime__c = System.now().addHours(-49);
        insert wageClaim;
        Thread__c thread = createThread(wageClaim.Id, 'HOT_BRUKER-FORMIDLER');

        Test.startTest();
        HOT_ThreadReplyPolicy.ReplyPolicy policy = HOT_ThreadReplyPolicy.getReplyPolicies(new Set<Id>{ thread.Id })
            .get(thread.Id);
        Test.stopTest();

        Thread__c savedThread = [SELECT HOT_Close_DateTime__c FROM Thread__c WHERE Id = :thread.Id];
        System.assertEquals(
            null,
            savedThread.HOT_Close_DateTime__c,
            'WageClaim should not feed the thread close formula.'
        );
        System.assertEquals(
            true,
            policy.canReply,
            'A WageClaim-only close date should not close non-resource-office threads.'
        );
    }

    @IsTest
    static void serviceAppointmentThreadUsesExplicitServiceAppointmentBeforeRelatedWorkOrder() {
        TestContext context = createContext();
        ServiceAppointment oldServiceAppointment = createServiceAppointment(
            context,
            System.now().addHours(-49),
            'Completed'
        );
        createServiceAppointment(context, System.now().addHours(-1), 'Completed');

        Thread__c thread = HOT_TestDataFactory.createThread('HOT_TOLK-FORMIDLER');
        thread.CRM_Related_Object__c = context.workOrder.Id;
        thread.HOT_ServiceAppointment__c = oldServiceAppointment.Id;
        insert thread;

        Test.startTest();
        HOT_ThreadReplyPolicy.ReplyPolicy policy = HOT_ThreadReplyPolicy.getReplyPolicies(new Set<Id>{ thread.Id })
            .get(thread.Id);
        Test.stopTest();

        System.assertEquals(
            false,
            policy.canReply,
            'An explicit ServiceAppointment thread should not stay open because another SA exists on the WorkOrder.'
        );
    }

    @IsTest
    static void messageHelperInformationMethodsStillWorkWithReplyPolicy() {
        TestContext context = createContext();
        ServiceAppointment serviceAppointment = createServiceAppointment(
            context,
            System.now().addHours(2),
            'Scheduled'
        );

        ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(UserInfo.getUserId());
        insert serviceResource;
        insert HOT_TestDataFactory.createAssignedResource(serviceAppointment.Id, serviceResource.Id);

        HOT_InterestedResource__c interestedResource = HOT_TestDataFactory.createInterestedResource(
            serviceAppointment.Id,
            serviceResource.Id
        );
        insert interestedResource;

        HOT_WageClaim__c wageClaim = HOT_TestDataFactory.createWageClaim(serviceResource);
        wageClaim.ServiceAppointment__c = serviceAppointment.Id;
        insert wageClaim;

        Thread__c thread = HOT_TestDataFactory.createThread('HOT_TOLK-FORMIDLER');
        thread.CRM_Related_Object__c = serviceAppointment.Id;
        thread.HOT_ServiceAppointment__c = serviceAppointment.Id;
        insert thread;
        Thread__c requestThread = createThread(context.request.Id, 'HOT_BRUKER-FORMIDLER');

        Test.startTest();
        System.assertEquals('HOT_Request__c', HOT_MessageHelper.getRecordObjectType(context.request.Id));
        System.assertEquals(context.request.Account__c, HOT_MessageHelper.getAccountOnRequest(context.request.Id));
        System.assertEquals(context.workOrder.AccountId, HOT_MessageHelper.getAccountOnWorkOrder(context.workOrder.Id));
        System.assertEquals(false, HOT_MessageHelper.getRequestInformation(context.request.Id).isEmpty());
        System.assertEquals(false, HOT_MessageHelper.getWorkOrderInformation(context.workOrder.Id).isEmpty());
        System.assertEquals(false, HOT_MessageHelper.getThreadFromThreadId(thread.Id).isEmpty());
        System.assertEquals(false, HOT_MessageHelper.getThreads(context.request.Id).isEmpty());
        System.assertEquals(
            false,
            HOT_MessageHelper.getSingleThread(context.request.Id, requestThread.CRM_Thread_Type__c).isEmpty()
        );
        System.assertNotEquals(null, HOT_MessageHelper.getUserLisenceType(UserInfo.getUserId()));
        System.assertNotEquals(null, HOT_MessageHelper.getUserNameRole());
        System.assertNotEquals(null, HOT_MessageHelper.getUserProfileAndName('HOT_TOLK-FORMIDLER'));
        System.assertNotEquals(null, HOT_MessageHelper.getThreadById(thread.Id));
        System.assertEquals(
            true,
            HOT_MessageHelper.getThreadByIdWithReplyPolicy(thread.Id).replyPolicy.canReply,
            'Message helper wrapper should include reply policy without a second UI Apex call.'
        );
        System.assertEquals(
            true,
            HOT_ThreadDetailController.getThreadDetailsWithReplyPolicy(thread.Id).replyPolicy.canReply,
            'Thread detail wrapper should include reply policy without a separate UI Apex call.'
        );
        System.assertNotEquals(
            null,
            HOT_MessageHelper.getServiceAppointmentInformationAndAccessCheck(serviceAppointment.Id)
        );
        System.assertNotEquals(
            null,
            HOT_MessageHelper.getInterestedResourceInformationAndAccessCheck(interestedResource.Id)
        );
        System.assertNotEquals(null, HOT_MessageHelper.getWageClaimInformationAndAccessCheck(wageClaim.Id));
        System.assertNotEquals(null, HOT_MessageHelper.createMessages(thread, 'Ikke lagret', null));
        Test.stopTest();
    }
}
