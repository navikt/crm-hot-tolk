public without sharing class HOT_ServiceAppointmentMessageController {
    @AuraEnabled(cacheable=true)
    public static List<HOT_ServiceAppointmentMessage__c> getMessages(Id recordId) {
        if (recordId == null || recordId.getSObjectType() != ServiceAppointment.SObjectType) {
            throw new AuraHandledException('Ikke en gyldig oppdrags-ID.');
        }

        if (!HOT_CheckPermissions.isFormidlerOrAdmin()) {
            List<AssignedResource> assignedResources = [
                SELECT Id
                FROM AssignedResource
                WHERE ServiceAppointmentId = :recordId AND ServiceResource.RelatedRecordId = :UserInfo.getUserId()
                LIMIT 1
            ];
            if (assignedResources.isEmpty()) {
                throw new AuraHandledException('Fant ikke oppdraget, eller du mangler tilgang.');
            }
        }

        List<ServiceAppointment> serviceAppointments = [
            SELECT HOT_Request__c, HOT_WorkOrderID__c
            FROM ServiceAppointment
            WHERE Id = :recordId
        ];
        if (serviceAppointments.isEmpty()) {
            throw new AuraHandledException('Fant ikke oppdraget, eller du mangler tilgang.');
        }

        Id requestId = serviceAppointments[0].HOT_Request__c;
        Id workOrderId = String.isBlank(serviceAppointments[0].HOT_WorkOrderID__c)
            ? null
            : Id.valueOf(serviceAppointments[0].HOT_WorkOrderID__c);
        if (requestId == null && workOrderId == null) {
            return new List<HOT_ServiceAppointmentMessage__c>();
        }

        return [
            SELECT Id, Message__c, CreatedDate, CreatedBy.Name
            FROM HOT_ServiceAppointmentMessage__c
            WHERE
                (Request__c != NULL
                AND Request__c = :requestId)
                OR (WorkOrder__c != NULL
                AND WorkOrder__c = :workOrderId)
            ORDER BY CreatedDate DESC, Id DESC
        ];
    }
}
