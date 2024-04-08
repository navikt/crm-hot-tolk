public without sharing class HOT_ThreadListController {
    @AuraEnabled(cacheable=true)
    public static List<Thread__c> getMyThreads() {
        List<Id> workOrderIds = new List<Id>();
        User user = [SELECT Id, AccountId FROM User WHERE Id = :UserInfo.getUserId()];
        List<HOT_Request__c> bestillerSamtaler = [
            SELECT Id
            FROM HOT_Request__c
            WHERE Orderer__c = :user.AccountId AND IsAccountEqualOrderer__c = FALSE
        ];

        Set<Id> bestillerSamtalerId = new Set<Id>();
        for (HOT_Request__c request : bestillerSamtaler) {
            bestillerSamtalerId.add(request.Id);
        }

        List<Thread__c> threads = [
            SELECT
                Id,
                HOT_Subject__c,
                CRM_Type__c,
                CRM_Related_Object__c,
                CRM_Number_of_unread_Messages__c,
                HOT_Thread_read_by__c,
                CRM_Registered_Datetime_Formula__c,
                CRM_Latest_Message_Datetime__c,
                HOT_AppointmentStartTime__c
            FROM Thread__c
            WHERE
                (CRM_Account__c = :user.AccountId
                AND CRM_Type__c = 'HOT_BRUKER-FORMIDLER'
                AND CRM_Number_of_Messages__c > 0
                AND HOT_IsDone__c = FALSE)
                OR (CRM_Related_Object__c IN :bestillerSamtalerId
                AND CRM_Type__c = 'HOT_BESTILLER-FORMIDLER'
                AND CRM_Number_of_Messages__c > 0
                AND HOT_IsDone__c = FALSE)
                OR (CRM_Account__c = :user.AccountId
                AND CRM_Type__c = 'HOT_BRUKER-TOLK'
                AND CRM_Number_of_Messages__c > 0
                AND HOT_IsDone__c = FALSE)
                OR (CRM_Account__c = :user.AccountId
                AND CRM_Type__c = 'HOT_BRUKER-BESTILLER'
                AND CRM_Number_of_Messages__c > 0
                AND HOT_IsDone__c = FALSE)
                OR (CRM_Related_Object__c IN :bestillerSamtalerId
                AND CRM_Type__c = 'HOT_BRUKER-BESTILLER'
                AND CRM_Number_of_Messages__c > 0
                AND HOT_IsDone__c = FALSE)
            ORDER BY CRM_Number_of_unread_Messages__c DESC, CRM_Registered_Datetime_Formula__c DESC
        ];

        return threads;
    }
    @AuraEnabled(cacheable=false)
    public static List<Thread__c> getMyThreadsIR() {
        List<Id> workOrderIds = new List<Id>();
        User user = [SELECT Id, AccountId FROM User WHERE Id = :UserInfo.getUserId()];
        List<ServiceResource> serviceResources = [SELECT Id FROM ServiceResource WHERE AccountId = :user.AccountId];
        if (serviceResources.size() > 0) {
            List<ServiceAppointment> serviceAppointments = [
                SELECT Id, HOT_WorkOrderLineItem__r.WorkOrderId
                FROM ServiceAppointment
                WHERE
                    Id IN (
                        SELECT ServiceAppointment__c
                        FROM HOT_InterestedResource__c
                        WHERE ServiceResource__c = :serviceResources[0].Id AND Status__c = 'Assigned'
                    )
            ];

            Map<Id, ServiceAppointment> saMap = new Map<Id, ServiceAppointment>(serviceAppointments);

            for (ServiceAppointment sa : saMap.values()) {
                workOrderIds.add(sa.HOT_WorkOrderLineItem__r.WorkOrderId);
            }
        }
        List<HOT_Request__c> bestillerSamtaler = [
            SELECT Id
            FROM HOT_Request__c
            WHERE Orderer__c = :user.AccountId AND IsAccountEqualOrderer__c = FALSE
        ];

        Set<Id> bestillerSamtalerId = new Set<Id>();
        for (HOT_Request__c request : bestillerSamtaler) {
            bestillerSamtalerId.add(request.Id);
        }

        List<Thread__c> threads = [
            SELECT
                Id,
                HOT_Subject__c,
                CRM_Type__c,
                CRM_Related_Object__c,
                CRM_Number_of_unread_Messages__c,
                HOT_Thread_read_by__c,
                CRM_Registered_Datetime_Formula__c
            FROM Thread__c
            WHERE
                CRM_Account__c = :user.AccountId
                AND CRM_Type__c = 'HOT_TOLK-FORMIDLER'
                AND CRM_Number_of_Messages__c > 0
            ORDER BY CRM_Number_of_unread_Messages__c DESC, CRM_Registered_Datetime_Formula__c DESC
        ];

        return threads;
    }
    @AuraEnabled(cacheable=true)
    public static List<Thread__c> getMyThreadsFreelance() {
        List<Id> workOrderIds = new List<Id>();
        User user = [SELECT Id, AccountId FROM User WHERE Id = :UserInfo.getUserId()];
        List<ServiceResource> serviceResources = [SELECT Id FROM ServiceResource WHERE AccountId = :user.AccountId];
        if (serviceResources.size() > 0) {
            List<ServiceAppointment> serviceAppointments = [
                SELECT Id, HOT_WorkOrderLineItem__r.WorkOrderId
                FROM ServiceAppointment
                WHERE
                    Id IN (
                        SELECT ServiceAppointment__c
                        FROM HOT_InterestedResource__c
                        WHERE ServiceResource__c = :serviceResources[0].Id AND Status__c = 'Assigned'
                    )
            ];

            Map<Id, ServiceAppointment> saMap = new Map<Id, ServiceAppointment>(serviceAppointments);

            for (ServiceAppointment sa : saMap.values()) {
                workOrderIds.add(sa.HOT_WorkOrderLineItem__r.WorkOrderId);
            }
        }
        List<Thread__c> threads = [
            SELECT
                Id,
                HOT_Subject__c,
                CRM_Type__c,
                HOT_IsEmployeeThread__c,
                CRM_Related_Object__c,
                CRM_Number_of_unread_Messages__c,
                HOT_Thread_read_by__c,
                CRM_Registered_Datetime_Formula__c,
                CRM_Latest_Message_Datetime__c,
                HOT_AppointmentStartTime__c
            FROM Thread__c
            WHERE
                (CRM_Related_Object__c IN :workOrderIds
                AND CRM_Number_of_Messages__c > 0
                AND HOT_IsDone__c = FALSE
                AND HOT_IsEmployeeThread__c = FALSE)
                OR (CRM_Account__c = :user.AccountId
                AND CRM_Type__c = 'HOT_TOLK-FORMIDLER'
                AND CRM_Number_of_Messages__c > 0
                AND HOT_IsDone__c = FALSE
                AND HOT_IsEmployeeThread__c = FALSE)
                OR (CRM_Account__c = :user.AccountId
                AND CRM_Type__c = 'HOT_TOLK-RESSURSKONTOR'
                AND CRM_Number_of_Messages__c > 0
                AND HOT_IsEmployeeThread__c = FALSE)
            ORDER BY CRM_Number_of_unread_Messages__c DESC, CRM_Registered_Datetime_Formula__c DESC
        ];

        return threads;
    }
}
