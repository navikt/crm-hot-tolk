public without sharing class HOT_WorkOrderHandler extends MyTriggers {
	
	public override void onBeforeInsert(){
		setStatusDefault((List<WorkOrder>) records);
		setOwner((List<WorkOrder>) records);
	}
	
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
		updateNumberOfWorkOrdersOnRequest((List<WorkOrder>) records);
	}
	public override void onAfterDelete() {
		updateNumberOfWorkOrdersOnRequest((List<WorkOrder>) records);
	}

	public override void onAfterUndelete() {
		updateNumberOfWorkOrdersOnRequest((List<WorkOrder>) records);
	}


	public static void createChildRecords(List<WorkOrder> workOrders){

		//Getting parent requests
		List<Id> requestIds = new List<Id>();
		for(WorkOrder workOrder : workOrders){
			requestIds.add(workOrder.HOT_Request__c);
		}
		Map<Id, HOT_Request__c> requests = new Map<Id, HOT_Request__c>([SELECT Id, InterpretationMethod__r.Id, InterpretationMethodSecondary__r.Id, NumberOfInterpreters__c, NumberOfInterpretersSecondary__c 
																		FROM HOT_Request__c WHERE Id IN :requestIds]);

		//Each workOrder should have 1 or more childs (workOrderLineItems)
		List<WorkOrderLineItem> workOrderLineItems = new List<WorkOrderLineItem>();
		for(WorkOrder workOrder:workOrders){
			
			//Check if status New

			//Fetching the workTypes from parent requests. If the request only has 1 workType, only one child workOrderLineItem should be created
			Map<Id, Decimal> workTypes = new Map<Id, Decimal>();
			workTypes.put(requests.get(workOrder.HOT_Request__c).InterpretationMethod__r.Id, requests.get(workOrder.HOT_Request__c).NumberOfInterpreters__c);
			if(requests.get(workOrder.HOT_Request__c).InterpretationMethodSecondary__c != null){
				workTypes.put(requests.get(workOrder.HOT_Request__c).InterpretationMethodSecondary__r.Id, requests.get(workOrder.HOT_Request__c).NumberOfInterpretersSecondary__c);
			}

			//If there are no child workOrderLineItems for this workOrder, they should be created 
			if(workOrder.LineItemCount == 0){
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
		}
		insert workOrderLineItems;
	}

	public static void setStatusDefault(List<WorkOrder> workOrders){
		for(WorkOrder workOrder : workOrders){
			workOrder.Status = 'New';
		}
	}

	public static void setOwner(List<WorkOrder> workOrders){
		for(WorkOrder workOrder : workOrders){
			if(WorkOrder.HOT_Request__c != null) {
				workOrder.OwnerId = workOrder.HOT_RequestOwnerId__c;
			}
		}
	}
	public static void updateNumberOfWorkOrdersOnRequest(List<WorkOrder> workOrders){
		List<Id> requestIds = new List<Id>();
		for(WorkOrder workOrder:workOrders){
			requestIds.add(workOrder.HOT_Request__c);
		}
		List<HOT_Request__c> requests = [SELECT Id, NumberOfWorkOrders__c, (SELECT Id FROM HOT_Request__c.Work_Orders__r WHERE Status NOT IN ('Annul', 'Canceled')) FROM HOT_Request__c WHERE Id IN :requestIds];
		for(HOT_Request__c request:requests){
			request.NumberOfWorkOrders__c = request.Work_Orders__r.size();
		}
		update requests;
	}

}


