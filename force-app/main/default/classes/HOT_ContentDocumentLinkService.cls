public without sharing class HOT_ContentDocumentLinkService {
    private static void handleException(Exception e) {
        LoggerUtility logger = new LoggerUtility();
        logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
        logger.publishSynch();
    }

    public static void setContentDocumentLinks(
        Map<Id, List<ContentDocumentLink>> contentDocumentLinksByServiceAppointment
    ) {
        List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();
        Set<Id> serviceAppointmentIds = new Set<Id>();

        for (Id serviceAppointmentId : contentDocumentLinksByServiceAppointment.keySet()) {
            serviceAppointmentIds.add(serviceAppointmentId);
            for (
                ContentDocumentLink contentDocumentLink : contentDocumentLinksByServiceAppointment.get(
                    serviceAppointmentId
                )
            ) {
                ContentDocumentLink contentDocumentLinkCopy = new ContentDocumentLink();
                contentDocumentLinkCopy.ContentDocumentId = contentDocumentLink.ContentDocumentId;
                contentDocumentLinkCopy.LinkedEntityId = serviceAppointmentId;
                contentDocumentLinkCopy.Visibility = 'AllUsers';
                contentDocumentLinkCopy.ShareType = 'V';
                contentDocumentLinks.add(contentDocumentLinkCopy);
            }
        }

        try {
            HOT_DatabaseOperations.insertRecords(contentDocumentLinks);
        } catch (Exception e) {
            handleException(e);
        }
        HOT_ServiceAppointmentNotification.notifyInterpretersOnNewFiles(serviceAppointmentIds);
    }

    @InvocableVariable
    public Id recordId;
    @InvocableVariable
    public List<ContentDocument> contentDocuments;

    @InvocableMethod
    public static void deleteContentDocumentLink(List<HOT_ContentDocumentLinkService> inputValue) {
        List<Id> contentDocumentIds = new List<Id>();

        for (ContentDocument contentDocument : inputValue[0].contentDocuments) {
            contentDocumentIds.add(contentDocument.Id);
        }

        List<ContentDocumentLink> contentDocumentLinks = [
            SELECT Id
            FROM ContentDocumentLink
            WHERE ContentDocumentId IN :contentDocumentIds AND LinkedEntityId = :inputValue[0].recordId
        ];

        HOT_DatabaseOperations.deleteRecords(contentDocumentLinks);
    }
}
