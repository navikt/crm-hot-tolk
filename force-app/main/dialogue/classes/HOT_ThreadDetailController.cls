public without sharing class HOT_ThreadDetailController {
    @AuraEnabled(cacheable=true)
    public static Thread__c getThreadDetails(Id recordId) {
        Boolean access = checkAccess(recordId);
        if (access == true) {
            Thread__c thread = [
                SELECT Id, HOT_Subject__c, CRM_Is_Closed__c, CRM_Thread_Type__c, CRM_Related_Object__c
                FROM Thread__c
                WHERE Id = :recordId
                LIMIT 1
            ];
            return thread;
        } else {
            throw new AuraHandledException('No access');
        }
    }
    @AuraEnabled(cacheable=false)
    public static boolean checkAccess(Id threadId) {
        Boolean grantAccess = false;
        Thread__c thread = [
            SELECT Id, CRM_Related_Object__c, CRM_Thread_Type__c, HOT_ServiceResource__r.RelatedRecordId
            FROM Thread__c
            WHERE Id = :threadId
        ];
        User user = [SELECT Id, AccountId, Profile.Name FROM User WHERE Id = :UserInfo.getUserId()];
        if (!String.isBlank(thread.CRM_Related_Object__c)) {
            String objectType = String.valueOf(((Id) thread.CRM_Related_Object__c).getsobjecttype());
            if (objectType == 'WorkOrder') {
                WorkOrder wo = [
                    SELECT Id, HOT_Request__r.Account__c
                    FROM WorkOrder
                    WHERE Id = :thread.CRM_Related_Object__c
                ];
                if (wo.HOT_Request__r.Account__c == user.AccountId) {
                    return true;
                } else {
                    List<AssignedResource> arList = [
                        SELECT Id
                        FROM AssignedResource
                        WHERE
                            ServiceAppointment.HOT_WorkOrderLineItem__r.WorkOrderId = :thread.CRM_Related_Object__c
                            AND ServiceResource.RelatedRecordId = :user.Id
                    ];
                    if (arList.size() > 0) {
                        return true;
                    }
                }
            }
            if (objectType == 'HOT_WageClaim__c') {
                HOT_WageClaim__c wc = [
                    SELECT Id, ServiceResource__r.RelatedRecordId
                    FROM HOT_WageClaim__c
                    WHERE Id = :thread.CRM_Related_Object__c
                ];
                if (wc.ServiceResource__r.RelatedRecordId == user.Id) {
                    return true;
                }
            }
            if (objectType == 'HOT_InterestedResource__c') {
                List<HOT_InterestedResource__c> irList = [
                    SELECT Id
                    FROM HOT_InterestedResource__c
                    WHERE Id = :thread.CRM_Related_Object__c AND ServiceResource__r.RelatedRecordId = :user.Id
                ];
                if (irList.size() > 0) {
                    return true;
                }
            }
            if (objectType == 'ServiceAppointment') {
                List<HOT_InterestedResource__c> irList = [
                    SELECT Id
                    FROM HOT_InterestedResource__c
                    WHERE
                        ServiceAppointment__c = :thread.CRM_Related_Object__c
                        AND ServiceResource__r.RelatedRecordId = :user.Id
                        AND (Status__c = 'Assigned'
                        OR Status__c = 'Canceled'
                        OR Status__c = 'Canceled by Interpreter'
                        OR Status__c = 'Reserved')
                ];
                List<AssignedResource> arList = [
                    SELECT Id
                    FROM AssignedResource
                    WHERE
                        ServiceResource.RelatedRecordId = :user.Id
                        AND ServiceAppointmentId = :thread.CRM_Related_Object__c
                ];
                if (irList.size() != 0 || arList.size() != 0) {
                    return true;
                }
            }

            if (objectType == 'HOT_Request__c') {
                HOT_Request__c request = [
                    SELECT Id, Orderer__c, Account__c
                    FROM HOT_Request__c
                    WHERE Id = :thread.CRM_Related_Object__c
                ];
                if (user.AccountId != null) {
                    if (request.Account__c == user.AccountId || request.Orderer__c == user.AccountId) {
                        return true;
                    }
                }
            }
        }
        List<GroupMember> groupMembers = [
            SELECT Id
            FROM GroupMember
            WHERE Group.DeveloperName = 'HOT_Tolk_Admin' AND Group.Type = 'Regular' AND UserOrGroupId = :user.Id
        ];

        if (
            (user.Profile.Name == 'HOT Tolk Formidler' || groupMembers.size() > 0) &&
            thread.CRM_Thread_Type__c.startsWith('HOT_')
        ) {
            return true;
        }
        //ansatt tolk tråder tilgang

        if (user.Id == thread.HOT_ServiceResource__r.RelatedRecordId) {
            return true;
        }

        return false;
    }
}
