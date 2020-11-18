public with sharing class HOT_ServiceAppointmentHandler extends MyTriggers {
	
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
