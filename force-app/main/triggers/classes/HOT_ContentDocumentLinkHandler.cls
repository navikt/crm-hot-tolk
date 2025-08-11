public without sharing class HOT_ContentDocumentLinkHandler extends MyTriggers {
    public override void onBeforeInsert() {
        confirmVisibilitySettings((List<ContentDocumentLink>) records);
    }

    public override void onAfterInsert() {
        createContentDocumentLinksToWO((List<ContentDocumentLink>) records);
        createContentDocumentLinksToSA((List<ContentDocumentLink>) records);
        createContentDocumentLinksToAccount((List<ContentDocumentLink>) records);
    }

    public static void createContentDocumentLinksToWO(List<ContentDocumentLink> contentDocumentLinks) {
        Map<Id, List<ContentDocumentLink>> linkedEntityMap = getContentDocumentLinksByRequest(contentDocumentLinks);
        List<WorkOrder> workOrder = [
            SELECT Id, HOT_Request__c
            FROM WorkOrder
            WHERE HOT_Request__c IN :linkedEntityMap.keySet()
        ];
        Map<Id, List<ContentDocumentLink>> contentDocumentLinksByWorkOrder = new Map<Id, List<ContentDocumentLink>>();
        for (WorkOrder wo : workOrder) {
            contentDocumentLinksByWorkOrder.put(wo.Id, linkedEntityMap.get(wo.HOT_Request__c));
        }
        if (!contentDocumentLinksByWorkOrder.isEmpty()) {
            HOT_ContentDocumentLinkService.setContentDocumentLinks(contentDocumentLinksByWorkOrder);
        }
    }

    public static void createContentDocumentLinksToSA(List<ContentDocumentLink> contentDocumentLinks) {
        Map<Id, List<ContentDocumentLink>> linkedEntityMap = getContentDocumentLinksByRequest(contentDocumentLinks);
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
        if (!contentDocumentLinksByServiceAppointment.isEmpty()) {
            HOT_ContentDocumentLinkService.setContentDocumentLinks(contentDocumentLinksByServiceAppointment);
        }
    }

    public static void createContentDocumentLinksToAccount(List<ContentDocumentLink> contentDocumentLinks) {
        Map<Id, List<ContentDocumentLink>> linkedEntityMap = getContentDocumentLinksByRequest(contentDocumentLinks);
        List<HOT_Request__c> requests = [
            SELECT Id, Account__c
            FROM HOT_Request__c
            WHERE Id IN :linkedEntityMap.keySet() AND Account__c != NULL
        ];
        List<ContentDocumentLink> contentDocumentLinksToAccount = new List<ContentDocumentLink>();
        for (HOT_Request__c request : requests) {
            for (ContentDocumentLink cdl : linkedEntityMap.get(request.Id)) {
                ContentDocumentLink newcdl = new ContentDocumentLink();
                newcdl.LinkedEntityId = request.Account__c;
                newcdl.ContentDocumentId = cdl.ContentDocumentId;
                newcdl.Visibility = 'AllUsers';
                contentDocumentLinksToAccount.add(newcdl);
            }
        }

        try {
            insert contentDocumentLinksToAccount;
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
            logger.publishSynch();
        }
    }

    public static void confirmVisibilitySettings(List<ContentDocumentLink> contentDocumentLinks) {
        SObjectType requestType = new HOT_Request__c().getSObjectType();
        SObjectType serviceAppointmentType = new ServiceAppointment().getSObjectType();

        for (ContentDocumentLink contentDocumentLink : contentDocumentLinks) {
            SObjectType cdiLinkedEntityIdType = contentDocumentLink.LinkedEntityId.getSobjectType();
            if (cdiLinkedEntityIdType == requestType || cdiLinkedEntityIdType == serviceAppointmentType) {
                contentDocumentLink.Visibility = 'AllUsers';
            }
        }
    }

    private static Map<Id, List<ContentDocumentLink>> getContentDocumentLinksByRequest(
        List<ContentDocumentLink> contentDocumentLinks
    ) {
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
        return linkedEntityMap;
    }
}
