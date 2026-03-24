public with sharing class HOT_MobileThreadListcontroller {
    @AuraEnabled(cacheable=false)
    public static List<Thread__c> getThreads() {
        String searchString = '%' + UserInfo.getUserId() + '%';
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
                HOT_AppointmentStartTime__c,
                CRM_Thread_Type__c
            FROM Thread__c
            WHERE
                (CRM_Related_Object__c IN :HOT_MobileThreadListcontroller.getRelatedWorkOrderIds()
                AND CRM_Number_of_Messages__c > 0
                AND HOT_IsEmployeeThread__c = TRUE)
                OR (HOT_ParticipantIds__c LIKE :searchString
                AND CRM_Number_of_Messages__c > 0)
            ORDER BY CRM_Number_of_unread_Messages__c DESC, CRM_Registered_Datetime_Formula__c DESC
        ];

        return threads;
    }
    private static Set<Id> getRelatedWorkOrderIds() {
        List<ServiceAppointment> serviceAppointments = [
            SELECT Id, HOT_WorkOrderLineItem__r.WorkOrderId
            FROM ServiceAppointment
            WHERE
                Id IN (
                    SELECT ServiceAppointment__c
                    FROM HOT_InterestedResource__c
                    WHERE
                        ServiceResource__r.RelatedRecordId = :UserInfo.getUserId()
                        AND (Status__c = 'Assigned'
                        OR Status__c = 'Reserved')
                )
        ];

        Set<Id> workOrderIds = new Set<Id>();
        for (ServiceAppointment sa : serviceAppointments) {
            workOrderIds.add(sa.HOT_WorkOrderLineItem__r.WorkOrderId);
        }
        return workOrderIds;
    }
}
