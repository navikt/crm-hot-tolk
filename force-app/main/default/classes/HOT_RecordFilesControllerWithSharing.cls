public with sharing class HOT_RecordFilesControllerWithSharing {
    @AuraEnabled(cacheable=true)
    public static List<ContentDocument> getContentDocuments(String recordId, Boolean isGetAll) {
        if (recordId == null) {
            return new List<ContentDocument>{};
        }

        Set<Id> requestId = new Set<Id>();
        List<WorkOrder> workOrder = [SELECT Id, HOT_Request__c FROM WorkOrder WHERE Id = :recordId];
        for (WorkOrder wo : workOrder) {
            requestId.add(wo.HOT_Request__c);
        }

        List<ServiceAppointment> serviceAppointments = [
            SELECT Id
            FROM ServiceAppointment
            WHERE HOT_WorkOrderLineItem__r.WorkOrderId = :recordId
        ];
        Set<Id> saIds = new Set<Id>();
        for (ServiceAppointment sa : serviceAppointments) {
            saIds.add(sa.Id);
        }

        List<HOT_File__c> hotFiles = [SELECT Id FROM HOT_File__c WHERE Service_Appointment__c = :saIds];
        Set<Id> hotFileIds = new Set<Id>();
        for (HOT_File__c hf : hotFiles) {
            hotFileIds.add(hf.Id);
        }

        List<ContentDocumentLink> contentDocumentLinks = [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE
                LinkedEntityId = :recordId
                OR LinkedEntityId IN :saIds
                OR LinkedEntityId IN :requestId
                OR LinkedEntityId IN :hotFileIds
        ];

        List<Id> contentDocumentIds = new List<Id>();
        for (ContentDocumentLink contentDocumentLink : contentDocumentLinks) {
            contentDocumentIds.add(contentDocumentLink.ContentDocumentId);
        }

        if (!isGetAll) {
            contentDocumentIds = RecordFilesControllerWithSharing.getOnlyMyContentDocuments(contentDocumentIds);
        }

        List<ContentDocument> contentDocuments = [
            SELECT Id, FileType, CreatedDate, Title, LatestPublishedVersionId
            FROM ContentDocument
            WHERE Id IN :contentDocumentIds AND ContentAssetId = NULL
        ];
        return contentDocuments;
    }
}
