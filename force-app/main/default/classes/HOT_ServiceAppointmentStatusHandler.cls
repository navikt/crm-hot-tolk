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
}
