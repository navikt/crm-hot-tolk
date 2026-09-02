public without sharing class HOT_InterestedResourceOnWorkOrderService {
    public static List<HOT_InterestedResource__c> getInterestedResourcesToUpdateOnDispatch(
        List<ServiceAppointment> serviceAppointments
    ) {
        if (serviceAppointments.isEmpty()) {
            return new List<HOT_InterestedResource__c>();
        }

        Set<Id> dispatchedServiceAppointmentIds = new Set<Id>();
        Set<Id> serviceResourceIds = new Set<Id>();
        Set<String> workOrderIds = new Set<String>();
        Map<String, Set<Id>> serviceAppointmentIdsByResourceAndWorkOrder = new Map<String, Set<Id>>();
        for (ServiceAppointment serviceAppointment : serviceAppointments) {
            if (
                serviceAppointment.Id == null ||
                serviceAppointment.HOT_ServiceResource__c == null ||
                String.isBlank(serviceAppointment.HOT_WorkOrderID__c)
            ) {
                continue;
            }

            dispatchedServiceAppointmentIds.add(serviceAppointment.Id);
            serviceResourceIds.add(serviceAppointment.HOT_ServiceResource__c);
            String workOrderId = serviceAppointment.HOT_WorkOrderID__c;
            workOrderIds.add(workOrderId);
            String resourceAndWorkOrderKey = getResourceAndWorkOrderKey(
                serviceAppointment.HOT_ServiceResource__c,
                workOrderId
            );
            if (!serviceAppointmentIdsByResourceAndWorkOrder.containsKey(resourceAndWorkOrderKey)) {
                serviceAppointmentIdsByResourceAndWorkOrder.put(resourceAndWorkOrderKey, new Set<Id>());
            }
            serviceAppointmentIdsByResourceAndWorkOrder.get(resourceAndWorkOrderKey)
                .add(serviceAppointment.Id);
        }

        if (workOrderIds.isEmpty() || serviceResourceIds.isEmpty()) {
            return new List<HOT_InterestedResource__c>();
        }

        List<HOT_InterestedResource__c> relatedInterestedResources = [
            SELECT
                Id,
                Status__c,
                ServiceAppointment__c,
                ServiceResource__c,
                ServiceAppointment__r.HOT_WorkOrderID__c
            FROM HOT_InterestedResource__c
            WHERE
                ServiceResource__c IN :serviceResourceIds
                AND Status__c = 'Interested'
                AND ServiceAppointment__c NOT IN :dispatchedServiceAppointmentIds
                AND ServiceAppointment__r.HOT_WorkOrderID__c IN :workOrderIds
        ];

        List<HOT_InterestedResource__c> interestedResourcesToUpdate = new List<HOT_InterestedResource__c>();
        for (HOT_InterestedResource__c interestedResource : relatedInterestedResources) {
            String resourceAndWorkOrderKey = getResourceAndWorkOrderKey(
                interestedResource.ServiceResource__c,
                interestedResource.ServiceAppointment__r.HOT_WorkOrderID__c
            );
            if (
                serviceAppointmentIdsByResourceAndWorkOrder.containsKey(resourceAndWorkOrderKey) &&
                !serviceAppointmentIdsByResourceAndWorkOrder.get(resourceAndWorkOrderKey)
                    .contains(interestedResource.ServiceAppointment__c)
            ) {
                interestedResource.Status__c = 'Not Assigned';
                interestedResourcesToUpdate.add(interestedResource);
            }
        }

        return interestedResourcesToUpdate;
    }

    private static String getResourceAndWorkOrderKey(Id serviceResourceId, String workOrderId) {
        return String.valueOf(serviceResourceId) + '-' + String.valueOf(workOrderId);
    }
}
