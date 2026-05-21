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

    private static Thread__c createThread(Id relatedObjectId, String threadType) {
        Thread__c thread = HOT_TestDataFactory.createThread(threadType);
        thread.CRM_Related_Object__c = relatedObjectId;
        insert thread;
        return thread;
    }

    @IsTest
    static void canReplyBeforeFortyEightHours() {
        TestContext context = createContext();
        createServiceAppointment(context, System.now().addHours(-47), 'Completed');
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
        createServiceAppointment(context, System.now().addHours(-49), 'Completed');
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
        createServiceAppointment(context, System.now().addHours(-49), 'Completed');
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
        createServiceAppointment(context, System.now().addHours(-49), 'Completed');
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
    static void requestThreadUsesLatestNonAnnulledServiceAppointment() {
        TestContext context = createContext();
        context.request.StartTime__c = System.now().addHours(-101);
        context.request.EndTime__c = System.now().addHours(-100);
        update context.request;

        createServiceAppointment(context, System.now().addHours(-80), 'Completed');
        createServiceAppointment(context, System.now().addHours(-1), 'Completed');
        createServiceAppointment(context, System.now().addDays(5), 'Annul');
        Thread__c thread = createThread(context.request.Id, 'HOT_BRUKER-FORMIDLER');

        Test.startTest();
        HOT_ThreadReplyPolicy.ReplyPolicy policy = HOT_ThreadReplyPolicy.getReplyPolicies(new Set<Id>{ thread.Id })
            .get(thread.Id);
        Test.stopTest();

        System.assertEquals(
            true,
            policy.canReply,
            'Series request threads should use the latest non-annulled ServiceAppointment end, not Request.EndTime__c.'
        );
        System.assert(
            policy.appointmentEndTime > System.now().addHours(-2),
            'The future Annul appointment should be ignored and the recent non-annulled appointment should be used.'
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
        context.request.StartTime__c = System.now().addHours(-60);
        context.request.EndTime__c = System.now().addHours(-49);
        update context.request;
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
        context.workOrder.StartDate = System.now().addHours(-60);
        context.workOrder.EndDate = System.now().addHours(-49);
        update context.workOrder;
        Thread__c thread = createThread(context.workOrder.Id, 'HOT_BRUKER-TOLK');

        Test.startTest();
        HOT_ThreadReplyPolicy.ReplyPolicy policy = HOT_ThreadReplyPolicy.getReplyPolicies(new Set<Id>{ thread.Id })
            .get(thread.Id);
        Test.stopTest();

        System.assertEquals(false, policy.canReply, 'WorkOrder EndDate should be fallback when no SA end exists.');
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
