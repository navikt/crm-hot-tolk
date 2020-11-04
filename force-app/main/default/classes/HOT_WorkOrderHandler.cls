public with sharing class HOT_WorkOrderHandler extends MyTriggers {
	
	public override void onAfterInsert() {
		createChildRecords((List<WorkOrder>) records);
	}

	public static void createChildRecords(List<WorkOrder> workOrders){
		List<Id> requestIds = new List<Id>();
		for(WorkOrder workOrder : workOrders){
			requestIds.add(workOrder.HOT_Request__c);
		}
		Map<Id, HOT_Request__c> requests = new Map<Id, HOT_Request__c>([SELECT Id, InterpretationMethod__r.Id, InterpretationMethodSecondary__r.Id, NumberOfInterpreters__c, NumberOfInterpretersSecondary__c 
																		FROM HOT_Request__c WHERE Id IN :requestIds]);
		List<WorkOrderLineItem> workOrderLineItems = new List<WorkOrderLineItem>();
		for(WorkOrder workOrder:workOrders){
			Map<Id, Decimal> workTypes = new Map<Id, Decimal>();
			workTypes.put(requests.get(workOrder.HOT_Request__c).InterpretationMethod__r.Id, requests.get(workOrder.HOT_Request__c).NumberOfInterpreters__c);
			if(requests.get(workOrder.HOT_Request__c).InterpretationMethodSecondary__c != null){
				workTypes.put(requests.get(workOrder.HOT_Request__c).InterpretationMethodSecondary__r.Id, requests.get(workOrder.HOT_Request__c).NumberOfInterpreters__c);
			}
			for(Id workTypeId:workTypes.keySet()){
				WorkOrderLineItem workOrderLineItem = new WorkOrderLineItem();
				workOrderLineItem.WorkOrderId = workOrder.Id;
				workOrderLineItem.City = workOrder.City;
				workOrderLineItem.Description = workOrder.Description;
				workOrderLineItem.EndDate = workOrder.EndDate;
				workOrderLineItem.HOT_InterpretationPostalCity__c = workOrder.HOT_InterpretationPostalCity__c;
				workOrderLineItem.HOT_InterpretationPostalCode__c = workOrder.HOT_InterpretationPostalCode__c;
				workOrderLineItem.HOT_InterpretationPostalStreet__c = workOrder.HOT_InterpretationStreet__c;
				workOrderLineItem.PostalCode = workOrder.PostalCode;
				workOrderLineItem.StartDate = workOrder.StartDate;
				workOrderLineItem.Street = workOrder.Street;
				workOrderLineItem.Subject = workOrder.Subject;
				workOrderLineItem.WorkTypeId = workTypeId;
				workOrderLineItem.HOT_NumberOfInterpreters__c = workTypes.get(workTypeId);
	
				workOrderLineItems.add(workOrderLineItem);
			}
		}
		insert workOrderLineItems;

	}

}
