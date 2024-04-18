@IsTest
private class HOT_ThreadSharingServiceTest {
    @TestSetup
    static void makeData() {
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' OR Name = 'Standardbruker' LIMIT 1];
        User user = HOT_TestDataFactory.createUser('user', profile);
        insert user;
        ServiceResource resource = HOT_TestDataFactory.createServiceResource(user.Id);
        insert resource;
    }

    @IsTest
    private static void testGrantAccess() {
        Map<Id, Set<Id>> interpreterByThread = new Map<Id, Set<Id>>();
        Set<Id> participants = new Set<Id>();
        User user = [SELECT Id FROM User LIMIT 1];

        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        Account account = HOT_TestDataFactory.createAccount(true);
        insert account;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        workOrder.AccountId = account.Id;
        insert workOrder;
        WorkOrderLineItem workOrderLineItem = HOT_TestDataFactory.createWorkOrderLineItem(workOrder, workType);
        insert workOrderLineItem;
        ServiceAppointment serviceAppointment_1 = HOT_TestDataFactory.createServiceAppointment(workOrderLineItem);
        serviceAppointment_1.HOT_Request__c = request.Id;
        insert serviceAppointment_1;

        Thread__c thread = HOT_TestDataFactory.createThread('HOT_TOLK-FORMIDLER');
        thread.HOT_ParticipantIds__c = user.Id;
        thread.CRM_Related_Object_Type__c = 'ServiceAppointment';
        thread.CRM_Related_Object__c = [SELECT Id FROM ServiceAppointment LIMIT 1].Id;
        insert thread;

        participants.add(user.Id);
        interpreterByThread.put(thread.Id, participants);

        Test.startTest();
        HOT_ThreadSharingService.grantAccess(interpreterByThread);
        Test.stopTest();

        System.assertEquals(1, [SELECT COUNT() FROM Thread__Share WHERE ParentId = :thread.Id]);
    }

    @IsTest
    private static void testPopulateParticipantSet() {
        User user = [SELECT Id FROM User LIMIT 1];
        String participants = user.Id;
        Set<Id> participantSet = HOT_ThreadSharingService.populateParticipantSet(participants);

        System.assertEquals(new Set<Id>{ user.Id }, participantSet);
    }
}
