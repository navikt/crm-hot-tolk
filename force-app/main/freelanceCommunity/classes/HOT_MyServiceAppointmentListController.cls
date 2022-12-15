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
        ServiceAppointment sa= [
            SELECT Status, HOT_CanceledByInterpreter__c
            FROM ServiceAppointment
            WHERE Id = :recordId
        ];
        return sa;
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
                AppointmentNumber,
                Subject,
                Description,
                toLabel(Status),
                ParentRecordId,
                HOT_AddressFormated__c,
                EarliestStartTime,
                DueDate,
                HOT_AssignedResourceId__c,
                HOT_WorkTypeName__c,
                SchedStartTime,
                SchedEndTime,
                ActualStartTime,
                ActualEndTime,
                HOT_TermsOfAgreement__c,
                City,
                ServiceTerritory.Name,
                HOT_ServiceTerritoryName__c,
                HOT_ServiceTerritoryDeveloperName__c,
                HOT_DegreeOfHearingAndVisualImpairment__c,
                HOT_HapticCommunication__c,
                HOT_Escort__c,
                HOT_AssignmentType__c,
                HOT_FreelanceSubject__c,
                HOT_DelPol_IsHideFilesFromFreelance__c,
                HOT_DelPol_ToHideRecord__c,
                HOT_Dispatcher__c,
                HOT_RequestNumber__c,
                HOT_IsSerieoppdrag__c,
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
    @AuraEnabled(cacheable=true)
    public static String getThreadFreelanceId(String serviceAppointmentId) {
         String Id='';
        ServiceAppointment serviceAppointment=[SELECT HOT_WorkOrderLineItem__r.WorkOrderId FROM ServiceAppointment WHERE Id=:serviceAppointmentId];
        try{

            Thread__c thread = [SELECT Id FROM Thread__c WHERE CRM_Related_Object__c=:serviceAppointment.HOT_WorkOrderLineItem__r.WorkOrderId LIMIT 1];
             if (thread.Id != null) {
               Id=thread.Id;
               return Id;
             }
             
            return Id;
        }catch(Exception E){

        }
        return Id;
    }
}
