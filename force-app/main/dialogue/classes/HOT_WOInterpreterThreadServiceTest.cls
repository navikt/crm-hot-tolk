@IsTest
private class HOT_WOInterpreterThreadServiceTest {
    @TestSetup
    static void setupData() {
        WorkType workType = HOT_TestDataFactory.createWorkType('FlowThreadMessageWT');
        insert workType;

        Account requestAccount = HOT_TestDataFactory.createAccount(true);
        insert requestAccount;

        HOT_Request__c request = HOT_TestDataFactory.createRequest('FLOW_THREAD_MSG_REQ', workType);
        request.Account__c = requestAccount.Id;
        request.Orderer__c = requestAccount.Id;
        request.Dispatcher__c = UserInfo.getUserId();
        insert request;

        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        workOrder.AccountId = requestAccount.Id;
        workOrder.Subject = 'FLOW_THREAD_MSG_WO';
        insert workOrder;

        WorkOrderLineItem workOrderLineItem1 = HOT_TestDataFactory.createWorkOrderLineItem(workOrder, workType);
        WorkOrderLineItem workOrderLineItem2 = HOT_TestDataFactory.createWorkOrderLineItem(workOrder, workType);
        insert new List<WorkOrderLineItem>{ workOrderLineItem1, workOrderLineItem2 };

        ServiceAppointment sa1 = HOT_TestDataFactory.createServiceAppointment(workOrderLineItem1);
        sa1.HOT_Request__c = request.Id;
        ServiceAppointment sa2 = HOT_TestDataFactory.createServiceAppointment(workOrderLineItem2);
        sa2.HOT_Request__c = request.Id;
        insert new List<ServiceAppointment>{ sa1, sa2 };

        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' OR Name = 'Standardbruker' LIMIT 1];

        User interpreterUser1 = HOT_TestDataFactory.createUser('wotint1', profile);
        User interpreterUser2 = HOT_TestDataFactory.createUser('wotint2', profile);
        insert new List<User>{ interpreterUser1, interpreterUser2 };

        Account interpreterAccount1 = HOT_TestDataFactory.createAccount(true);
        Account interpreterAccount2 = HOT_TestDataFactory.createAccount(true);
        insert new List<Account>{ interpreterAccount1, interpreterAccount2 };

        ServiceResource serviceResource1 = HOT_TestDataFactory.createServiceResource(interpreterUser1.Id);
        serviceResource1.AccountId = interpreterAccount1.Id;
        serviceResource1.HOT_IsFreelanceInterpreter__c = true;

        ServiceResource serviceResource2 = HOT_TestDataFactory.createServiceResource(interpreterUser2.Id);
        serviceResource2.AccountId = interpreterAccount2.Id;
        serviceResource2.HOT_IsFreelanceInterpreter__c = true;

        insert new List<ServiceResource>{ serviceResource1, serviceResource2 };

        AssignedResource assignedResource1 = HOT_TestDataFactory.createAssignedResource(sa1.Id, serviceResource1.Id);
        AssignedResource assignedResource2 = HOT_TestDataFactory.createAssignedResource(sa2.Id, serviceResource2.Id);
        insert new List<AssignedResource>{ assignedResource1, assignedResource2 };
    }

    @IsTest
    static void createsMissingThreadsAndSendsMessageToAllInterpreterThreads() {
        WorkOrder workOrder = [SELECT Id FROM WorkOrder WHERE Subject = 'FLOW_THREAD_MSG_WO' LIMIT 1];

        HOT_WOInterpreterThreadService.Input request = new HOT_WOInterpreterThreadService.Input();
        request.workOrderId = workOrder.Id;
        request.messageText = 'Broadcast to all';

        Test.startTest();
        List<HOT_WOInterpreterThreadService.Result> results = HOT_WOInterpreterThreadService.sendMessageToInterpreters(
            new List<HOT_WOInterpreterThreadService.Input>{ request }
        );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Expected exactly one result');
        System.assertEquals(2, results[0].interpreterCount, 'Expected two interpreters');
        System.assertEquals(2, results[0].createdThreadCount, 'Expected one new thread per interpreter');
        System.assertEquals(2, results[0].messageCount, 'Expected one message per thread');
        System.assertEquals('Processed', results[0].statusMessage, 'Expected successful processing status');

        List<Thread__c> threads = [
            SELECT Id, HOT_ServiceResource__c, HOT_ParticipantIds__c
            FROM Thread__c
            WHERE HOT_WorkOrder__c = :workOrder.Id AND CRM_Thread_Type__c = 'HOT_TOLK-FORMIDLER'
        ];
        System.assertEquals(2, threads.size(), 'Expected two one-to-one interpreter threads');

        Set<Id> serviceResourceIdsOnThread = new Set<Id>();
        for (Thread__c thread : threads) {
            serviceResourceIdsOnThread.add(thread.HOT_ServiceResource__c);
        }
        System.assertEquals(2, serviceResourceIdsOnThread.size(), 'Expected one unique thread per interpreter');

        Set<Id> threadIds = new Map<Id, Thread__c>(threads).keySet();
        Integer broadcastMessageCount = 0;
        for (Message__c message : [
            SELECT Id, CRM_Message_Text__c
            FROM Message__c
            WHERE CRM_Thread__c IN :threadIds
        ]) {
            if (message.CRM_Message_Text__c == 'Broadcast to all') {
                broadcastMessageCount++;
            }
        }
        System.assertEquals(2, broadcastMessageCount, 'Expected one message in each interpreter thread');
    }

