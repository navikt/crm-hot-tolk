public with sharing class HOT_ServiceAppointmentListControllerMy {

	@AuraEnabled(cacheable = true)
	public static List<ServiceAppointment> getMyServiceAppointments() {
		List<ServiceAppointment> serviceAppointments = [SELECT AppointmentNumber, Subject, SchedStartTime, SchedEndTime, 
		Address, HOT_InterpretationStreet__c, HOT_InterpretationPostalCode__c, HOT_InterpretationPostalCity__c
		FROM ServiceAppointment 
		ORDER BY SchedStartTime ASC];
		return serviceAppointments;
	}
    
}
