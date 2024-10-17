public without sharing class HOT_MyServiceAppointmentListController {
    @AuraEnabled(cacheable=true)
    public static List<WorkOrderLineItem> getParentWorkOrderLineItems() {
        List<ServiceAppointment> serviceAppointments = [
            SELECT ParentRecordId
            FROM ServiceAppointment
            WHERE HOT_AssignedResourceId__c = :UserInfo.getUserId()
        ];
        List<Id> parentRecordIds = new List<Id>();
        for (ServiceAppointment sa : serviceAppointments) {
            parentRecordIds.add(sa.ParentRecordId);
        }
        List<WorkOrderLineItem> workOrderLineItems = [
            SELECT Id, WorkOrder.HOT_Request__r.AssignmentType__c
            FROM WorkOrderLineItem
            WHERE Id IN :parentRecordIds
        ];
        return workOrderLineItems;
    }
    @AuraEnabled(cacheable=true)
    public static ServiceAppointment getServiceAppointment(String recordId) {
        ServiceAppointment sa = [
            SELECT Status, HOT_CanceledByInterpreter__c
            FROM ServiceAppointment
            WHERE Id = :recordId
        ];
        return sa;
    }
    @AuraEnabled(cacheable=false)
    public static Boolean checkAccessToSA(String saId) {
        Boolean hasAccess = false;
        ServiceResource serviceResource = [
            SELECT Id
            FROM ServiceResource
            WHERE RelatedRecordId = :UserInfo.getUserId()
        ];
        if (serviceResource.Id != null) {
            List<AssignedResource> ar = [
                SELECT Id
                FROM AssignedResource
                WHERE ServiceAppointmentId = :saId AND ServiceResourceId = :serviceResource.Id
            ];
            if (ar.size() > 0) {
                hasAccess = true;
            }
        }
        return hasAccess;
    }
    @AuraEnabled
    public static ServiceAppointment getServiceAppointmentDetails(String recordId) {
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        List<ServiceResource> serviceResource = [
            SELECT Id, Name
            FROM ServiceResource
            WHERE RelatedRecordId = :currentUser.Id
        ];
        List<HOT_InterestedResource__c> ir = [
            SELECT Id
            FROM HOT_InterestedResource__c
            WHERE ServiceAppointment__c = :recordId AND ServiceResource__c IN :serviceResource
        ];
        if (ir.size() != 0) {
            ServiceAppointment serviceAppointment = [
                SELECT
                    AppointmentNumber,
                    ActualEndTime,
                    ActualStartTime,
                    Description,
                    DueDate,
                    EarliestStartTime,
                    HOT_AddressFormated__c,
                    HOT_AssignmentType__c,
                    HOT_DegreeOfHearingAndVisualImpairment__c,
                    HOT_DelPol_IsHideFilesFromFreelance__c,
                    HOT_DelPol_ToHideRecord__c,
                    HOT_Dispatcher__c,
                    HOT_Escort__c,
                    HOT_FreelanceSubject__c,
                    HOT_HapticCommunication__c,
                    HOT_IsSerieoppdrag__c,
                    HOT_ReleaseDate__c,
                    HOT_ServiceResource__c,
                    HOT_ReleasedBy__c,
                    HOT_Request__r.Account__r.CRM_Person__r.INT_KrrMobilePhone__c,
                    HOT_Request__r.Account__r.Name,
                    HOT_Request__r.Orderer__r.CRM_Person__r.INT_KrrMobilePhone__c,
                    HOT_Request__r.OwnerName__c,
                    HOT_Request__r.IsNotNotifyAccount__c,
                    HOT_RequestNumber__c,
                    HOT_ServiceTerritoryDeveloperName__c,
                    HOT_ServiceTerritoryName__c,
                    HOT_TermsOfAgreement__c,
                    HOT_WorkTypeName__c,
                    HOT_Request__r.Account__r.CRM_Person__r.HOT_Gender__c,
                    HOT_Request__r.Account__r.CRM_Person__r.CRM_AgeNumber__c,
                    SchedEndTime,
                    SchedStartTime,
                    Status,
                    Subject,
                    HOT_Interpreters__c,
                    HOT_TotalNumberOfInterpreters__c
                FROM ServiceAppointment
                WHERE Id = :recordId
            ];
            return serviceAppointment;
        } else {
            return null;
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<ServiceAppointment> getMyServiceAppointments() {
        ServiceResource serviceResource = [
            SELECT Id, Name
            FROM ServiceResource
            WHERE RelatedRecordId = :UserInfo.getUserId()
        ];
        List<AssignedResource> assignedResources = [
            SELECT ServiceAppointmentId, ServiceResourceId
            FROM AssignedResource
            WHERE ServiceResourceId = :serviceResource.Id
        ];
        List<Id> serviceAppointmentIds = new List<Id>();
        for (AssignedResource ar : assignedResources) {
            serviceAppointmentIds.add(ar.ServiceAppointmentId);
        }
        List<ServiceAppointment> serviceAppointments = [
            SELECT
                ActualEndTime,
                ActualStartTime,
                AppointmentNumber,
                City,
                Description,
                DueDate,
                EarliestStartTime,
                HOT_AddressFormated__c,
                HOT_AssignedResourceId__c,
                HOT_AssignmentType__c,
                HOT_DegreeOfHearingAndVisualImpairment__c,
                HOT_DelPol_IsHideFilesFromFreelance__c,
                HOT_DelPol_ToHideRecord__c,
                HOT_Dispatcher__c,
                HOT_Escort__c,
                HOT_FreelanceSubject__c,
                HOT_HapticCommunication__c,
                HOT_Interpreters__c,
                HOT_IsSerieoppdrag__c,
                HOT_ReleaseDate__c,
                HOT_ReleasedBy__c,
                HOT_Request__r.IsNotNotifyAccount__c,
                HOT_RequestNumber__c,
                HOT_ServiceTerritoryDeveloperName__c,
                HOT_Request__r.Account__r.CRM_Person__r.INT_KrrMobilePhone__c,
                HOT_Request__r.Account__r.Name,
                HOT_Request__r.Orderer__r.CRM_Person__r.INT_KrrMobilePhone__c,
                HOT_Request__r.Account__r.CRM_Person__r.HOT_Gender__c,
                HOT_Request__r.Account__r.CRM_Person__r.CRM_AgeNumber__c,
                HOT_Request__r.OwnerName__c,
                HOT_NavEmployeeName__c,
                HOT_ServiceTerritoryName__c,
                HOT_TermsOfAgreement__c,
                HOT_TotalNumberOfInterpreters__c,
                HOT_WorkTypeName__c,
                ParentRecordId,
                SchedEndTime,
                SchedStartTime,
                ServiceTerritory.Name,
                Subject,
                toLabel(Status),
                (
                    SELECT Id, HOT_TermsOfAgreement__c
                    FROM ServiceAppointment.InterestedResources__r
                    WHERE ServiceResource__c = :serviceResource.Id
                )
            FROM ServiceAppointment
            WHERE
                Id IN :serviceAppointmentIds
                AND Status IN ('Dispatched', 'Completed')
                AND HOT_DelPol_ToHideRecord__c = FALSE
            ORDER BY SchedStartTime ASC
        ];
        return serviceAppointments;
    }
    @AuraEnabled
    public static String getThreadFreelanceId(String serviceAppointmentId) {
        String Id = '';
        ServiceAppointment serviceAppointment = [
            SELECT HOT_WorkOrderLineItem__r.WorkOrderId
            FROM ServiceAppointment
            WHERE Id = :serviceAppointmentId
        ];
        try {
            Thread__c thread = [
                SELECT Id
                FROM Thread__c
                WHERE
                    CRM_Related_Object__c = :serviceAppointment.HOT_WorkOrderLineItem__r.WorkOrderId
                    AND CRM_Thread_Type__c = 'HOT_BRUKER-TOLK'
                LIMIT 1
            ];
            if (thread.Id != null) {
                Id = thread.Id;
                return Id;
            }

            return Id;
        } catch (Exception E) {
        }
        return Id;
    }
    @AuraEnabled
    public static String getThreadServiceAppointmentId(String serviceAppointmentId) {
        String Id = '';
        try {
            Id userId = UserInfo.getUserId();
            List<ServiceResource> serviceResource = [
                SELECT Id, Name
                FROM ServiceResource
                WHERE RelatedRecordId = :userId
            ];

            HOT_InterestedResource__c interestedResource = [
                SELECT Id, Status__c, ServiceResource__c, ServiceAppointment__c
                FROM HOT_InterestedResource__c
                WHERE ServiceResource__c IN :serviceResource AND ServiceAppointment__c = :serviceAppointmentId
            ];

            if (interestedResource.Status__c == 'Assigned') {
                Thread__c thread = [
                    SELECT Id
                    FROM Thread__c
                    WHERE CRM_Related_Object__c = :serviceAppointmentId
                    LIMIT 1
                ];
                if (thread.Id != null) {
                    Id = thread.Id;
                    return Id;
                }

                return Id;
            } else {
                Thread__c thread = [
                    SELECT Id
                    FROM Thread__c
                    WHERE CRM_Related_Object__c = :interestedResource.Id
                    LIMIT 1
                ];
                if (thread.Id != null) {
                    Id = thread.Id;
                    return Id;
                }

                return Id;
            }
        } catch (Exception E) {
        }
        return Id;
    }
    @AuraEnabled
    public static String getOwnerName(String serviceAppointmentId) {
        String ownerName = '';
        ServiceAppointment sa = [
            SELECT HOT_Request__r.OwnerName__c
            FROM ServiceAppointment
            WHERE Id = :serviceAppointmentId
        ];
        if (sa.HOT_Request__r.OwnerName__c != null) {
            ownerName = sa.HOT_Request__r.OwnerName__c;
        }
        return ownerName;
    }
    @AuraEnabled
    public static String getThreadInterpretersId(String serviceAppointmentId) {
        String Id = '';
        ServiceAppointment serviceAppointment = [
            SELECT HOT_WorkOrderLineItem__r.WorkOrderId
            FROM ServiceAppointment
            WHERE Id = :serviceAppointmentId
        ];
        try {
            Thread__c thread = [
                SELECT Id
                FROM Thread__c
                WHERE
                    CRM_Related_Object__c = :serviceAppointment.HOT_WorkOrderLineItem__r.WorkOrderId
                    AND CRM_Thread_Type__c = 'HOT_TOLK-TOLK'
                LIMIT 1
            ];
            if (thread.Id != null) {
                Id = thread.Id;
                return Id;
            }

            return Id;
        } catch (Exception E) {
        }
        return Id;
    }
}
