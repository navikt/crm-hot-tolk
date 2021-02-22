public without sharing class HOT_InterestedResourceHandler extends MyTriggers {
    public override void onAfterInsert() {
        System.debug('HOT_InterestedResourceHandler onAfterInsert');
        updateNumberOfInterestedResourcesOnWorkOrderLineItem((List<HOT_InterestedResource__c>) records);
    }

    public override void onAfterUpdate(Map<Id, sObject> triggerOldMap) {
        System.debug('HEI');
        System.debug('HOT_InterestedResourceHandler onAfterUpdate');
        updateNumberOfInterestedResourcesOnWorkOrderLineItem((List<HOT_InterestedResource__c>) records);
    }

    private static void updateNumberOfInterestedResourcesOnWorkOrderLineItem(
        List<HOT_InterestedResource__c> interestedResources
    ) {
        List<Id> serviceAppointmentIds = new List<Id>();
        for (HOT_InterestedResource__c interestedResource : interestedResources) {
            serviceAppointmentIds.add(interestedResource.ServiceAppointment__c);
        }
        List<ServiceAppointment> serviceAppointments = [
            SELECT
                Id,
                ParentRecordId,
                (
                    SELECT Id, ServiceResource__c
                    FROM ServiceAppointment.InterestedResources__r
                    WHERE Status__c = 'Interested'
                )
            FROM ServiceAppointment
            WHERE Id IN :serviceAppointmentIds
        ];
        Map<Id, Set<Id>> uniqueSRbyWOLI = new Map<Id, Set<Id>>();
        for (ServiceAppointment serviceAppointment : serviceAppointments) {
            Set<Id> serviceResourceIds = new Set<Id>();
            for (HOT_InterestedResource__c ir : serviceAppointment.InterestedResources__r) {
                serviceResourceIds.add(ir.ServiceResource__c);
            }
            uniqueSRbyWOLI.put(serviceAppointment.ParentRecordId, serviceResourceIds);
        }
        System.debug(uniqueSRbyWOLI);
        Map<Id, WorkOrderLineItem> workOrderLineItems = new Map<Id, WorkOrderLineItem>(
            [SELECT Id, HOT_NumberOfInterestedResources__c FROM WorkOrderLineItem WHERE Id IN :uniqueSRbyWOLI.keySet()]
        );
        for (Id id : workOrderLineItems.keySet()) {
            System.debug(uniqueSRbyWOLI.get(id));
            System.debug(uniqueSRbyWOLI.get(id).size());
            workOrderLineItems.get(id).HOT_NumberOfInterestedResources__c = uniqueSRbyWOLI.get(id).size();
        }
        update workOrderLineItems.values();
    }
}
