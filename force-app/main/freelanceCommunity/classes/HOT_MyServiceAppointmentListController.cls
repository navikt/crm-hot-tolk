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
    @AuraEnabled
    public static ServiceAppointment getServiceAppointmentDetails(String recordId) {
      ServiceAppointment serviceAppointment= [
            SELECT  AppointmentNumber,
                Subject,
                SchedStartTime,
                SchedEndTime,
                EarliestStartTime,
                DueDate,
                ActualStartTime,
                ActualEndTime,
                HOT_AddressFormated__c,
                HOT_ServiceTerritoryName__c,
                Status,
                HOT_HapticCommunication__c,
                HOT_ServiceTerritoryDeveloperName__c,
                HOT_DegreeOfHearingAndVisualImpairment__c,
                HOT_WorkTypeName__c,
                HOT_TermsOfAgreement__c,
                HOT_Escort__c,
                HOT_AssignmentType__c,
                HOT_FreelanceSubject__c,
                HOT_DelPol_IsHideFilesFromFreelance__c,
                HOT_DelPol_ToHideRecord__c,
                HOT_Dispatcher__c,
                Description,
                HOT_RequestNumber__c,
                HOT_IsSerieoppdrag__c,
                HOT_Request__r.Account__r.Name,
                HOT_Request__r.Orderer__r.CRM_Person__r.INT_KrrMobilePhone__c,
                HOT_Request__r.Account__r.CRM_Person__r.INT_KrrMobilePhone__c
            FROM ServiceAppointment
            WHERE Id=:recordId
        ];
        return serviceAppointment;
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
                HOT_TotalNumberOfInterpreters__c,
                HOT_Escort__c,
                HOT_AssignmentType__c,
                HOT_FreelanceSubject__c,
                HOT_DelPol_IsHideFilesFromFreelance__c,
                HOT_DelPol_ToHideRecord__c,
                HOT_Dispatcher__c,
                HOT_RequestNumber__c,
                HOT_IsSerieoppdrag__c,
                HOT_Request__r.IsNotNotifyAccount__c,
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
         String Id='';
        ServiceAppointment serviceAppointment=[SELECT HOT_WorkOrderLineItem__r.WorkOrderId FROM ServiceAppointment WHERE Id=:serviceAppointmentId];
        try{

            Thread__c thread = [SELECT Id FROM Thread__c WHERE CRM_Related_Object__c=:serviceAppointment.HOT_WorkOrderLineItem__r.WorkOrderId AND CRM_Thread_Type__c='HOT_BRUKER-TOLK' LIMIT 1];
             if (thread.Id != null) {
               Id=thread.Id;
               return Id;
             }
             
            return Id;
        }catch(Exception E){

        }
        return Id;
    }
     @AuraEnabled
    public static String getThreadServiceAppointmentId(String serviceAppointmentId) {
         String Id='';
        try{

            Thread__c thread = [SELECT Id FROM Thread__c WHERE CRM_Related_Object__c=:serviceAppointmentId LIMIT 1];
             if (thread.Id != null) {
               Id=thread.Id;
               return Id;
             }
             
            return Id;
        }catch(Exception E){

        }
        return Id;
    }
    @AuraEnabled
    public static String getOrdererInformation(String serviceAppointmentId){
        String phonenumber='';
        ServiceAppointment sa=[SELECT HOT_Request__r.Orderer__r.CRM_Person__r.INT_KrrMobilePhone__c FROM ServiceAppointment WHERE Id=:serviceAppointmentId];
        if(sa.HOT_Request__r.Orderer__r.CRM_Person__r.INT_KrrMobilePhone__c!=null){
            phonenumber=sa.HOT_Request__r.Orderer__r.CRM_Person__r.INT_KrrMobilePhone__c;
        }
        return phoneNumber;
    }
    @AuraEnabled
    public static String getAccountPhonenumber(String serviceAppointmentId){
        String phonenumber='';
        ServiceAppointment sa=[SELECT HOT_Request__r.Account__r.Name, HOT_Request__r.Account__r.CRM_Person__r.INT_KrrMobilePhone__c FROM ServiceAppointment WHERE Id=:serviceAppointmentId];
        if(sa.HOT_Request__r.Account__r.CRM_Person__r.INT_KrrMobilePhone__c!=null){
            phonenumber=sa.HOT_Request__r.Account__r.CRM_Person__r.INT_KrrMobilePhone__c;
        }
        return phoneNumber;
    }
    @AuraEnabled
    public static String getAccountName(String serviceAppointmentId){
        String name = '';
        ServiceAppointment sa=[SELECT HOT_Request__r.Account__r.Name FROM ServiceAppointment WHERE Id=:serviceAppointmentId];
        if(sa.HOT_Request__r.Account__c!=null){
            Name=sa.HOT_Request__r.Account__r.Name;
        }
        return Name;
    }
     @AuraEnabled
    public static String getThreadInterpretersId(String serviceAppointmentId) {
         String Id='';
        ServiceAppointment serviceAppointment=[SELECT HOT_WorkOrderLineItem__r.WorkOrderId FROM ServiceAppointment WHERE Id=:serviceAppointmentId];
        try{

            Thread__c thread = [SELECT Id FROM Thread__c WHERE CRM_Related_Object__c=:serviceAppointment.HOT_WorkOrderLineItem__r.WorkOrderId AND CRM_Thread_Type__c='HOT_TOLK-TOLK' LIMIT 1];
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
