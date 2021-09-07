public with sharing class HOT_ContentDocumentLinkService {


    public static void setContentDocumentLinks(List<ServiceAppointment> serviceAppointments){
        
        List<ContentDocumentLink> ContentDocumentLinks = new List<ContentDocumentLink>();
        List<Id> requests = new List<Id>();
        
        for (ServiceAppointment serviceAppointment : serviceAppointments) {
            requests.add(serviceAppointment.HOT_Request__c);
        }

        Map<Id, HOT_Request__c> idRequestMap = new Map<Id,HOT_Request__c>([SELECT Id, (SELECT ContentDocumentId, LinkedEntityId, ShareType, Visibility 
        FROM HOT_Request__c.ContentDocumentLinks) FROM HOT_Request__c WHERE Id IN  :requests]);

        Map<Id, ServiceAppointment> idServiceAppointmentMap = new Map<Id,ServiceAppointment>([SELECT Id, (SELECT ContentDocumentId, LinkedEntityId, ShareType, Visibility 
        FROM ServiceAppointment.ContentDocumentLinks) FROM ServiceAppointment WHERE Id IN  :serviceAppointments]);     
                                                                            
        Map<Id, List<Id>> serviceAppointmentContentDocumentIdMap = new Map<Id, List<Id>>(); // Contains ServiceAppointmentId and ContentDocumentId to its ContentDocumentLinks

        for (Id serviceAppointmentId : idServiceAppointmentMap.keySet()) {
            List<ContentDocumentLink> innerContentDocumentLinks = idServiceAppointmentMap.get(serviceAppointmentId).ContentDocumentLinks;
            List<Id> contentDocumentIds = new List<Id>();
            
            for (ContentDocumentLink contentDocumentLink : innerContentDocumentLinks) {
                contentDocumentIds.add(contentDocumentLink.ContentDocumentId);
            }
            serviceAppointmentContentDocumentIdMap.put(serviceAppointmentId, contentDocumentIds);
        }


        for (ServiceAppointment serviceAppointment : serviceAppointments) {
            HOT_Request__c request = idRequestMap.get(serviceAppointment.HOT_Request__c);
            
            for (ContentDocumentLink cdl : request.ContentDocumentLinks){
                if (!serviceAppointmentContentDocumentIdMap.get(serviceAppointment.Id).contains(cdl.ContentDocumentId)){
                    ContentDocumentLink temp1 = cdl.clone(false, false, false, false);
                    temp1.LinkedEntityId = serviceAppointment.Id;
                    ContentDocumentLinks.add(temp1);
                }
            }
        }
        insert ContentDocumentLinks;
    }
}
