public without sharing class HOT_RequestStatusHandler extends MyTriggers {
	
	public override void onBeforeUpdate(Map<Id,sObject> triggerOldMap) {
		List<HOT_Request__c> updateStatusRequests = new List<HOT_Request__c>();

		for(SObject record : records) {
			System.debug('record: ' + record);
			if(record.getSObjectType() == Schema.HOT_Request__c.getSObjectType()
				&& record.get('IsUpdateStatus__c') == true) {
					updateStatusRequests.add((HOT_Request__c)record);
			}
		}

		if(updateStatusRequests.size() > 0) {
			updateRequestStatus(updateStatusRequests);
		}
	}

	private static void updateRequestStatus(List<HOT_Request__c> requests) {

		Map<String, String> statusMap = new Map<String, String>(); // Map<Work Order Status, Request Status>
		statusMap.put('New', 'Godkjent');
		statusMap.put('Scheduled', 'Reservert');
		statusMap.put('Dispatched', 'Tildelt');
		statusMap.put('In Progress', 'Pågår');
		statusMap.put('Completed', 'Dekket');
		statusMap.put('Partially Complete', 'Delvis dekket');
		statusMap.put('Cannot Complete', 'Udekket');
		statusMap.put('Canceled', 'Avlyst');

		List<WorkOrder> workOrders = [SELECT HOT_Request__c, Status FROM WorkOrder WHERE HOT_Request__c IN: requests AND Status != 'Annul'];
		Map<Id,List<WorkOrder>> workOrdersMaps = new Map<Id, List<WorkOrder>>();
		
		for(WorkOrder workOrder : workOrders) {
			if(workOrdersMaps.containsKey(workOrder.HOT_Request__c)) {
				workOrdersMaps.get(workOrder.HOT_Request__c).add(workOrder);
			} else {
				List<WorkOrder> workOrderList = new List<WorkOrder>();
				workOrderList.add(workOrder);
				workOrdersMaps.put(workOrder.HOT_Request__c, workOrderList);
			}
		}

		for(HOT_Request__c request : requests) {
			Integer numberOfWorkOrder = workOrdersMaps.get(request.Id).size();
			Integer numberOfNew = 0;
			Integer numberOfScheduled = 0;
			Integer numberOfDispatched = 0;
			Integer numberOfInProgress = 0;
			Integer numberOfCompleted = 0;
			Integer numberOfPartiallyComplete = 0;
			Integer numberOfCannotComplete = 0;
			Integer numberOfCanceled = 0;
			
			for(WorkOrder workOrder : workOrdersMaps.get(request.Id)) {
				if(workOrder.Status == 'New') {
					numberOfNew++;
				}
				if(workOrder.Status == 'Scheduled') {
					numberOfScheduled++;
				}
				if(workOrder.Status == 'Dispatched') {
					numberOfDispatched++;
				}
				if(workOrder.Status == 'In Progress') {
					numberOfInProgress++;
				}
				if(workOrder.Status == 'Completed') {
					numberOfCompleted++;
				}
				if(workOrder.Status == 'Partially Complete') {
					numberOfPartiallyComplete++;
				}
				if(workOrder.Status == 'Cannot Complete') {
					numberOfCannotComplete++;
				}
				if(workOrder.Status == 'Canceled') {
					numberOfCanceled++;
				}
			}

			System.debug('numberOfWorkOrder: ' + numberOfWorkOrder);
			System.debug('numberOfNew: ' + numberOfNew);
			System.debug('numberOfScheduled: ' + numberOfScheduled);
			System.debug('numberOfDispatched: ' + numberOfDispatched);
			System.debug('numberOfInProgress: ' + numberOfInProgress);
			System.debug('numberOfCompleted: ' + numberOfCompleted);
			System.debug('numberOfPartiallyComplete: ' + numberOfPartiallyComplete);
			System.debug('numberOfCannotComplete: ' + numberOfCannotComplete);
			System.debug('numberOfCanceled: ' + numberOfCanceled);
			
			if(numberOfScheduled > 0) {
				request.Status__c = statusMap.get('Scheduled');
			}
			if(numberOfPartiallyComplete > 0) {
				request.Status__c = statusMap.get('Partially Complete');
			}
			if(numberOfCannotComplete > 0) {
				request.Status__c = statusMap.get('Partially Complete');
			}
			if(numberOfCompleted > 0) {
				request.Status__c = statusMap.get('Partially Complete');
			}
			if(numberOfDispatched == numberOfWorkOrder) {
				request.Status__c = statusMap.get('Dispatched');
				continue;
			}
			if(numberOfInProgress == numberOfWorkOrder) {
				request.Status__c = statusMap.get('In Progress');
				continue;
			}
			if(numberOfCompleted == numberOfWorkOrder) {
				request.Status__c = statusMap.get('Completed');
				continue;
			}
			if(numberOfCannotComplete == numberOfWorkOrder) {
				request.Status__c = statusMap.get('Cannot Complete');
				continue;
			}
			if(numberOfCanceled == numberOfWorkOrder) {
				request.Status__c = statusMap.get('Canceled');
				continue;
			}
			if(numberOfNew == numberOfWorkOrder) {
				request.Status__c = statusMap.get('New');
				continue;
			}
			request.IsUpdateStatus__c = false;
		}
	}
}
