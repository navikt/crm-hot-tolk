public with sharing class HOT_ContentDocumentLinkHandler extends MyTriggers {
    // Har lagt til to triggere. Den ene skal brukes til TOLK-190, den andre til TOLK-1588.
    // Hvilken skal brukes hvor?
    public override void onBeforeInsert() {
        List<ContentDocumentLink> contentDocumentLinks = (List<ContentDocumentLink>) records;
    }

    public override void onAfterInsert() {
        List<ContentDocumentLink> contentDocumentLinks = (List<ContentDocumentLink>) records;

        createContentDocumentLinksToSA(records);
    }

    public void createContentDocumentLinksToSA(List<ContentDocumentLink> contentDocumentLinks) {
        List<Id> requestsWithCli = new List<Id>();
        Map<Id, List<ContentDocumentLink>> linkedEntityMap = new Map<Id, List<ContentDocumentLink>>();
        HOT_Request__c requestObject = new HOT_Request__c();
        for (ContentDocumentLink cli : contentDocumentLinks) {
            if (cli.LinkedEntityId.getSObjectType() == requestObject.getSObjectType()) {
                requestsWithCli.add(cli.LinkedEntityId);
                if (linkedEntityMap.get(cli.LinkedEntityId) == null) {
                    linkedEntityMap.put(cli.LinkedEntityId, new List<ContentDocumentLink>{ cli });
                } else {
                    linkedEntityMap.get(cli.LinkedEntityId).add(cli);
                }
            }
        }
        List<ServiceAppointment> serviceAppointments = [
            SELECT Id, HOT_Request__c
            FROM ServiceAppointment
            WHERE HOT_Request__c IN :requestsWithCli
        ];
        Map<Id, List<ContentDocumentLink>> serviceAppointmentMap = new Map<Id, List<ContentDocumentLink>>();
        for (ServiceAppointment serviceAppointment : ServiceAppointments) {
            serviceAppointmentMap.put(serviceAppointment.Id, linkedEntityMap.get(serviceAppointment.HOT_Request__c));
        }
        HOT_ContentDocumentLinkService.setContentDocumentLinks(serviceAppointmentMap);
    }
}
