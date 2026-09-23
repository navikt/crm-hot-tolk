@IsTest
public with sharing class HOT_TLThreadListControllerTest {
    private static final String APPOINTMENT_SUBJECT = 'TL Thread List Appointment';

    @TestSetup
    static void setupData() {
        WorkType workType = HOT_TestDataFactory.createWorkType('tl-thread-list');
        insert workType;

        HOT_Request__c request = HOT_TestDataFactory.createRequest('tl-thread-list', workType);
        insert request;

        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder;

        WorkOrderLineItem workOrderLineItem = HOT_TestDataFactory.createWorkOrderLineItem(workOrder, workType);
        insert workOrderLineItem;

        ServiceAppointment serviceAppointment = HOT_TestDataFactory.createServiceAppointment(workOrderLineItem);
        serviceAppointment.Subject = APPOINTMENT_SUBJECT;
        serviceAppointment.Status = 'Scheduled';
        serviceAppointment.HOT_TjenesteleverandorStatus__c = 'Transferred';
        insert serviceAppointment;

        ServiceResource currentUserServiceResource = HOT_TestDataFactory.createServiceResource(UserInfo.getUserId());
        insert currentUserServiceResource;

        Thread__c accessibleThread = HOT_TestDataFactory.createThread('HOT_TJENESTELEVERANDOR-FORMIDLER');
        accessibleThread.CRM_Type__c = 'HOT_TJENESTELEVERANDOR-FORMIDLER';
        accessibleThread.CRM_Related_Object__c = serviceAppointment.Id;
        accessibleThread.HOT_ReadByTjenesteleverandor__c = false;
        accessibleThread.HOT_ServiceResource__c = currentUserServiceResource.Id;
        insert accessibleThread;

        Thread__c inaccessibleThread = HOT_TestDataFactory.createThread('HOT_TJENESTELEVERANDOR-TOLK');
        inaccessibleThread.CRM_Type__c = 'HOT_TJENESTELEVERANDOR-TOLK';
        inaccessibleThread.CRM_Related_Object__c = serviceAppointment.Id;
        inaccessibleThread.HOT_ReadByTjenesteleverandor__c = false;
        insert inaccessibleThread;

        Thread__c excludedThreadType = HOT_TestDataFactory.createThread('HOT_BRUKER-FORMIDLER');
        excludedThreadType.CRM_Type__c = 'HOT_BRUKER-FORMIDLER';
        excludedThreadType.CRM_Related_Object__c = serviceAppointment.Id;
        insert excludedThreadType;

        Thread__c excludedNoMessages = HOT_TestDataFactory.createThread('HOT_TJENESTELEVERANDOR-FORMIDLER');
        excludedNoMessages.CRM_Type__c = 'HOT_TJENESTELEVERANDOR-FORMIDLER';
        excludedNoMessages.CRM_Related_Object__c = serviceAppointment.Id;
        insert excludedNoMessages;

        insert new List<Message__c>{
            new Message__c(CRM_Thread__c = accessibleThread.Id, CRM_Message_Text__c = 'message-accessible'),
            new Message__c(CRM_Thread__c = inaccessibleThread.Id, CRM_Message_Text__c = 'message-inaccessible'),
            new Message__c(CRM_Thread__c = excludedThreadType.Id, CRM_Message_Text__c = 'message-wrong-type')
        };
    }

    private static Id getAccessibleThreadId() {
        Id serviceAppointmentId = getServiceAppointmentId();
        return [
            SELECT Id
            FROM Thread__c
            WHERE
                CRM_Related_Object__c = :serviceAppointmentId
                AND CRM_Type__c = 'HOT_TJENESTELEVERANDOR-FORMIDLER'
                AND HOT_ServiceResource__c != NULL
            LIMIT 1
        ]
        .Id;
    }

    private static Id getInaccessibleThreadId() {
        Id serviceAppointmentId = getServiceAppointmentId();
        return [
            SELECT Id
            FROM Thread__c
            WHERE CRM_Related_Object__c = :serviceAppointmentId AND CRM_Type__c = 'HOT_TJENESTELEVERANDOR-TOLK'
            LIMIT 1
        ]
        .Id;
    }

    private static Id getServiceAppointmentId() {
        return [SELECT Id FROM ServiceAppointment WHERE Subject = :APPOINTMENT_SUBJECT LIMIT 1].Id;
    }

    private static User createNonAdminUser() {
        Profile profile = [
            SELECT Id
            FROM Profile
            WHERE PermissionsModifyAllData = FALSE AND UserType = 'Standard'
            LIMIT 1
        ];

        String runSuffix = String.valueOf(Datetime.now().getTime());
        User user = new User(
            Username = 'tl.thread.' + runSuffix + '@nav.no',
            LastName = 'TLNoAccess',
            Email = 'tl.thread.' + runSuffix + '@nav.no',
            Alias = 'tltst',
            CommunityNickname = 'tltst' + runSuffix,
            TimeZoneSidKey = 'Europe/Paris',
            LocaleSidKey = 'no_NO',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'no',
            ProfileId = profile.Id
        );
        insert user;
        return user;
    }

    @IsTest
    static void getAllTjenesteleverandorThreadsReturnsOnlyRelevantThreads() {
        Id accessibleThreadId = getAccessibleThreadId();
        Id inaccessibleThreadId = getInaccessibleThreadId();

        Test.startTest();
        List<Thread__c> threads = HOT_TLThreadlistController.getAllTjenesteleverandorThreads();
        Test.stopTest();

        Set<Id> returnedIds = new Set<Id>();
        for (Thread__c threadRecord : threads) {
            returnedIds.add(threadRecord.Id);
            System.assert(
                threadRecord.CRM_Type__c == 'HOT_TJENESTELEVERANDOR-FORMIDLER' ||
                    threadRecord.CRM_Type__c == 'HOT_TJENESTELEVERANDOR-TOLK',
                'Only tjenesteleverandor thread types should be returned.'
            );
        }

        System.assert(returnedIds.contains(accessibleThreadId), 'Expected accessible TL thread to be returned.');
        System.assert(returnedIds.contains(inaccessibleThreadId), 'Expected TL thread with message to be returned.');
    }

    @IsTest
    static void markThreadAsReadByTLMarksUnreadAccessibleThread() {
        Id accessibleThreadId = getAccessibleThreadId();

        Test.startTest();
        HOT_TLThreadlistController.markThreadAsReadByTL(accessibleThreadId);
        Test.stopTest();

        Thread__c updatedThread = [
            SELECT HOT_ReadByTjenesteleverandor__c
            FROM Thread__c
            WHERE Id = :accessibleThreadId
            LIMIT 1
        ];
        System.assertEquals(
            true,
            updatedThread.HOT_ReadByTjenesteleverandor__c,
            'Accessible thread should be marked as read for service provider.'
        );
    }

    @IsTest
    static void markThreadAsReadByTLDoesNothingForNullThreadId() {
        Test.startTest();
        HOT_TLThreadlistController.markThreadAsReadByTL(null);
        Test.stopTest();

        System.assert(true, 'Method should return without exception for null thread id.');
    }

    @IsTest
    static void markThreadAsReadByTLDoesNothingWithoutAccess() {
        Id inaccessibleThreadId = getInaccessibleThreadId();
        User nonAdminUser = createNonAdminUser();

        Test.startTest();
        System.runAs(nonAdminUser) {
            HOT_TLThreadlistController.markThreadAsReadByTL(inaccessibleThreadId);
        }
        Test.stopTest();

        Thread__c threadAfterCall = [
            SELECT HOT_ReadByTjenesteleverandor__c
            FROM Thread__c
            WHERE Id = :inaccessibleThreadId
            LIMIT 1
        ];
        System.assertEquals(
            false,
            threadAfterCall.HOT_ReadByTjenesteleverandor__c,
            'Thread should stay unread when user has no access.'
        );
    }

    @IsTest
    static void getServiceAppointmentDetailsReturnsNullForNullInput() {
        Test.startTest();
        ServiceAppointment details = HOT_TLThreadlistController.getServiceAppointmentDetails(null);
        Test.stopTest();

        System.assertEquals(null, details, 'Expected null when record id is null.');
    }

    @IsTest
    static void getServiceAppointmentDetailsReturnsRequestedAppointment() {
        Id serviceAppointmentId = getServiceAppointmentId();

        Test.startTest();
        ServiceAppointment details = HOT_TLThreadlistController.getServiceAppointmentDetails(
            (String) serviceAppointmentId
        );
        Test.stopTest();

        System.assertEquals(serviceAppointmentId, details.Id, 'Expected the requested service appointment details.');
        System.assertEquals('TL Thread List Appointment', details.Subject, 'Expected selected fields to be populated.');
    }
}
