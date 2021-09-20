public with sharing class HOT_ContentDocumentLinkHandler extends MyTriggers {
    public override void onBeforeInsert() {
        confirmVisibilitySettings((List<ContentDocumentLink>) records);
    }

    public override void onAfterInsert() {
        createContentDocumentLinksToSA((List<ContentDocumentLink>) records);
    }

    public void createContentDocumentLinksToSA(List<ContentDocumentLink> contentDocumentLinks) {
        Map<Id, List<ContentDocumentLink>> linkedEntityMap = new Map<Id, List<ContentDocumentLink>>();
        HOT_Request__c requestObject = new HOT_Request__c();
        for (ContentDocumentLink cli : contentDocumentLinks) {
            if (cli.LinkedEntityId.getSObjectType() == requestObject.getSObjectType()) {
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
            WHERE HOT_Request__c IN :linkedEntityMap.keySet()
        ];
        Map<Id, List<ContentDocumentLink>> contentDocumentLinksByServiceAppointment = new Map<Id, List<ContentDocumentLink>>();
        for (ServiceAppointment serviceAppointment : ServiceAppointments) {
            contentDocumentLinksByServiceAppointment.put(
                serviceAppointment.Id,
                linkedEntityMap.get(serviceAppointment.HOT_Request__c)
            );
        }
        HOT_ContentDocumentLinkService.setContentDocumentLinks(contentDocumentLinksByServiceAppointment);
    }

    public void confirmVisibilitySettings(List<ContentDocumentLink> contentDocumentLinks) {
        SObjectType requestType = new HOT_Request__c().getSObjectType();
        SObjectType serviceAppointmentType = new ServiceAppointment().getSObjectType();

        for (ContentDocumentLink contentDocumentLink : contentDocumentLinks) {
            SObjectType cdiLinkedEntityIdType = contentDocumentLink.LinkedEntityId.getSobjectType();
            if (cdiLinkedEntityIdType == requestType || cdiLinkedEntityIdType == serviceAppointmentType) {
                contentDocumentLink.Visibility = 'AllUsers';
            }
        }
    }
}
