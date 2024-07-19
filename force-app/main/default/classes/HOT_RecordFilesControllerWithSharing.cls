public with sharing class HOT_RecordFilesControllerWithSharing {
    @AuraEnabled(cacheable=true)
    public static List<ContentDocument> getContentDocuments(String recordId, Boolean isGetAll) {
        if (recordId == null) {
            return new List<ContentDocument>{};
        }
        List<ServiceAppointment> serviceAppointments=[SELECT Id FROM ServiceAppointment WHERE HOT_WorkOrderLineItem__r.WorkOrderId=:recordId];
        Set<Id>saIds=new Set<Id>();
        for(ServiceAppointment sa : serviceAppointments){
            saIds.add(sa.Id);
        }
        List<ContentDocumentLink> contentDocumentLinks = [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :recordId OR LinkedEntityId IN :saIds
        ];

        List<Id> contentDocumentIds = new List<Id>();
        for (ContentDocumentLink contentDocumentLink : contentDocumentLinks) {
            contentDocumentIds.add(contentDocumentLink.ContentDocumentId);
        }

        if (!isGetAll) {
            contentDocumentIds = RecordFilesControllerWithSharing.getOnlyMyContentDocuments(contentDocumentIds);
        }

        List<ContentDocument> contentDocuments = [
            SELECT Id, FileType, CreatedDate, Title
            FROM ContentDocument
            WHERE Id IN :contentDocumentIds AND ContentAssetId = NULL
        ];
        return contentDocuments;
    }
}