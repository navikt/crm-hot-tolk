public without sharing class HOT_ContentDocumentLinkService {
    public static void setContentDocumentLinks(
        Map<Id, List<ContentDocumentLink>> contentDocumentLinksByServiceAppointment
    ) {
        List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();

        for (Id serviceAppointmentId : contentDocumentLinksByServiceAppointment.keySet()) {
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
            insert contentDocumentLinks;
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
            logger.publishSynch();
        }
    }

    @InvocableVariable
    public Id contentDocumentId;

    @InvocableMethod
    public static void getContentDocumentLink(List<HOT_ContentDocumentLinkService> inputValues) {
        List<Id> contentDocumentIds = new List<Id>();

        for (HOT_ContentDocumentLinkService inputvalue : inputValues) {
            contentDocumentIds.add(inputvalue.contentDocumentId);
        }

        List<ContentDocumentLink> contentDocumentLinks = [
            SELECT ID
            FROM ContentDocumentLink
            WHERE ContentDocumentId IN :contentDocumentIds
        ];
    }
}
