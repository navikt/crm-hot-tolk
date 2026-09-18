public without sharing class HOT_TLThreadlistController {
    @AuraEnabled(cacheable=false)
    public static List<Thread__c> getAllTjenesteleverandorThreads() {
        List<Thread__c> threads = [
            SELECT
                Id,
                OwnerId,
                HOT_Subject__c,
                CRM_Type__c,
                CRM_Related_Object__c,
                CRM_Number_of_unread_Messages__c,
                HOT_Thread_read_by__c,
                CRM_Registered_Datetime_Formula__c,
                CRM_Latest_Message_Datetime__c,
                HOT_AppointmentStartTime__c,
                CRM_Thread_Type__c,
                HOT_ServiceAppointment__r.HOT_TjenesteleverandorStatus__c,
                HOT_ReadByTjenesteleverandor__c,
                HOT_TLDispatcher__c
            FROM Thread__c
            WHERE
                (CRM_Type__c = 'HOT_TJENESTELEVERANDOR-FORMIDLER'
                OR CRM_Type__c = 'HOT_TJENESTELEVERANDOR-TOLK')
                AND CRM_Number_of_Messages__c > 0
            ORDER BY CRM_Number_of_unread_Messages__c DESC, CRM_Registered_Datetime_Formula__c DESC
        ];

        return threads;
    }

    @AuraEnabled
    public static void markThreadAsReadByTL(Id threadId) {
        if (threadId == null) {
            return;
        }

        if (!HOT_ThreadDetailController.checkAccess(threadId)) {
            return;
        }

        try {
            Thread__c thread = [
                SELECT Id, HOT_ReadByTjenesteleverandor__c
                FROM Thread__c
                WHERE Id = :threadId
                LIMIT 1
            ];

            if (thread.HOT_ReadByTjenesteleverandor__c) {
                return;
            }

            thread.HOT_ReadByTjenesteleverandor__c = true;
            update thread;
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
            logger.publishSynch();
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=false)
    public static ServiceAppointment getServiceAppointmentDetails(String recordId) {
        if (recordId != null) {
            ServiceAppointment serviceAppointment = [
                SELECT
                    AppointmentNumber,
                    HOT_AssignmentType__c,
                    HOT_Request__r.Account__r.CRM_Person__r.HOT_MobilePhone__c,
                    HOT_Request__r.Account__r.CRM_Person__r.INT_Confidential__c,
                    HOT_Request__r.Account__r.Name,
                    HOT_WorkTypeName__c,
                    HOT_Request__r.Account__r.CRM_Person__r.INT_Sex__c,
                    HOT_Request__r.Account__r.CRM_Person__r.CRM_AgeNumber__c,
                    SchedEndTime,
                    SchedStartTime,
                    toLabel(Status),
                    Subject,
                    HOT_Interpreters__c
                FROM ServiceAppointment
                WHERE Id = :recordId
            ];
            return serviceAppointment;
        } else {
            return null;
        }
    }
    @AuraEnabled
    public static Map<String, Integer> getNumberOfUnreadThreads() {
        Id currentUserId = UserInfo.getUserId();
        List<Thread__c> allUnreadThreads = [
            SELECT Id, HOT_TLDispatcher__c
            FROM Thread__c
            WHERE HOT_ReadByTjenesteleverandor__c = FALSE
        ];

        Integer myUnreadCount = 0;

        for (Thread__c thread : allUnreadThreads) {
            if (thread.HOT_TLDispatcher__c == currentUserId) {
                myUnreadCount++;
            }
        }
        return new Map<String, Integer>{ 'allUnread' => allUnreadThreads.size(), 'myUnread' => myUnreadCount };
    }
}
