public with sharing class HOT_WorkOrderHandler extends MyTriggers {
	
	public override void onAfterInsert() {
		List<Id> requestIds = new List<Id>();
		for(WorkOrder workOrder:(List<WorkOrder>) records){
			requestIds.add(workOrder.HOT_Request__c);
		}
		List<WorkOrder> approvedWorkOrders = new List<WorkOrder>();
		Map<Id, HOT_Request__c> requests = new Map<Id, HOT_Request__c>([SELECT Id, Status__c FROM HOT_Request__c WHERE Id IN :requestIds]);
		for(WorkOrder workOrder:(List<WorkOrder>) records){
			if(requests.get(workOrder.HOT_Request__c).Status__c != 'Åpen' && requests.get(workOrder.HOT_Request__c).Status__c != 'Avlyst' && requests.get(workOrder.HOT_Request__c).Status__c != 'Annullert'){
				approvedWorkOrders.add(workOrder);
			}
		}
		if(approvedWorkOrders.size()>0){
			createChildRecords(approvedWorkOrders);
		}
	}

	public static void createChildRecords(List<WorkOrder> workOrders){
		List<WorkOrderLineItem> workOrderLineItems = new List<WorkOrderLineItem>();
		for(WorkOrder workOrder:workOrders){
			if(workOrder.LineItemCount == 0){
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
		}
		insert workOrderLineItems;

	}

}
