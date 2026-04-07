public without sharing class HOT_AssignOrReserveSAService {
    public class Request {
        @InvocableVariable(required=true label='Service Appointment Id')
        public Id serviceAppointmentId;

        @InvocableVariable(required=true label='Service Resource Id')
        public Id serviceResourceId;

        @InvocableVariable(required=true label='Target Status')
        public String targetStatus;
    }

    public class Response {
        @InvocableVariable(label='Success')
        public Boolean success;

        @InvocableVariable(label='Message')
        public String message;

        @InvocableVariable(label='Service Appointment Id')
        public Id serviceAppointmentId;

        @InvocableVariable(label='Assigned Resource Id')
        public Id assignedResourceId;
    }

    @InvocableMethod(
        label='Assign or Reserve Service Appointment'
        description='Creates or updates the assigned resource on a service appointment and sets it to Scheduled or Dispatched.'
        category='HOT Tolketjeneste'
        iconName='slds:standard:service_appointment'
    )
    public static List<Response> assignOrReserve(List<Request> requests) {
        List<Response> responses = new List<Response>();
        for (Request requestItem : requests) {
            responses.add(handleRequest(requestItem));
        }
        return responses;
    }

    private static Response handleRequest(Request requestItem) {
        Response response = new Response();
        response.success = false;

        try {
            validateRequest(requestItem);
            response.serviceAppointmentId = requestItem.serviceAppointmentId;

            List<AssignedResource> existingAssignedResources = [
                SELECT Id, ServiceResourceId
                FROM AssignedResource
                WHERE ServiceAppointmentId = :requestItem.serviceAppointmentId
                LIMIT 2
            ];
            if (existingAssignedResources.size() > 1) {
                throw new FlowHandledException('Oppdraget har flere tildelte ressurser enn forventet.');
            }

            ServiceAppointment currentServiceAppointment = [
                SELECT Id, Status, HOT_ServiceResource__c, HOT_AssignedResourceId__c
                FROM ServiceAppointment
                WHERE Id = :requestItem.serviceAppointmentId
                LIMIT 1
            ];
            validateServiceAppointment(currentServiceAppointment);

            ServiceResource selectedServiceResource = [
                SELECT Id, RelatedRecordId, Name
                FROM ServiceResource
                WHERE Id = :requestItem.serviceResourceId
                LIMIT 1
            ];

            // When downgrading from dispatched to scheduled, do that before AR updates so trigger side effects
            // keep the related Interested Resource in Reserved instead of Assigned.
            if (requestItem.targetStatus == 'Scheduled' && currentServiceAppointment.Status == 'Dispatched') {
                update new ServiceAppointment(
                    Id = currentServiceAppointment.Id,
                    Status = 'Scheduled',
                    HOT_ServiceResource__c = currentServiceAppointment.HOT_ServiceResource__c,
                    HOT_AssignedResourceId__c = currentServiceAppointment.HOT_AssignedResourceId__c
                );
            }

            AssignedResource assignedResource;
            if (existingAssignedResources.isEmpty()) {
                assignedResource = new AssignedResource(
                    ServiceAppointmentId = requestItem.serviceAppointmentId,
                    ServiceResourceId = requestItem.serviceResourceId
                );
                insert assignedResource;
            } else {
                assignedResource = existingAssignedResources[0];
                if (assignedResource.ServiceResourceId != requestItem.serviceResourceId) {
                    assignedResource.ServiceResourceId = requestItem.serviceResourceId;
                    update assignedResource;
                }
            }

            ServiceAppointment refreshedServiceAppointment = [
                SELECT Id, Status, HOT_ServiceResource__c, HOT_AssignedResourceId__c
                FROM ServiceAppointment
                WHERE Id = :requestItem.serviceAppointmentId
                LIMIT 1
            ];

            ServiceAppointment serviceAppointmentToUpdate = new ServiceAppointment(Id = refreshedServiceAppointment.Id);
            Boolean shouldUpdateServiceAppointment = false;

            if (refreshedServiceAppointment.Status != requestItem.targetStatus) {
                serviceAppointmentToUpdate.Status = requestItem.targetStatus;
                shouldUpdateServiceAppointment = true;
            }
            if (refreshedServiceAppointment.HOT_ServiceResource__c != selectedServiceResource.Id) {
                serviceAppointmentToUpdate.HOT_ServiceResource__c = selectedServiceResource.Id;
                shouldUpdateServiceAppointment = true;
            }
            if (refreshedServiceAppointment.HOT_AssignedResourceId__c != selectedServiceResource.RelatedRecordId) {
                serviceAppointmentToUpdate.HOT_AssignedResourceId__c = selectedServiceResource.RelatedRecordId;
                shouldUpdateServiceAppointment = true;
            }

            if (shouldUpdateServiceAppointment) {
                update serviceAppointmentToUpdate;
            }

            if (requestItem.targetStatus == 'Scheduled') {
                syncInterestedResourceToReserved(requestItem.serviceAppointmentId, requestItem.serviceResourceId);
            }

            response.success = true;
            response.assignedResourceId = assignedResource.Id;
            response.message = requestItem.targetStatus == 'Dispatched'
                ? 'Tolken ble tildelt oppdraget.'
                : 'Tolken ble reservert til oppdraget.';
        } catch (Exception ex) {
            response.message = ex.getMessage();
        }

        return response;
    }

    private static void validateRequest(Request requestItem) {
        if (requestItem == null) {
            throw new FlowHandledException('Ingen input ble sendt til handlingen.');
        }
        if (requestItem.serviceAppointmentId == null) {
            throw new FlowHandledException('Oppdrag mangler.');
        }
        if (requestItem.serviceResourceId == null) {
            throw new FlowHandledException('Du må velge en tolk.');
        }
        if (requestItem.targetStatus != 'Scheduled' && requestItem.targetStatus != 'Dispatched') {
            throw new FlowHandledException('Ugyldig målstatus.');
        }
    }

    private static void validateServiceAppointment(ServiceAppointment serviceAppointment) {
        Set<String> blockedStatuses = new Set<String>{ 'Completed', 'Canceled', 'Annul', 'In Progress', 'Cannot Complete' };
        if (blockedStatuses.contains(serviceAppointment.Status)) {
            throw new FlowHandledException('Oppdrag med status ' + serviceAppointment.Status + ' kan ikke endres her.');
        }
    }

    private static void syncInterestedResourceToReserved(Id serviceAppointmentId, Id selectedServiceResourceId) {
        List<HOT_InterestedResource__c> interestedResourcesToUpdate = new List<HOT_InterestedResource__c>();
        for (
            HOT_InterestedResource__c interestedResource : [
                SELECT Id, Status__c, ServiceResource__c
                FROM HOT_InterestedResource__c
                WHERE ServiceAppointment__c = :serviceAppointmentId
            ]
        ) {
            if (
                interestedResource.ServiceResource__c == selectedServiceResourceId &&
                interestedResource.Status__c == 'Assigned'
            ) {
                interestedResource.Status__c = 'Reserved';
                interestedResourcesToUpdate.add(interestedResource);
            }
        }

        if (!interestedResourcesToUpdate.isEmpty()) {
            update interestedResourcesToUpdate;
        }
    }

    private class FlowHandledException extends Exception {
    }
}
