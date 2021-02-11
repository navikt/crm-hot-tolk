List<HOT_InterestedResource__c> interestedResources = [
    SELECT Id, Status__c, ServiceAppointment__c
    FROM HOT_InterestedResource__c
    WHERE
        Status__c = 'Not Assigned'
        AND ServiceAppointment__r.Status NOT IN (
            'None',
            'Released to Freelance'
        )
];

System.debug(interestedResources);
List<Id> serviceAppointmentIds = new List<Id>();
for (HOT_InterestedResource__c interestedResource : interestedResources) {
    serviceAppointmentIds.add(interestedResource.ServiceAppointment__c);
}
List<AssignedResource> assignedResources = [
    SELECT Id, ServiceAppointmentId, ServiceResourceId
    FROM AssignedResource
    WHERE ServiceAppointmentId IN :serviceAppointmentIds
];

List<HOT_InterestedResource__c> updatedInterestedResources = HOT_AssignedResourceHandler.updateInterestedResourceStatus(
    assignedResources
);
System.debug(updatedInterestedResources);
update updatedInterestedResources;
