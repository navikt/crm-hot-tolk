public with sharing class HOT_ContentDocumentLinkService {


    public static void setContentDocumentLinks(Map<Id, List<ContentDocumentLink>> serviceAppointmentMap){
        
        List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();

        for (Id serviceAppointmentId : serviceAppointmentMap.keySet()) {
            for (ContentDocumentLink contentDocumentLink: serviceAppointmentMap.get(serviceAppointmentId)){
                ContentDocumentLink contentDocumentLinkCopy = contentDocumentLink.clone(false, false, false, false);
                contentDocumentLinkCopy.LinkedEntityId = serviceAppointmentId;
                contentDocumentLinks.add(contentDocumentLinkCopy);
            }
        }
        insert contentDocumentLinks;
    }
}








