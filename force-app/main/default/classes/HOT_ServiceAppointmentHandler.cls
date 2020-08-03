public without sharing class HOT_ServiceAppointmentHandler extends MyTriggers {
	
	public override void onBeforeUpdate(Map<Id,sObject> triggerOldMap) {
		List<ServiceAppointment> updatedServiceAppointments = new List<ServiceAppointment>();

		for(ServiceAppointment serviceAppointment : (List<ServiceAppointment>) records) {
			if(serviceAppointment.Status != triggerOldMap.get(serviceAppointment.Id).get('Status')){
				updatedServiceAppointments.add(serviceAppointment);
			}
		}

		if(updatedServiceAppointments.size() > 0) {
			updateAssignedResourceOnServiceAppointment(updatedServiceAppointments);
		}
	}

	private static void updateAssignedResourceOnServiceAppointment(List<ServiceAppointment> serviceAppointments) {
		List<AssignedResource> assignedResources = [SELECT Id, ServiceAppointmentId, ServiceResourceId, ServiceResource.RelatedRecordId FROM AssignedResource WHERE ServiceAppointmentId IN :serviceAppointments];
		Map<Id,List<AssignedResource>> assignedResourcesToServiceAppointmentIdMap = new Map<Id,List<AssignedResource>>();
		
		for(AssignedResource assignedResource : assignedResources) {
			if(assignedResourcesToServiceAppointmentIdMap.containsKey(assignedResource.ServiceAppointmentId)) {
				assignedResourcesToServiceAppointmentIdMap.get(assignedResource.ServiceAppointmentId).add(assignedResource);
			} else {
				List<AssignedResource> assignedResourceList = new List<AssignedResource>();
				assignedResourceList.add(assignedResource);
				assignedResourcesToServiceAppointmentIdMap.put(assignedResource.ServiceAppointmentId, assignedResourceList);
			}
		}

		for(ServiceAppointment serviceAppointment : serviceAppointments) {
			if(assignedResourcesToServiceAppointmentIdMap.containsKey(serviceAppointment.Id) && assignedResourcesToServiceAppointmentIdMap.get(serviceAppointment.Id).size() > 0) {
				serviceAppointment.HOT_AssignedResourceId__c = assignedResourcesToServiceAppointmentIdMap.get(serviceAppointment.Id)[0].ServiceResource.RelatedRecordId;
				serviceAppointment.HOT_ServiceResource__c = assignedResourcesToServiceAppointmentIdMap.get(serviceAppointment.Id)[0].ServiceResourceId;
			} else {
				serviceAppointment.HOT_AssignedResourceId__c = null;
				serviceAppointment.HOT_ServiceResource__c = null;
			}
			if(serviceAppointment.Status == 'None') {
				serviceAppointment.HOT_AssignedResourceId__c = null;
				serviceAppointment.HOT_ServiceResource__c = null;
			}
		}
	}
}