    @IsTest
    static void reusesExistingThreadForInterpreterAndCreatesOnlyMissingOne() {
        WorkOrder workOrder = [
            SELECT Id, Subject, HOT_Request__r.Dispatcher__c, HOT_Request__r.Account__c
            FROM WorkOrder
            WHERE Subject = 'FLOW_THREAD_MSG_WO'
            LIMIT 1
        ];
        User interpreterUser1 = [SELECT Id FROM User WHERE LastName = 'wotint1' LIMIT 1];
        ServiceResource existingInterpreter = [
            SELECT Id, AccountId, RelatedRecordId
            FROM ServiceResource
            WHERE RelatedRecordId = :interpreterUser1.Id
            LIMIT 1
        ];

        Thread__c existingThread = new Thread__c();
        existingThread.RecordTypeId = HOT_MessageHelper.getHOTThreadRecordType();
        existingThread.CRM_Related_Object__c = workOrder.Id;
        existingThread.HOT_WorkOrder__c = workOrder.Id;
        existingThread.CRM_Thread_Type__c = 'HOT_TOLK-FORMIDLER';
        existingThread.HOT_ServiceResource__c = existingInterpreter.Id;
        existingThread.CRM_Account__c = existingInterpreter.AccountId;
        existingThread.HOT_Account__c = workOrder.HOT_Request__r.Account__c;
        existingThread.HOT_Dispatcher__c = workOrder.HOT_Request__r.Dispatcher__c;
        existingThread.HOT_Title__c = workOrder.Subject;
        existingThread.HOT_ParticipantIds__c = existingInterpreter.RelatedRecordId;
        insert existingThread;

        HOT_WOInterpreterThreadService.Input request = new HOT_WOInterpreterThreadService.Input();
        request.workOrderId = workOrder.Id;
        request.messageText = 'Broadcast with existing thread';

        Test.startTest();
        List<HOT_WOInterpreterThreadService.Result> results = HOT_WOInterpreterThreadService.sendMessageToInterpreters(
            new List<HOT_WOInterpreterThreadService.Input>{ request }
        );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Expected exactly one result');
        System.assertEquals(2, results[0].interpreterCount, 'Expected two interpreters');
        System.assertEquals(1, results[0].createdThreadCount, 'Expected only one missing thread to be created');
        System.assertEquals(2, results[0].messageCount, 'Expected message in both interpreter threads');

        Integer existingThreadCount = [
            SELECT COUNT()
            FROM Thread__c
            WHERE
                HOT_WorkOrder__c = :workOrder.Id
                AND CRM_Thread_Type__c = 'HOT_TOLK-FORMIDLER'
                AND HOT_ServiceResource__c = :existingInterpreter.Id
        ];
        System.assertEquals(1, existingThreadCount, 'Should not create duplicate thread for same interpreter');

        List<Thread__c> allInterpreterThreads = [
            SELECT Id
            FROM Thread__c
            WHERE HOT_WorkOrder__c = :workOrder.Id AND CRM_Thread_Type__c = 'HOT_TOLK-FORMIDLER'
        ];
        System.assertEquals(2, allInterpreterThreads.size(), 'Expected exactly two interpreter threads in total');

        Set<Id> threadIds = new Map<Id, Thread__c>(allInterpreterThreads).keySet();
        Integer messagesCreated = 0;
        for (Message__c message : [
            SELECT Id, CRM_Message_Text__c
            FROM Message__c
            WHERE CRM_Thread__c IN :threadIds
        ]) {
            if (message.CRM_Message_Text__c == 'Broadcast with existing thread') {
                messagesCreated++;
            }
        }
        System.assertEquals(2, messagesCreated, 'Expected one broadcast message per interpreter thread');
    }
}
