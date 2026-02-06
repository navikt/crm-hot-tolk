ServiceResource sr = [
    SELECT Id, Name 
    FROM ServiceResource 
    WHERE Name = 'Darth Vader' 
    AND IsActive = true 
    LIMIT 1
];

ServiceAppointment sa = [
    SELECT Id, AppointmentNumber, Status 
    FROM ServiceAppointment 
    WHERE Status NOT IN ('Completed', 'Canceled') 
    ORDER BY CreatedDate ASC 
    LIMIT 1
];

List<AssignedResource> existingAssignments = [
    SELECT Id 
    FROM AssignedResource 
    WHERE ServiceAppointmentId = :sa.Id 
    AND ServiceResourceId = :sr.Id
];

if (existingAssignments.isEmpty()) {
    AssignedResource ar = new AssignedResource(
        ServiceAppointmentId = sa.Id,
        ServiceResourceId = sr.Id
    );
    insert ar;

    sa.Status = 'Dispatched';
    update sa;

    System.debug('Suksess: ' + sr.Name + ' er tildelt ' + sa.AppointmentNumber);
} else {
    System.debug('Info: Brukeren er allerede tildelt denne avtalen.');
}