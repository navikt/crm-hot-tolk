List<ServiceAppointment> serviceAppointments = [
    SELECT Id, Status, HOT_IsReleasedToFreelance__c
    FROM ServiceAppointment
    WHERE Status = 'None' AND HOT_IsReleasedToFreelance__c = TRUE
];
if (serviceAppointments.size() > 0) {
    for (ServiceAppointment serviceAppointment : serviceAppointments) {
        serviceAppointment.Status = 'Released to Freelance';
    }
    update serviceAppointments;
}
