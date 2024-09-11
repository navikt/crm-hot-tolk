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
        Thread__c thread = [SELECT Id, CRM_Related_Object__c, CRM_Thread_Type__c FROM Thread__c WHERE Id = :threadId];
        Id relatedObjectId = thread.CRM_Related_Object__c;
        String objectType = String.valueOf(relatedObjectId.getsobjecttype());
        if (objectType == 'WorkOrder') {
            User user = [SELECT Id, AccountId FROM User WHERE Id = :UserInfo.getUserId()];
            WorkOrder wo = [
                SELECT Id, HOT_Request__r.Account__c
                FROM WorkOrder
                WHERE Id = :thread.CRM_Related_Object__c
            ];
            List<ServiceResource> serviceResource = [
                SELECT Id, HOT_IsEmployedInterpreter__c
                FROM ServiceResource
                WHERE RelatedRecordId = :user.Id
            ];
            if (!serviceResource.isEmpty()) {
                List<AssignedResource> arList = [
                    SELECT ServiceResourceId
                    FROM AssignedResource
                    WHERE
                        ServiceAppointment.HOT_WorkOrderLineItem__r.WorkOrderId = :thread.CRM_Related_Object__c
                        AND ServiceResourceId = :serviceResource[0].Id
                ];
                if (arList.size() != 0) {
                    grantAccess = true;
                }
            } else if (wo.HOT_Request__r.Account__c == user.AccountId) {
                grantAccess = true;
            }
        }
        if (objectType == 'HOT_WageClaim__c') {
            User user = [SELECT Id, AccountId FROM User WHERE Id = :UserInfo.getUserId()];
            List<ServiceResource> serviceResource = [SELECT Id FROM ServiceResource WHERE AccountId = :user.AccountId];
            HOT_WageClaim__c wc = [
                SELECT Id, ServiceResource__c
                FROM HOT_WageClaim__c
                WHERE Id = :thread.CRM_Related_Object__c
            ];
            if (serviceResource.size() != 0 || wc.ServiceResource__c == serviceResource[0].Id) {
                grantAccess = true;
            }
        }
        if (objectType == 'HOT_InterestedResource__c') {
            User user = [SELECT Id, AccountId FROM User WHERE Id = :UserInfo.getUserId()];
            if (user.AccountId != null) {
                ServiceResource serviceResource = [SELECT Id FROM ServiceResource WHERE AccountId = :user.AccountId];
                List<HOT_InterestedResource__c> irList = [
                    SELECT Id
                    FROM HOT_InterestedResource__c
                    WHERE Id = :thread.CRM_Related_Object__c AND ServiceResource__c = :serviceResource.Id
                ];
                if (irList.size() != 0) {
                    grantAccess = true;
                }
            }
        }
        if (objectType == 'ServiceAppointment') {
            User user = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
            List<ServiceResource> srList = [SELECT Id FROM ServiceResource WHERE RelatedRecordId = :user.Id];
            if (srList.size() != 0) {
                List<HOT_InterestedResource__c> irList = [
                    SELECT Id
                    FROM HOT_InterestedResource__c
                    WHERE
                        ServiceAppointment__c = :thread.CRM_Related_Object__c
                        AND ServiceResource__c = :srList[0].Id
                        AND (Status__c = 'Assigned'
                        OR Status__c = 'Canceled'
                        OR Status__c = 'Canceled by Interpreter')
                ];
                List<AssignedResource> arList = [
                    SELECT Id
                    FROM AssignedResource
                    WHERE ServiceResourceId = :srList[0].Id AND ServiceAppointmentId = :thread.CRM_Related_Object__c
                ];
                if (irList.size() != 0 || arList.size() != 0) {
                    grantAccess = true;
                }
            }
        }

        if (objectType == 'HOT_Request__c') {
            HOT_Request__c request = [
                SELECT Id, Orderer__c, Account__c
                FROM HOT_Request__c
                WHERE Id = :thread.CRM_Related_Object__c
            ];
            User user = [SELECT Id, AccountId FROM User WHERE Id = :UserInfo.getUserId()];
            if (user.AccountId != null) {
                if (request.Account__c == user.AccountId || request.Orderer__c == user.AccountId) {
                    grantAccess = true;
                }
            }
        }
        User user = [SELECT Id, FirstName, Profile.Name FROM User WHERE Id = :UserInfo.getUserId()];
        if (user.Profile.Name == 'HOT Tolk Formidler' && thread.CRM_Thread_Type__c.startsWith('HOT_')) {
            grantAccess = true;
        }
        return grantAccess;
    }
}
