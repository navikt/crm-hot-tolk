public with sharing class HOT_ServiceAppointmentHandler extends MyTriggers {
	
	public override void onBeforeInsert() {
		setStatusDefault((List<ServiceAppointment>) records);
		setOwner((List<ServiceAppointment>) records);
	}

	public override void onBeforeUpdate(Map<Id,sObject> triggerOldMap) {
		
		List<ServiceAppointment> serviceAppointmentsWithChangedStatusOrResource = new List<ServiceAppointment>();
		
		for(ServiceAppointment serviceAppointment : (List<ServiceAppointment>) records) {
			if(serviceAppointment.Status != triggerOldMap.get(serviceAppointment.Id).get('Status') || serviceAppointment.HOT_ServiceResource__c != triggerOldMap.get(serviceAppointment.Id).get('HOT_ServiceResource__c')) {
				serviceAppointmentsWithChangedStatusOrResource.add(serviceAppointment);
			}
		}

		if(serviceAppointmentsWithChangedStatusOrResource.size()>0) {
			createHistoricallyAssignedResources(serviceAppointmentsWithChangedStatusOrResource, triggerOldMap);
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
			// Added resource
			if(!serviceAppointment.HOT_DoNotCreateHAR__c && serviceAppointment.HOT_ServiceResource__c != null && oldServiceAppointment.HOT_ServiceResource__c == null) {
				HOT_HistoricallyAssignedResource__c historicallyAssignedResource = new HOT_HistoricallyAssignedResource__c();
				historicallyAssignedResource.ServiceAppointment__c = serviceAppointment.Id;
				historicallyAssignedResource.ServiceResource__c = serviceAppointment.HOT_ServiceResource__c;
				historicallyAssignedResource.Status__c = serviceAppointment.Status;
				newHistoricallyAssignedResources.add(historicallyAssignedResource);
			}
			// Same resource, but status has changed
			if(!serviceAppointment.HOT_DoNotCreateHAR__c && serviceAppointment.HOT_ServiceResource__c != null && serviceAppointment.HOT_ServiceResource__c == oldServiceAppointment.HOT_ServiceResource__c) {
				HOT_HistoricallyAssignedResource__c historicallyAssignedResource = new HOT_HistoricallyAssignedResource__c();
				historicallyAssignedResource.ServiceAppointment__c = serviceAppointment.Id;
				historicallyAssignedResource.ServiceResource__c = serviceAppointment.HOT_ServiceResource__c;
				historicallyAssignedResource.Status__c = serviceAppointment.Status;
				newHistoricallyAssignedResources.add(historicallyAssignedResource);
			}
			// Changed resource
			if(!serviceAppointment.HOT_DoNotCreateHAR__c && serviceAppointment.HOT_ServiceResource__c != null && oldServiceAppointment.HOT_ServiceResource__c != null && serviceAppointment.HOT_ServiceResource__c != oldServiceAppointment.HOT_ServiceResource__c) {
				HOT_HistoricallyAssignedResource__c historicallyAssignedResourceOld = new HOT_HistoricallyAssignedResource__c();
				historicallyAssignedResourceOld.ServiceAppointment__c = serviceAppointment.Id;
				historicallyAssignedResourceOld.ServiceResource__c = oldServiceAppointment.HOT_ServiceResource__c;
				historicallyAssignedResourceOld.Status__c = 'Tolk tatt av oppdraget';
				newHistoricallyAssignedResources.add(historicallyAssignedResourceOld);

				HOT_HistoricallyAssignedResource__c historicallyAssignedResourceNew = new HOT_HistoricallyAssignedResource__c();
				historicallyAssignedResourceNew.ServiceAppointment__c = serviceAppointment.Id;
				historicallyAssignedResourceNew.ServiceResource__c = serviceAppointment.HOT_ServiceResource__c;
				historicallyAssignedResourceNew.Status__c = serviceAppointment.Status;
				newHistoricallyAssignedResources.add(historicallyAssignedResourceNew);
			}
			// Removed resource
			if(!serviceAppointment.HOT_DoNotCreateHAR__c && serviceAppointment.HOT_ServiceResource__c == null && oldServiceAppointment.HOT_ServiceResource__c != null) {
				HOT_HistoricallyAssignedResource__c historicallyAssignedResource = new HOT_HistoricallyAssignedResource__c();
				historicallyAssignedResource.ServiceAppointment__c = serviceAppointment.Id;
				historicallyAssignedResource.ServiceResource__c = oldServiceAppointment.HOT_ServiceResource__c;
				historicallyAssignedResource.Status__c = 'Tolk tatt av oppdraget';
				newHistoricallyAssignedResources.add(historicallyAssignedResource);
			}
			// Only status change, no resource connected to service appointment
			if(!serviceAppointment.HOT_DoNotCreateHAR__c && serviceAppointment.HOT_ServiceResource__c == null && serviceAppointment.HOT_ServiceResource__c == oldServiceAppointment.HOT_ServiceResource__c) {
				// Do noting
			}
		}
		insert newHistoricallyAssignedResources;
	}
}
