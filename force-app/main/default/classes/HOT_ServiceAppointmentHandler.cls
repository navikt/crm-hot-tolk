public without sharing class HOT_ServiceAppointmentHandler extends MyTriggers {

	public override void onBeforeInsert(){
		setStatusDefault((List<ServiceAppointment>) records);
		setOwner((List<ServiceAppointment>) records);
	}

	public override void onBeforeUpdate(Map<Id,sObject> triggerOldMap) {
		List<ServiceAppointment> recievedNewInterpreter= new List<ServiceAppointment>();
		
		for(ServiceAppointment serviceApp:(List<ServiceAppointment>) records) {
			if(serviceApp.get('HOT_ServiceResource__c') != null &&
				serviceApp.get('HOT_ServiceResource__c') != triggerOldMap.get(serviceApp.Id).get('HOT_ServiceResource__c')) {
					recievedNewInterpreter.add(serviceApp);
			}
		}

		if(recievedNewInterpreter.size() > 0) {
			updateCancelledByInterpreter(recievedNewInterpreter);
		}
	}

	private static void updateCancelledByInterpreter(List<ServiceAppointment> recievedNewInterpreter) {
		List<ServiceAppointment> serviceAppointmentsToUpdate = new List<ServiceAppointment>();
		for(ServiceAppointment serviceAppointment : recievedNewInterpreter) {
			serviceAppointment.HOT_CanceledByInterpreter__c = false;
			serviceAppointmentsToUpdate.add(serviceAppointment);			
		}
	}

	private static void setStatusDefault(List<ServiceAppointment> serviceAppointments){
		for(ServiceAppointment serviceAppointment : serviceAppointments){
			serviceAppointment.Status = 'None';
		}
	}

	private static void setOwner(List<ServiceAppointment> serviceAppointments){
		for(ServiceAppointment serviceAppointment : serviceAppointments){
			if(serviceAppointment.HOT_Request__c != null) {
				serviceAppointment.OwnerId = serviceAppointment.HOT_RequestOwnerId__c;
			}
		}
	}
}
