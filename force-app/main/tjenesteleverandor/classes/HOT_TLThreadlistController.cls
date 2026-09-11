public with sharing class HOT_TLThreadlistController {
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
                HOT_ServiceAppointment__r.HOT_TjenesteleverandorStatus__c
            FROM Thread__c
            WHERE
                (CRM_Type__c = 'HOT_TJENESTELEVERANDOR-FORMIDLER'
                OR CRM_Type__c = 'HOT_TJENESTELEVERANDOR-TOLK')
                AND CRM_Number_of_Messages__c > 0
            ORDER BY CRM_Number_of_unread_Messages__c DESC, CRM_Registered_Datetime_Formula__c DESC
        ];

        return threads;
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
}
