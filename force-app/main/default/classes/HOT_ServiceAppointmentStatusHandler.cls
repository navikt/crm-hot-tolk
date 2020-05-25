public without sharing class HOT_ServiceAppointmentStatusHandler extends MyTriggers {
	
	public override void onAfterUpdate(Map<Id,sObject> triggerOldMap) {
		List<ServiceAppointment> changedStatusServiceAppointments = new List<ServiceAppointment>();
		
		for(SObject record : records) {
			if(record.getSObjectType() == Schema.ServiceAppointment.getSObjectType()
				&& record.get('ParentRecordId') != null
				&& record.get('Status') != triggerOldMap.get(record.Id).get('Status')) {
					changedStatusServiceAppointments.add((ServiceAppointment)record);
			}
		}
		if(changedStatusServiceAppointments.size() > 0) {
			updateWorkOrderLineItemStatus(changedStatusServiceAppointments);
			updateInterestedResourceStatus(changedStatusServiceAppointments);
		}
	}

	private static void updateWorkOrderLineItemStatus(List<ServiceAppointment> changedServiceAppointments) {
		List<WorkOrderLineItem> workOrderLineItemsToUpdate = new List<WorkOrderLineItem>();
		for(ServiceAppointment serviceAppointment : changedServiceAppointments) {
			if(serviceAppointment.ParentRecordId.getSobjectType() == Schema.WorkOrderLineItem.getSObjectType()) {
				WorkOrderLineItem workOrderToAdd = new WorkOrderLineItem(Id = serviceAppointment.ParentRecordId, HOT_IsUpdateStatus__c = true);
				if(!workOrderLineItemsToUpdate.contains(workOrderToAdd)) {
					workOrderLineItemsToUpdate.add(workOrderToAdd);
				}
			}
		}
		update workOrderLineItemsToUpdate;
	}

	private static void updateInterestedResourceStatus(List<ServiceAppointment> changedServiceAppointments) {
		List<Id> serviceAppointmentIds = new List<Id>();
		for(ServiceAppointment serviceAppointment : changedServiceAppointments) {
			serviceAppointmentIds.add(serviceAppointment.Id);
		}

		List<HOT_InterestedResource__c> interestedResourcesToUpdate = [SELECT Id, Status__c FROM HOT_InterestedResource__c WHERE ServiceAppointment__c IN: serviceAppointmentIds];
		for(HOT_InterestedResource__c interestedResource:interestedResourcesToUpdate){
			interestedResource.Status__c = 'Canceled';
		}
		update interestedResourcesToUpdate;
	}
}
