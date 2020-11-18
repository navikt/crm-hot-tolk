public without sharing class HOT_ServiceAppointmentHandler extends MyTriggers {

	public override void onBeforeInsert(){
		setStatusDefault((List<ServiceAppointment>) records);
		setOwner((List<ServiceAppointment>) records);
		setFieldsByPreferredInterpreter((List<ServiceAppointment>) records);
	}
	public override void onBeforeUpdate(Map<Id, sObject> triggerOldMap){
		List<ServiceAppointment> updatedServiceAppointment = new List<ServiceAppointment>();
		for(ServiceAppointment serviceAppointment:(List<ServiceAppointment>) records){
			if(triggerOldMap.get(serviceAppointment.Id).get('HOT_PreferredInterpreter__c') != ServiceAppointment.HOT_PreferredInterpreter__c && ServiceAppointment.HOT_PreferredInterpreter__c != null){
				updatedServiceAppointment.add(serviceAppointment);
			}
		}
		if(!updatedServiceAppointment.isEmpty()){
			updatedServiceAppointment = setFieldsByPreferredInterpreter(updatedServiceAppointment);
		}
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
		for(ServiceAppointment serviceAppointment : recievedNewInterpreter) {
			serviceAppointment.HOT_CanceledByInterpreter__c = false;		
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

	public static List<ServiceAppointment> setFieldsByPreferredInterpreter(List<ServiceAppointment> serviceAppointments){
			List<Id> preferredResourceId = new List<Id>();
		List<ServiceAppointment> serviceAppointmentsToUpdate = new List<ServiceAppointment>();
		for(ServiceAppointment serviceAppointment : serviceAppointments){
			if(serviceAppointment.HOT_PreferredInterpreter__c != null){
				preferredResourceId.add(serviceAppointment.HOT_PreferredInterpreter__c);
				serviceAppointmentsToUpdate.add(serviceAppointment);
			}
		}
		Map<Id, ServiceResource> serviceResources = new Map<Id, ServiceResource>([SELECT Id, HOT_ServiceTerritory__c, HOT_IsFreelanceInterpreter__c, HOT_IsEmployedInterpreter__c FROM ServiceResource WHERE Id IN :preferredResourceId]);
		for(ServiceAppointment serviceAppointment : serviceAppointmentsToUpdate){
			if(serviceAppointment.ServiceTerritoryId != serviceResources.get(serviceAppointment.HOT_PreferredInterpreter__c).HOT_ServiceTerritory__c){
				serviceAppointment.ServiceTerritoryId = serviceResources.get(serviceAppointment.HOT_PreferredInterpreter__c).HOT_ServiceTerritory__c;
			}

			if(serviceAppointment.HOT_IsReleasedToFreelance__c != serviceResources.get(serviceAppointment.HOT_PreferredInterpreter__c).HOT_IsFreelanceInterpreter__c){
				serviceAppointment.HOT_IsReleasedToFreelance__c = serviceResources.get(serviceAppointment.HOT_PreferredInterpreter__c).HOT_IsFreelanceInterpreter__c;
				serviceAppointment.HOT_IsEmployedInterpreter__c = serviceResources.get(serviceAppointment.HOT_PreferredInterpreter__c).HOT_IsEmployedInterpreter__c;
			}
		}
		return serviceAppointmentsToUpdate;
	}

}
