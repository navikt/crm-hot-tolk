trigger HOT_ServiceAppointmentMessageTrigger on HOT_ServiceAppointmentMessage__c(after insert) {
    MyTriggers.run();
}
