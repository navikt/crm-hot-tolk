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

	public override void onAfterUpdate(Map<Id, sObject> triggerOldMap) {
		List<HOT_Request__c> avlystRequests = new List<HOT_Request__c>();
		List<HOT_Request__c> annullertRequests = new List<HOT_Request__c>();

        for (HOT_Request__c request : (List<HOT_Request__c>) records) {
			// Filter for Avlyst requests
            if (request.Status__c != triggerOldMap.get(request.Id).get('Status__c') && request.Status__c == 'Avlyst') {
                avlystRequests.add(request);
			}
			// Filter for Annullert requests
            if (request.Status__c != triggerOldMap.get(request.Id).get('Status__c') && request.Status__c == 'Annullert') {
                annullertRequests.add(request);
			}
        }
        if (avlystRequests.size() > 0) {
            updateChildRecords(avlystRequests, 'Canceled');
		}
		if (annullertRequests.size() > 0) {
            updateChildRecords(annullertRequests, 'Annul');
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
			if(workOrdersMaps.get(request.Id) != null) {
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
				if(numberOfDispatched > 0) {
					request.Status__c = statusMap.get('Dispatched');
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

	private static void updateChildRecords(List<HOT_Request__c> changedRequests, String newStatus) {
		
		List<WorkOrder> workOrders = [SELECT Status FROM WorkOrder WHERE HOT_Request__c IN :changedRequests AND Status != :newStatus AND Status != 'Annul' AND Status != 'Completed' AND Status != 'Partially Complete'];

		for (WorkOrder workOrder : workOrders) {
            workOrder.Status = newStatus;
        }
        if (workOrders.size() > 0) {
            update workOrders;
        }
	}
}
