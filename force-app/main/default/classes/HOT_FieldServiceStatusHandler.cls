public with sharing class HOT_FieldServiceStatusHandler extends MyTriggers {

	public override void onBeforeUpdate(Map<Id,sObject> triggerOldMap) {
		List<WorkOrder> changedWorkOrders = new List<WorkOrder>();
		List<WorkOrderLineItem> changedWorkOrderLineItems = new List<WorkOrderLineItem>();
		List<ServiceAppointment> changedServiceAppointments = new List<ServiceAppointment>();
		
		for(SObject record : records) {
			if(record.getSObjectType() == Schema.WorkOrder.getSObjectType()
				&& record.get('Status') != triggerOldMap.get(record.Id).get('Status')) {
					changedWorkOrders.add((WorkOrder)record);
			}
			if(record.getSObjectType() == Schema.WorkOrderLineItem.getSObjectType()
				&& record.get('Status') != triggerOldMap.get(record.Id).get('Status')) {
				changedWorkOrderLineItems.add((WorkOrderLineItem)record);
			}
			if(record.getSObjectType() == Schema.ServiceAppointment.getSObjectType()
				&& record.get('Status') != triggerOldMap.get(record.Id).get('Status')) {
				changedServiceAppointments.add((ServiceAppointment)record);
			}
		}

		if(changedWorkOrders.size() > 0) {
			updateRequestStatus(changedWorkOrders);
		}
		if(changedWorkOrderLineItems.size() > 0) {
			updateWorkOrderStatus(changedWorkOrderLineItems);
		}
		if(changedServiceAppointments.size() > 0) {
			updateWorkOrderLineItemStatus(changedServiceAppointments);
		}
	}

	public static void updateRequestStatus(List<WorkOrder> changedWorkOrders) {
		Map<String, String> statusMap = new Map<String, String>(); // legger ikke legg til "New" da den ikke skal
		statusMap.put('Reserved', 'Reserved');
		statusMap.put('Assigned', 'Assigned');
		statusMap.put('Partially Covered', 'Partially Covered');
		statusMap.put('Under Process', 'Under Process');
		statusMap.put('Not Covered', 'Not Covered');
		statusMap.put('Canceled', 'Canceled');
		statusMap.put('Declined', 'Declined');
		statusMap.put('Covered', 'Covered');
		
		List<HOT_Request__c> requestsToUpdate = new List<HOT_Request__c>();
		for(WorkOrder workOrder : changedWorkOrders) {
			if(statusMap.containsKey(workOrder.Status)) {
				requestsToUpdate.add(new HOT_Request__c(Id = workOrder.HOT_Request__c, Status__c = statusMap.get(workOrder.Status))); // filtrere ut de uten verdi i HOT_Request__c
			}
		}
		update requestsToUpdate;
	}

	private static void updateWorkOrderStatus(List<WorkOrderLineItem> changedWorkOrderLineItems) {

	}

	private static void updateWorkOrderLineItemStatus(List<ServiceAppointment> changedServiceAppointments) {

	}
}