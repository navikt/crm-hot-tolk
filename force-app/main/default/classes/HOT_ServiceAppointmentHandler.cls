public without sharing class HOT_ServiceAppointmentHandler extends MyTriggers {
	
	public override void onBeforeInsert() {
		setStatusDefault((List<ServiceAppointment>) records);
		setOwner((List<ServiceAppointment>) records);
		setFieldsByPreferredInterpreter((List<ServiceAppointment>) records);
	}
	public override void onBeforeUpdate(Map<Id, sObject> triggerOldMap) {
		
		List<ServiceAppointment> recievedNewInterpreter= new List<ServiceAppointment>();
		List<ServiceAppointment> updatedServiceAppointment = new List<ServiceAppointment>();
		List<ServiceAppointment> serviceAppointmentsWithChangedStatusOrResource = new List<ServiceAppointment>();
		
		for(ServiceAppointment serviceAppointment : (List<ServiceAppointment>) records){
			if(serviceAppointment.get('HOT_ServiceResource__c') != null &&
			serviceAppointment.get('HOT_ServiceResource__c') != triggerOldMap.get(serviceAppointment.Id).get('HOT_ServiceResource__c')) {
					recievedNewInterpreter.add(serviceAppointment);
			}
			if(triggerOldMap.get(serviceAppointment.Id).get('HOT_PreferredInterpreter__c') != ServiceAppointment.HOT_PreferredInterpreter__c && ServiceAppointment.HOT_PreferredInterpreter__c != null){
				updatedServiceAppointment.add(serviceAppointment);
			}
			if(serviceAppointment.Status != triggerOldMap.get(serviceAppointment.Id).get('Status') || serviceAppointment.HOT_ServiceResource__c != triggerOldMap.get(serviceAppointment.Id).get('HOT_ServiceResource__c')) {
				serviceAppointmentsWithChangedStatusOrResource.add(serviceAppointment);
			}
		}
		if(!updatedServiceAppointment.isEmpty()) {
			updatedServiceAppointment = setFieldsByPreferredInterpreter(updatedServiceAppointment);
		}
		if(recievedNewInterpreter.size() > 0) {
			updateCancelledByInterpreter(recievedNewInterpreter);
		}
		if(serviceAppointmentsWithChangedStatusOrResource.size()>0) {
			createHistoricallyAssignedResources(serviceAppointmentsWithChangedStatusOrResource, triggerOldMap);
		}
	}

	private static void updateCancelledByInterpreter(List<ServiceAppointment> recievedNewInterpreter) {
		for(ServiceAppointment serviceAppointment : recievedNewInterpreter) {
			serviceAppointment.HOT_CanceledByInterpreter__c = false;		
		}
	}

	private static void setStatusDefault(List<ServiceAppointment> serviceAppointments) {
		for(ServiceAppointment serviceAppointment : serviceAppointments) {
			serviceAppointment.Status = 'None';
		}
	}

	private static void setOwner(List<ServiceAppointment> serviceAppointments) {
		for(ServiceAppointment serviceAppointment : serviceAppointments) {
			if(serviceAppointment.HOT_Request__c != null) {
				serviceAppointment.OwnerId = serviceAppointment.HOT_RequestOwnerId__c;
			}
		}
	}

	private static void createHistoricallyAssignedResources(List<ServiceAppointment> serviceAppointments, Map<Id,sObject> triggerOldMap) {
		
		List<HOT_HistoricallyAssignedResource__c> newHistoricallyAssignedResources = new List<HOT_HistoricallyAssignedResource__c>();
		
		for(ServiceAppointment serviceAppointment : serviceAppointments) {
			
			ServiceAppointment oldServiceAppointment = (ServiceAppointment)triggerOldMap.get(serviceAppointment.Id);
			
			// First check if we sould create a Historically Assigned Resource for this change
			if(serviceAppointment.HOT_DoNotCreateHAR__c) {
				serviceAppointment.HOT_DoNotCreateHAR__c = false;

			} else {
				// Added resource
				if(serviceAppointment.HOT_ServiceResource__c != null && oldServiceAppointment.HOT_ServiceResource__c == null) {
					HOT_HistoricallyAssignedResource__c historicallyAssignedResource = new HOT_HistoricallyAssignedResource__c();
					historicallyAssignedResource.ServiceAppointment__c = serviceAppointment.Id;
					historicallyAssignedResource.ServiceResource__c = serviceAppointment.HOT_ServiceResource__c;
					historicallyAssignedResource.Status__c = getTranslatedStatus(serviceAppointment.Status);
					newHistoricallyAssignedResources.add(historicallyAssignedResource);
				}
				// Same resource, but status has changed
				if(serviceAppointment.HOT_ServiceResource__c != null && serviceAppointment.HOT_ServiceResource__c == oldServiceAppointment.HOT_ServiceResource__c) {
					HOT_HistoricallyAssignedResource__c historicallyAssignedResource = new HOT_HistoricallyAssignedResource__c();
					historicallyAssignedResource.ServiceAppointment__c = serviceAppointment.Id;
					historicallyAssignedResource.ServiceResource__c = serviceAppointment.HOT_ServiceResource__c;
					historicallyAssignedResource.Status__c = getTranslatedStatus(serviceAppointment.Status);
					newHistoricallyAssignedResources.add(historicallyAssignedResource);
				}
				// Changed resource
				if(serviceAppointment.HOT_ServiceResource__c != null && oldServiceAppointment.HOT_ServiceResource__c != null && serviceAppointment.HOT_ServiceResource__c != oldServiceAppointment.HOT_ServiceResource__c) {
					HOT_HistoricallyAssignedResource__c historicallyAssignedResourceOld = new HOT_HistoricallyAssignedResource__c();
					historicallyAssignedResourceOld.ServiceAppointment__c = serviceAppointment.Id;
					historicallyAssignedResourceOld.ServiceResource__c = oldServiceAppointment.HOT_ServiceResource__c;
					historicallyAssignedResourceOld.Status__c = 'Tolk tatt av oppdraget';
					newHistoricallyAssignedResources.add(historicallyAssignedResourceOld);

					HOT_HistoricallyAssignedResource__c historicallyAssignedResourceNew = new HOT_HistoricallyAssignedResource__c();
					historicallyAssignedResourceNew.ServiceAppointment__c = serviceAppointment.Id;
					historicallyAssignedResourceNew.ServiceResource__c = serviceAppointment.HOT_ServiceResource__c;
					historicallyAssignedResourceNew.Status__c = getTranslatedStatus(serviceAppointment.Status);
					newHistoricallyAssignedResources.add(historicallyAssignedResourceNew);
				}
				// Removed resource
				if(serviceAppointment.HOT_ServiceResource__c == null && oldServiceAppointment.HOT_ServiceResource__c != null) {
					HOT_HistoricallyAssignedResource__c historicallyAssignedResource = new HOT_HistoricallyAssignedResource__c();
					historicallyAssignedResource.ServiceAppointment__c = serviceAppointment.Id;
					historicallyAssignedResource.ServiceResource__c = oldServiceAppointment.HOT_ServiceResource__c;
					historicallyAssignedResource.Status__c = 'Tolk tatt av oppdraget';
					newHistoricallyAssignedResources.add(historicallyAssignedResource);
				}
				// Only status change, no resource connected to service appointment
				if(serviceAppointment.HOT_ServiceResource__c == null && serviceAppointment.HOT_ServiceResource__c == oldServiceAppointment.HOT_ServiceResource__c) {
					// Do noting
				}					
			}
		}
		insert newHistoricallyAssignedResources;
	}

	private static String getTranslatedStatus (String status) {
		if(status == 'Annul') return 'Annullert';
		if(status == 'Canceled') return 'Avlyst';
		if(status == 'Cannot Complete') return 'Udekket';
		if(status == 'Completed') return 'Dekket';
		if(status == 'Dispatched') return 'Tildelt';
		if(status == 'In Progress') return 'Pågår';
		if(status == 'None') return 'Åpen';
		if(status == 'Released to Freelance') return 'Frigitt til frilanstolker';
		if(status == 'Scheduled') return 'Reservert';

		return '';
	}

	public static List<ServiceAppointment> setFieldsByPreferredInterpreter(List<ServiceAppointment> serviceAppointments) {
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
