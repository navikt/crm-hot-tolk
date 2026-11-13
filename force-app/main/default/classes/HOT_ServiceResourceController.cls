public with sharing class HOT_ServiceResourceController {
    @AuraEnabled(cacheable=true)
    public static List<ServiceResource> getAllServiceResources(Boolean searchFreelances, Boolean searchEmployees) {
        if (searchFreelances == true && searchEmployees == true) {
            return [
                SELECT Id, Name, HOT_IsEmployedInterpreter__c, HOT_IsFreelanceInterpreter__c
                FROM ServiceResource
                WHERE
                    IsActive = TRUE
                    AND CRM_Domain__c = 'HOT'
                    AND CRM_Subdomain__c = 'Tolketjenesten'
                    AND (HOT_IsFreelanceInterpreter__c = TRUE
                    OR HOT_IsEmployedInterpreter__c = TRUE)
                ORDER BY Name
            ];
        }
        if (searchFreelances == true) {
            return [
                SELECT Id, Name, HOT_IsEmployedInterpreter__c, HOT_IsFreelanceInterpreter__c
                FROM ServiceResource
                WHERE
                    IsActive = TRUE
                    AND CRM_Domain__c = 'HOT'
                    AND CRM_Subdomain__c = 'Tolketjenesten'
                    AND HOT_IsFreelanceInterpreter__c = TRUE
                ORDER BY Name
            ];
        }
        if (searchEmployees == true) {
            return [
                SELECT Id, Name, HOT_IsEmployedInterpreter__c, HOT_IsFreelanceInterpreter__c
                FROM ServiceResource
                WHERE
                    IsActive = TRUE
                    AND CRM_Domain__c = 'HOT'
                    AND CRM_Subdomain__c = 'Tolketjenesten'
                    AND HOT_IsEmployedInterpreter__c = TRUE
                ORDER BY Name
            ];
        }
        return new List<ServiceResource>();
    }

    @AuraEnabled
    public static ResourceDetails getResourceDetails(Id resourceId, Id serviceAppointmentId) {
        ServiceResource resource = [
            SELECT Id, Name, HOT_PreferredRegions__c, HOT_IsEmployedInterpreter__c, HOT_IsFreelanceInterpreter__c
            FROM ServiceResource
            WHERE Id = :resourceId
            LIMIT 1
        ];
        ServiceAppointment appointment = [
            SELECT SchedStartTime, SchedEndTime, ServiceTerritory.Name
            FROM ServiceAppointment
            WHERE Id = :serviceAppointmentId
            LIMIT 1
        ];

        ResourceDetails details = new ResourceDetails();
        details.id = resource.Id;
        details.name = resource.Name;
        details.isEmployedInterpreter = resource.HOT_IsEmployedInterpreter__c;
        details.isFreelanceInterpreter = resource.HOT_IsFreelanceInterpreter__c;
        details.preferredRegions = new List<String>();
        details.serviceTerritoryName = appointment.ServiceTerritory?.Name;

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
        if (details.serviceTerritoryName != null && !details.regionMatches) {
            List<ServiceTerritoryMember> matchingTerritoryMembers = [
                SELECT Id
                FROM ServiceTerritoryMember
                WHERE
                    ServiceResourceId = :resourceId
                    AND ServiceTerritory.Name = :details.serviceTerritoryName
                    AND EffectiveEndDate = NULL
                LIMIT 1
            ];
            details.regionMatches = !matchingTerritoryMembers.isEmpty();
        }
        if (appointment.SchedStartTime == null || appointment.SchedEndTime == null) {
            throw new AuraHandledException('Kan ikke vurdere tilgjengelighet fordi oppdraget mangler planlagte tider.');
        }

        List<ServiceAppointment> overlappingAppointments = [
            SELECT Id
            FROM ServiceAppointment
            WHERE
                Id IN (SELECT ServiceAppointmentId FROM AssignedResource WHERE ServiceResourceId = :resourceId)
                AND Id != :serviceAppointmentId
                AND SchedStartTime < :appointment.SchedEndTime
                AND SchedEndTime > :appointment.SchedStartTime
            LIMIT 1
        ];
        details.hasOverlap = !overlappingAppointments.isEmpty();

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

    public class ResourceDetails {
        @AuraEnabled
        public Id id;
        @AuraEnabled
        public String name;
        @AuraEnabled
        public Boolean isEmployedInterpreter;
        @AuraEnabled
        public Boolean isFreelanceInterpreter;
        @AuraEnabled
        public List<String> preferredRegions;
        @AuraEnabled
        public String serviceTerritoryName;
        @AuraEnabled
        public Boolean regionMatches;
        @AuraEnabled
        public Boolean hasOverlap;
        @AuraEnabled
        public Boolean hasRegionMismatch;
    }
}
