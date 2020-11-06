public with sharing class HOT_ServiceAppointmentHandler extends MyTriggers {
	
	public override void onBeforeInsert(){
		setStatusDefault((List<ServiceAppointment>) records);
	}

	public static void setStatusDefault(List<ServiceAppointment> serviceAppointments){
		for(ServiceAppointment serviceAppointment : serviceAppointments){
			serviceAppointment.Status = 'None';
		}
	}
}
