public with sharing class HOT_WorkOrderHandler extends MyTriggers {
	
	public override void onAfterInsert() {
		createChildRecords((List<WorkOrder>) records);
	}

	public static void createChildRecords(List<WorkOrder> workOrders){
		List<WorkOrderLineItem> workOrderLineItems = new List<WorkOrderLineItem>();
		for(WorkOrder workOrder:workOrders){
			WorkOrderLineItem workOrderLineItem = new WorkOrderLineItem();

			workOrderLineItem.WorkOrderId = workOrder.Id;
			workOrderLineItem.City = workOrder.City;
			workOrderLineItem.Description = workOrder.Description;
			workOrderLineItem.EndDate = workOrder.EndDate;
			workOrderLineItem.HOT_InterpretationPostalCity__c = workOrder.HOT_InterpretationPostalCity__c;
			workOrderLineItem.HOT_InterpretationPostalCode__c = workOrder.HOT_InterpretationPostalCode__c;
			workOrderLineItem.HOT_InterpretationPostalStreet__c = workOrder.HOT_InterpretationStreet__c;
			workOrderLineItem.HOT_NumberOfInterpreters__c = workOrder.HOT_NumberOfInterpreters__c;
			workOrderLineItem.PostalCode = workOrder.PostalCode;
			workOrderLineItem.StartDate = workOrder.StartDate;
			workOrderLineItem.Street = workOrder.Street;
			workOrderLineItem.Subject = workOrder.Subject;
			workOrderLineItem.WorkTypeId = workOrder.WorkTypeId;

			workOrderLineItems.add(workOrderLineItem);
		}
		insert workOrderLineItems;

	}

}
