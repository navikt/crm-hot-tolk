
List<AssignedResource> assignedResources = [
    SELECT Id
    FROM AssignedResource
    WHERE ServiceAppointment.Status = 'Cannot Complete'
];
delete assignedResources;