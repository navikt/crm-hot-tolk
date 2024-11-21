public with sharing class HOT_HotFilesController {
    @AuraEnabled
    public static Id getHotFileRecordId(Id serviceAppointmentId) {
        List<HOT_File__c> hotFilesList = [
            SELECT Id
            FROM HOT_File__c
            WHERE Service_Appointment__c = :serviceAppointmentId
            LIMIT 1
        ];
        System.debug('hotFilesList >>' + hotFilesList);
        if (!hotFilesList.isEmpty()) {
            return hotFilesList[0].Id;
        }
        return null;
    }

    @AuraEnabled
    public static Id createHotFileRecord(Id serviceAppointmentId) {
        Id existingId = getHotFileRecordId(serviceAppointmentId);
        if (existingId != null) {
            // Record already exists; return existing Id
            return existingId;
        }
        ServiceAppointment serviceAppointment = [
            SELECT Id, HOT_Account__c
            FROM ServiceAppointment
            WHERE Id = :serviceAppointmentId
            LIMIT 1
        ];
        // Create a new HOT_File__c record
        HOT_File__c hotFilesRecord = new HOT_File__c(
            Service_Appointment__c = serviceAppointmentId,
            Account__c = serviceAppointment.HOT_Account__c
        );
        HOT_DatabaseOperations.insertRecords(hotFilesRecord);
        return hotFilesRecord.Id;
    }

    @AuraEnabled
    public static void shareWithUser(Id hotFileId, List<Id> contentDocumentIds) {
        HOT_File__c hotFile = [SELECT Id, Account__c FROM HOT_File__c WHERE Id = :hotFileId LIMIT 1];

        if (hotFile != null && hotFile.Account__c != null) {
            List<ContentDocumentLink> cdls = new List<ContentDocumentLink>();
            for (Id contentDocumentId : contentDocumentIds) {
                ContentDocumentLink cdl = new ContentDocumentLink();
                cdl.ContentDocumentId = contentDocumentId;
                cdl.LinkedEntityId = hotFile.Account__c;
                cdl.ShareType = 'V';
                cdls.add(cdl);
            }
            HOT_DatabaseOperations.insertRecords(cdls);
        }
    }
}
