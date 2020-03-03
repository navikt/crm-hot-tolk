public with sharing class HOT_FieldServiceStatusHandler extends MyTriggers {

	public override void onBeforeUpdate(Map<Id,sObject> triggerOldMap) {
		List<WorkOrder> changedWorkOrders = new List<WorkOrder>();
		List<WorkOrderLineItem> changedWorkOrderLineItems = new List<WorkOrderLineItem>();
		List<ServiceAppointment> changedServiceAppointments = new List<ServiceAppointment>();
		
		for(SObject record : records) {
			if(record.getSObjectType() == Schema.WorkOrder.getSObjectType()
				&& record.get('HOT_Request__c') != null
				&& record.get('Status') != triggerOldMap.get(record.Id).get('Status')) {
					changedWorkOrders.add((WorkOrder)record);
			}
			if(record.getSObjectType() == Schema.WorkOrderLineItem.getSObjectType()
				&& record.get('WorkOrderId') != null
				&& record.get('Status') != triggerOldMap.get(record.Id).get('Status')) {
				changedWorkOrderLineItems.add((WorkOrderLineItem)record);
			}
			if(record.getSObjectType() == Schema.ServiceAppointment.getSObjectType()
				&& record.get('ParentRecordId') != null
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
		Map<String, String> statusMap = new Map<String, String>(); // Map<Work Order Status, Request Status>
		//statusMap.put('Ny', 'Approved'); trenger ikke Ny da den aldri skal tilbake til denne statusen. Stemmer det?
		statusMap.put('Pågår', 'Under Process');
		statusMap.put('På venting', 'Assigned');
		statusMap.put('Fullført', 'Covered');
		statusMap.put('Avsluttet', 'XXX');
		statusMap.put('Kan ikke fullføre', 'Not Covered');
		statusMap.put('Avbrutt', 'Canceled');

		List<HOT_Request__c> requestsToUpdate = new List<HOT_Request__c>();
		for(WorkOrder workOrder : changedWorkOrders) {
			if(statusMap.containsKey(workOrder.Status)) {
				requestsToUpdate.add(new HOT_Request__c(Id = workOrder.HOT_Request__c, Status__c = statusMap.get(workOrder.Status)));
			}
		}
		update requestsToUpdate;
	}

	private static void updateWorkOrderStatus(List<WorkOrderLineItem> changedWorkOrderLineItems) {
		List<WorkOrder> workOrdersToUpdate = new List<WorkOrder>();
		for(WorkOrderLineItem workOrderLineItem : changedWorkOrderLineItems) {
			workOrdersToUpdate.add(new WorkOrder(Id = workOrderLineItem.WorkOrderId, Status = workOrderLineItem.Status));
		}
		update workOrdersToUpdate;
	}

	private static void updateWorkOrderLineItemStatus(List<ServiceAppointment> changedServiceAppointments) {
		List<WorkOrderLineItem> workOrderLineItemsToUpdate = new List<WorkOrderLineItem>();
		for(ServiceAppointment serviceAppointment : changedServiceAppointments) {
			if(serviceAppointment.ParentRecordId.getSobjectType() == Schema.WorkOrderLineItem.getSObjectType()) {
				workOrderLineItemsToUpdate.add(new WorkOrderLineItem(Id = serviceAppointment.ParentRecordId, Status = serviceAppointment.Status));
			}
		}
		update workOrderLineItemsToUpdate;
	}
}