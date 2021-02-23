public without sharing class HOT_AssignedResourceHandler extends MyTriggers {
    public override void onBeforeInsert() {
        updateServiceTerritoryOnServiceAppointment((List<AssignedResource>) records);
        setResourceTypeOnServiceAppointment((List<AssignedResource>) records);
    }
    public override void onBeforeUpdate(Map<Id, sObject> triggerOldMap) {
        List<AssignedResource> assignedResourcesFiltered = new List<AssignedResource>();
        for (AssignedResource assignedResource : (List<AssignedResource>) records) {
            if (assignedResource.ServiceResourceId != triggerOldMap.get(assignedResource.Id).get('ServiceResourceId')) {
                assignedResourcesFiltered.add(assignedResource);
            }
        }
        if (assignedResourcesFiltered.size() > 0) {
            updateServiceTerritoryOnServiceAppointment(assignedResourcesFiltered);
            setResourceTypeOnServiceAppointment(assignedResourcesFiltered);
        }
    }

    public override void onAfterInsert() {
        List<ServiceAppointment> serviceAppointments = setServiceResourceFieldsOnServiceAppointment(
            (List<AssignedResource>) records
        );
        update serviceAppointments;
        List<HOT_InterestedResource__c> interestedResource = createInterestedResources(
            (List<AssignedResource>) records
        );
        insert interestedResource;
        List<HOT_InterestedResource__c> interestedResources = updateInterestedResourceStatus(
            (List<AssignedResource>) records
        );
        update interestedResources;
    }

    public override void onAfterUpdate(Map<Id, sObject> triggerOldMap) {
        List<AssignedResource> assignedResourcesFiltered = new List<AssignedResource>();
        for (AssignedResource assignedResource : (List<AssignedResource>) records) {
            if (assignedResource.ServiceResourceId != triggerOldMap.get(assignedResource.Id).get('ServiceResourceId')) {
                assignedResourcesFiltered.add(assignedResource);
            }
        }
        if (assignedResourcesFiltered.size() > 0) {
            List<ServiceAppointment> serviceAppointments = setServiceResourceFieldsOnServiceAppointment(
                (List<AssignedResource>) records
            );
            update serviceAppointments;
            List<HOT_InterestedResource__c> interestedResource = createInterestedResources(
                (List<AssignedResource>) records
            );
            insert interestedResource;
            List<HOT_InterestedResource__c> interestedResources = updateInterestedResourceStatus(
                (List<AssignedResource>) records
            );
            update interestedResources;
        }
    }

    public List<ServiceAppointment> setServiceResourceFieldsOnServiceAppointment(List<AssignedResource> records) {
        //Creates Map and List for SOQL and reference later
        Map<Id, AssignedResource> assignedResourceByServiceAppointmentId = new Map<Id, AssignedResource>();
        List<Id> serviceResourceIds = new List<Id>();
        for (AssignedResource ar : (List<AssignedResource>) records) {
            assignedResourceByServiceAppointmentId.put(ar.ServiceAppointmentId, ar);
            serviceResourceIds.add(ar.ServiceResourceId);
        }

        //Fetches ServiceAppointments to be updated and userId of the ServiceResources
        List<ServiceAppointment> serviceAppointments = [
            SELECT Id, HOT_AssignedResourceId__c, HOT_ServiceResource__c
            FROM ServiceAppointment
            WHERE Id IN :assignedResourceByServiceAppointmentId.keySet()
        ];
        Map<Id, ServiceResource> serviceResourceById = new Map<Id, ServiceResource>(
            [SELECT Id, RelatedRecordId, Name FROM ServiceResource WHERE Id IN :serviceResourceIds]
        );

        //Setting fields on ServiceAppointment
        for (ServiceAppointment sa : serviceAppointments) {
            Id serviceResourceId = assignedResourceByServiceAppointmentId.get(sa.Id).ServiceResourceId;
            sa.HOT_ServiceResource__c = serviceResourceId;
            sa.HOT_AssignedResourceId__c = serviceResourceById.get(serviceResourceId).RelatedRecordId;
        }
        return serviceAppointments;
    }

    public override void onAfterDelete() {
        List<Id> serviceAppointmentIds = new List<Id>();
        for (AssignedResource ar : (List<AssignedResource>) records) {
            serviceAppointmentIds.add(ar.ServiceAppointmentId);
        }
        List<ServiceAppointment> serviceAppointments = [
            SELECT
                Id,
                HOT_AssignedResourceId__c,
                HOT_ServiceResource__c,
                EarliestStartTime,
                DueDate,
                SchedStartTime,
                SchedEndTime,
                HOT_IsReleasedToFreelance__c,
                HOT_IsEmployedInterpreter__c
            FROM ServiceAppointment
            WHERE Id IN :serviceAppointmentIds
        ];

        for (ServiceAppointment sa : serviceAppointments) {
            sa.HOT_ServiceResource__c = null;
            sa.HOT_AssignedResourceId__c = null;
            sa.SchedStartTime = sa.EarliestStartTime;
            sa.SchedEndTime = sa.DueDate;
            sa.HOT_IsReleasedToFreelance__c = false;
            sa.HOT_IsEmployedInterpreter__c = true;
        }
        update serviceAppointments;
    }

    List<HOT_InterestedResource__c> createInterestedResources(List<AssignedResource> records) {
        List<HOT_InterestedResource__c> interestedResources = new List<HOT_InterestedResource__c>();

        //Creates map to be used in query of InterestedResources
        Map<Id, Id> serviceResourceIdByServiceAppointmentId = new Map<Id, Id>();
        for (AssignedResource assignedResource : records) {
            serviceResourceIdByServiceAppointmentId.put(
                assignedResource.ServiceAppointmentId,
                assignedResource.ServiceResourceId
            );
        }
        //Fetches possible matches with Interested Resources
        List<HOT_InterestedResource__c> existingInterestedResources = [
            SELECT Id, ServiceAppointment__c, ServiceResource__c
            FROM HOT_InterestedResource__c
            WHERE
                ServiceAppointment__c IN :serviceResourceIdByServiceAppointmentId.keySet()
                AND ServiceResource__c IN :serviceResourceIdByServiceAppointmentId.values()
        ];
        //Fetches Freelance interpreters included in the assigned resource records, and gets their Ids
        List<ServiceResource> serviceResources = [
            SELECT Id
            FROM ServiceResource
            WHERE Id IN :serviceResourceIdByServiceAppointmentId.values() AND HOT_IsFreelanceInterpreter__c = TRUE
        ];
        List<Id> freelanceResourceIds = new List<Id>();
        for (ServiceResource serviceResource : serviceResources) {
            freelanceResourceIds.add(serviceResource.Id);
        }

        //Runs through all AR records, and if the ServiceResource is a freelance interpreter, runs through the Interested Resources and checks for matches on SA and SR
        //If there is no match, an IR should be created.
        for (AssignedResource assignedResource : records) {
            if (freelanceResourceIds.contains(assignedResource.ServiceResourceId)) {
                Boolean shouldCreateInterestedResource = true;
                for (HOT_InterestedResource__c interestedResource : existingInterestedResources) {
                    if (
                        assignedResource.ServiceAppointmentId == interestedResource.ServiceAppointment__c &&
                        assignedResource.ServiceResourceId == interestedResource.ServiceResource__c
                    ) {
                        shouldCreateInterestedResource = false;
                        break;
                    }
                }
                if (shouldCreateInterestedResource) {
                    HOT_InterestedResource__c interestedResource = new HOT_InterestedResource__c();
                    interestedResource.ServiceAppointment__c = assignedResource.ServiceAppointmentId;
                    interestedResource.ServiceResource__c = assignedResource.ServiceResourceId;
                    interestedResource.Status__c = 'Assigned';
                    interestedResources.add(interestedResource);
                }
            }
        }
        return interestedResources;
    }

    static public List<HOT_InterestedResource__c> updateInterestedResourceStatus(
        List<AssignedResource> assignedResources
    ) {
        List<Id> serviceAppointmentIds = new List<Id>();
        for (AssignedResource assignedResource : assignedResources) {
            serviceAppointmentIds.add(assignedResource.ServiceAppointmentId);
        }
        List<HOT_InterestedResource__c> interestedResources = [
            SELECT Id, Status__c, ServiceAppointment__c, ServiceResource__c
            FROM HOT_InterestedResource__c
            WHERE ServiceAppointment__c IN :serviceAppointmentIds
        ];
        for (AssignedResource assignedResource : assignedResources) {
            for (HOT_InterestedResource__c interestedResource : interestedResources) {
                if (assignedResource.ServiceAppointmentId == interestedResource.ServiceAppointment__c) {
                    if (
                        interestedResource.ServiceResource__c == assignedResource.ServiceResourceId &&
                        interestedResource.Status__c != 'Assigned'
                    ) {
                        interestedResource.Status__c = 'Assigned';
                    } else if (
                        interestedResource.ServiceResource__c != assignedResource.ServiceResourceId &&
                        interestedResource.Status__c != 'Not Assigned'
                    ) {
                        interestedResource.Status__c = 'Not Assigned';
                    }
                }
            }
        }
        return interestedResources;
    }

    public static void updateServiceTerritoryOnServiceAppointment(List<AssignedResource> assignedResources) {
        List<Id> serviceAppointmentIds = new List<Id>();
        List<Id> serviceResourceIds = new List<Id>();
        for (AssignedResource assignedResource : assignedResources) {
            serviceAppointmentIds.add(assignedResource.ServiceAppointmentId);
            serviceResourceIds.add(assignedResource.ServiceResourceId);
        }
        Map<Id, ServiceAppointment> serviceAppointments = new Map<Id, ServiceAppointment>(
            [SELECT Id, ServiceTerritoryId FROM ServiceAppointment WHERE Id IN :serviceAppointmentIds]
        );
        Map<Id, ServiceResource> serviceResources = new Map<Id, ServiceResource>(
            [SELECT Id, HOT_ServiceTerritory__r.Id FROM ServiceResource WHERE Id IN :serviceResourceIds]
        );

        List<ServiceAppointment> serviceAppointmentsToUpdate = new List<ServiceAppointment>();
        for (AssignedResource assignedResource : assignedResources) {
            if (
                serviceAppointments.get(assignedResource.ServiceAppointmentId).ServiceTerritoryId !=
                serviceResources.get(assignedResource.ServiceResourceId).HOT_ServiceTerritory__r.Id
            ) {
                serviceAppointments.get(assignedResource.ServiceAppointmentId)
                    .ServiceTerritoryId = serviceResources.get(assignedResource.ServiceResourceId)
                    .HOT_ServiceTerritory__c;
                serviceAppointmentsToUpdate.add(serviceAppointments.get(assignedResource.ServiceAppointmentId));
            }
        }
        update serviceAppointmentsToUpdate;
    }

    public static void setResourceTypeOnServiceAppointment(List<AssignedResource> assignedResources) {
        List<Id> serviceAppointmentIds = new List<Id>();
        List<Id> serviceResourceIds = new List<Id>();
        for (AssignedResource assignedResource : assignedResources) {
            serviceAppointmentIds.add(assignedResource.ServiceAppointmentId);
            serviceResourceIds.add(assignedResource.ServiceResourceId);
        }
        Map<Id, ServiceAppointment> serviceAppointments = new Map<Id, ServiceAppointment>(
            [
                SELECT Id, HOT_IsReleasedToFreelance__c, HOT_IsEmployedInterpreter__c
                FROM ServiceAppointment
                WHERE Id IN :serviceAppointmentIds
            ]
        );
        Map<Id, ServiceResource> serviceResources = new Map<Id, ServiceResource>(
            [
                SELECT Id, HOT_IsFreelanceInterpreter__c, HOT_IsEmployedInterpreter__c
                FROM ServiceResource
                WHERE Id IN :serviceResourceIds
            ]
        );

        List<ServiceAppointment> serviceAppointmentsToUpdate = new List<ServiceAppointment>();
        for (AssignedResource assignedResource : assignedResources) {
            if (
                serviceResources.get(assignedResource.ServiceResourceId).HOT_IsEmployedInterpreter__c !=
                serviceAppointments.get(assignedResource.ServiceAppointmentId).HOT_IsEmployedInterpreter__c
            ) {
                serviceAppointments.get(assignedResource.ServiceAppointmentId)
                    .HOT_IsEmployedInterpreter__c = serviceResources.get(assignedResource.ServiceResourceId)
                    .HOT_IsEmployedInterpreter__c;
                serviceAppointments.get(assignedResource.ServiceAppointmentId)
                    .HOT_IsReleasedToFreelance__c = serviceResources.get(assignedResource.ServiceResourceId)
                    .HOT_IsFreelanceInterpreter__c;
                serviceAppointmentsToUpdate.add(serviceAppointments.get(assignedResource.ServiceAppointmentId));
            }
        }
        update serviceAppointmentsToUpdate;
    }
}
