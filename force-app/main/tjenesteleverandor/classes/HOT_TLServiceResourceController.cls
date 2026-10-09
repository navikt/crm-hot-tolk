public with sharing class HOT_TLServiceResourceController {
    @AuraEnabled(cacheable=true)
    public static List<ServiceResource> getAllServiceResources() {
        return [
            SELECT Id, Name
            FROM ServiceResource
            WHERE
                IsActive = TRUE
                AND CRM_Domain__c = 'HOT'
                AND CRM_Subdomain__c = 'Tolketjenesten'
                AND HOT_IsFreelanceInterpreter__c = TRUE
            ORDER BY Name
        ];
    }

    @AuraEnabled
    public static ResourceDetails getResourceDetails(Id resourceId, Id serviceAppointmentId) {
        ServiceResource resource = [
            SELECT Id, Name, HOT_PreferredRegions__c
            FROM ServiceResource
            WHERE Id = :resourceId
            WITH USER_MODE
            LIMIT 1
        ];
        ServiceAppointment appointment = [
            SELECT EarliestStartTime, DueDate, HOT_Request__r.ServiceTerritory__r.Name
            FROM ServiceAppointment
            WHERE Id = :serviceAppointmentId
            WITH USER_MODE
            LIMIT 1
        ];

        ResourceDetails details = new ResourceDetails();
        details.id = resource.Id;
        details.name = resource.Name;
        details.preferredRegions = new List<String>();
        details.serviceTerritoryName = appointment.HOT_Request__r?.ServiceTerritory__r?.Name;

        Set<String> preferredRegionValues = new Set<String>();
        if (String.isNotBlank(resource.HOT_PreferredRegions__c)) {
            preferredRegionValues.addAll(resource.HOT_PreferredRegions__c.split(';'));
        }
        for (
            Schema.PicklistEntry regionOption : ServiceResource.HOT_PreferredRegions__c.getDescribe()
                .getPicklistValues()
        ) {
            if (preferredRegionValues.contains(regionOption.getValue())) {
                details.preferredRegions.add(regionOption.getLabel());
            }
        }

        details.regionMatches =
            details.serviceTerritoryName != null && details.preferredRegions.contains(details.serviceTerritoryName);
        details.hasOverlap = false;

        if (appointment.EarliestStartTime != null && appointment.DueDate != null) {
            for (HOT_InterestedResource__c assignedResource : [
                SELECT ServiceAppointmentStartTime__c, ServiceAppointmentEndTime__c
                FROM HOT_InterestedResource__c
                WHERE
                    ServiceResource__c = :resourceId
                    AND ServiceAppointment__c != :serviceAppointmentId
                    AND Status__c = 'Assigned'
                WITH USER_MODE
            ]) {
                if (
                    assignedResource.ServiceAppointmentStartTime__c != null &&
                    assignedResource.ServiceAppointmentEndTime__c != null &&
                    appointment.EarliestStartTime < assignedResource.ServiceAppointmentEndTime__c &&
                    appointment.DueDate > assignedResource.ServiceAppointmentStartTime__c
                ) {
                    details.hasOverlap = true;
                    break;
                }
            }
        }

        return details;
    }
    @AuraEnabled(cacheable=true)
    public static List<HOT_InterestedResource__c> interestedResourcesOfServiceAppointment(Id saID) {
        List<HOT_InterestedResource__c> interestedResources = [
            SELECT ServiceResource__c, ServiceResource__r.Name, ServiceAppointment__c, Status__c
            FROM HOT_InterestedResource__c
            WHERE ServiceAppointment__c = :saID
            ORDER BY ServiceResource__r.Name
        ];
        return interestedResources;
    }

    /** Details displayed after a resource is selected. */
    public class ResourceDetails {
        @AuraEnabled
        public Id id;
        @AuraEnabled
        public String name;
        @AuraEnabled
        public List<String> preferredRegions;
        @AuraEnabled
        public String serviceTerritoryName;
        @AuraEnabled
        public Boolean regionMatches;
        @AuraEnabled
        public Boolean hasOverlap;
    }
}
