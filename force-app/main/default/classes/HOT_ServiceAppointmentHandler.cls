public with sharing class HOT_ServiceAppointmentHandler extends MyTriggers {
	public override void onBeforeUpdate(Map<Id,sObject> triggerOldMap) {
		List<ServiceAppointment> recievedNewInterpreter= new List<ServiceAppointment>();
		
		for(SObject record : records) {
			if(record.getSObjectType() == Schema.ServiceAppointment.getSObjectType()
				&& record.get('ParentRecordId') != null
				&& record.get('Status') != triggerOldMap.get(record.Id).get('Status')
				&& record.get('Status') != 'Annul' 
				&& record.get('Status') != 'Cancelled' 
				&& record.get('HOT_ServiceResource__c') != triggerOldMap.get(record.Id).get('HOT_ServiceResource__c')) {
					recievedNewInterpreter.add((ServiceAppointment)record);
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
		update serviceAppointmentsToUpdate;
	}

	public override void onBeforeInsert(){
		setStatusDefault((List<ServiceAppointment>) records);
		setOwner((List<ServiceAppointment>) records);
	}

	public static void setStatusDefault(List<ServiceAppointment> serviceAppointments){
		for(ServiceAppointment serviceAppointment : serviceAppointments){
			serviceAppointment.Status = 'None';
		}
	}

	public static void setOwner(List<ServiceAppointment> serviceAppointments){
		for(ServiceAppointment serviceAppointment : serviceAppointments){
			if(serviceAppointment.HOT_Request__c != null) {
				serviceAppointment.OwnerId = serviceAppointment.HOT_RequestOwnerId__c;
			}
		}
	}
}
