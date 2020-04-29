//Kan den ikke være with sharing, og så har vi sharing rule for permset: frilans: if(realeseToFrilans){ SHARE with frilans}
//Deling kan føre til mange problemer. Frilans får tilgang og kan søke opp i tolk-appen
public class HOT_ServiceAppointmentListControllerAll {
	
	@AuraEnabled(cacheable = true)
	public static List<ServiceAppointment> getAllServiceAppointments() {	
		List<ServiceAppointment> serviceAppointments = [SELECT AppointmentNumber,
		Subject, SchedStartTime, SchedEndTime, 
		Address, HOT_InterpretationStreet__c, HOT_InterpretationPostalCode__c, HOT_InterpretationPostalCity__c
		FROM ServiceAppointment 
		//WHERE released=:true AND Status =: 'Open'
		ORDER BY SchedStartTime ASC];
		return serviceAppointments;
	}

}

