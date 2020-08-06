public without sharing class HOT_WorkOrderStatusHandler extends MyTriggers {
	
	public override void onAfterUpdate(Map<Id,sObject> triggerOldMap) {
		List<WorkOrder> changedStatusWorkOrders = new List<WorkOrder>();
		
		for(SObject record : records) {
			if(record.getSObjectType() == Schema.WorkOrder.getSObjectType()
				&& record.get('HOT_Request__c') != null
				&& record.get('Status') != triggerOldMap.get(record.Id).get('Status')) {
					changedStatusWorkOrders.add((WorkOrder)record);
			}
		}

		if(changedStatusWorkOrders.size() > 0) {
			updateRequestStatus(changedStatusWorkOrders);
		}
	}

	public override void onBeforeUpdate(Map<Id,sObject> triggerOldMap) {
		List<WorkOrder> updateStatusWorkOrders = new List<WorkOrder>();

		for(SObject record : records) {
			System.debug('record: ' + record);
			if(record.getSObjectType() == Schema.WorkOrder.getSObjectType()
				&& record.get('HOT_IsUpdateStatus__c') == true) {
					updateStatusWorkOrders.add((WorkOrder)record);
			}
		}

		if(updateStatusWorkOrders.size() > 0) {
			updateWorkOrderStatus(updateStatusWorkOrders);
		}
	}

	public static void updateRequestStatus(List<WorkOrder> changedWorkOrders) {
		Map<String, String> statusMap = new Map<String, String>(); // Map<Work Order Status, Request Status>
		statusMap.put('New', 'Godkjent');
		statusMap.put('Scheduled', 'Reservert');
		statusMap.put('Dispatched', 'Tildelt');
		statusMap.put('In Progress', 'Pågår');
		statusMap.put('Completed', 'Dekket');
		statusMap.put('Partially Complete', 'Delvis dekket');
		statusMap.put('Cannot Complete', 'Udekket');
		statusMap.put('Canceled', 'Avlyst');
		statusMap.put('Annul', 'Annullert');

		List<HOT_Request__c> requestsToUpdate = new List<HOT_Request__c>();
		for(WorkOrder workOrder : changedWorkOrders) {
			if(statusMap.containsKey(workOrder.Status)) {
				HOT_Request__c requestToAdd = new HOT_Request__c(Id = workOrder.HOT_Request__c, Status__c = statusMap.get(workOrder.Status)); 
				if(!requestsToUpdate.contains(requestToAdd)) {
					requestsToUpdate.add(requestToAdd);
				}
			}
		}
		update requestsToUpdate;
	}

	private static void updateWorkOrderStatus(List<WorkOrder> workOrders) {
		List<WorkOrderLineItem> workOrderLineItems = [SELECT WorkOrderId, Status FROM WorkOrderLineItem WHERE WorkOrderId IN: workOrders];
		Map<Id,List<WorkOrderLineItem>> workOrderLineItemsMaps = new Map<Id, List<WorkOrderLineItem>>();
		
		for(WorkOrderLineItem workOrderLineItem : workOrderLineItems) {
			if(workOrderLineItemsMaps.containsKey(workOrderLineItem.WorkOrderId)) {
				workOrderLineItemsMaps.get(workOrderLineItem.WorkOrderId).add(workOrderLineItem);
			} else {
				List<WorkOrderLineItem> workOrderLineItemList = new List<WorkOrderLineItem>();
				workOrderLineItemList.add(workOrderLineItem);
				workOrderLineItemsMaps.put(workOrderLineItem.WorkOrderId, workOrderLineItemList);
			}
		}

		for(WorkOrder workOrder : workOrders) {
			Integer numberOfWorkOrderLineItem = workOrderLineItemsMaps.get(workOrder.Id).size();
			Integer numberOfScheduled = 0;
			Integer numberOfDispatched = 0;
			Integer numberOfInProgress = 0;
			Integer numberOfCompleted = 0;
			Integer numberOfPartiallyComplete = 0;
			Integer numberOfCannotComplete = 0;
			Integer numberOfCanceled = 0;
			Integer numberOfAnnul = 0;
			
			for(WorkOrderLineItem workOrderLineItem : workOrderLineItemsMaps.get(workOrder.Id)) {
				if(workOrderLineItem.Status == 'Scheduled') {
					numberOfScheduled++;
				}
				if(workOrderLineItem.Status == 'Dispatched') {
					numberOfDispatched++;
				}
				if(workOrderLineItem.Status == 'In Progress') {
					numberOfInProgress++;
				}
				if(workOrderLineItem.Status == 'Completed') {
					numberOfCompleted++;
				}
				if(workOrderLineItem.Status == 'Partially Complete') {
					numberOfPartiallyComplete++;
				}
				if(workOrderLineItem.Status == 'Cannot Complete') {
					numberOfCannotComplete++;
				}
				if(workOrderLineItem.Status == 'Canceled') {
					numberOfCanceled++;
				}
				if(workOrderLineItem.Status == 'Annul') {
					numberOfAnnul++;
				}
			}

			System.debug('numberOfWorkOrderLineItem: ' + numberOfWorkOrderLineItem);
			System.debug('numberOfScheduled: ' + numberOfScheduled);
			System.debug('numberOfDispatched: ' + numberOfDispatched);
			System.debug('numberOfInProgress: ' + numberOfInProgress);
			System.debug('numberOfCompleted: ' + numberOfCompleted);
			System.debug('numberOfPartiallyComplete: ' + numberOfPartiallyComplete);
			System.debug('numberOfCannotComplete: ' + numberOfCannotComplete);
			System.debug('numberOfCanceled: ' + numberOfCanceled);
			System.debug('numberOfAnnul: ' + numberOfAnnul);
			
			if(numberOfScheduled > 0) {
				workOrder.Status = 'Scheduled';
			}
			if(numberOfPartiallyComplete > 0) {
				workOrder.Status = 'Partially Complete';
			}
			if(numberOfCannotComplete > 0) {
				workOrder.Status = 'Partially Complete';
			}
			if(numberOfDispatched == numberOfWorkOrderLineItem) {
				workOrder.Status = 'Dispatched';
			}
			if(numberOfInProgress == numberOfWorkOrderLineItem) {
				workOrder.Status = 'In Progress';
			}
			if(numberOfCompleted == numberOfWorkOrderLineItem) {
				workOrder.Status = 'Completed';
			}
			if(numberOfCannotComplete == numberOfWorkOrderLineItem) {
				workOrder.Status = 'Cannot Complete';
			}
			if(numberOfCanceled == numberOfWorkOrderLineItem) {
				workOrder.Status = 'Canceled';
			}
			if(numberOfAnnul == numberOfWorkOrderLineItem) {
				workOrder.Status = 'Annul';
			}
			workOrder.HOT_IsUpdateStatus__c = false;
		}
	}
}
