public without sharing class HOT_WorkOrderLineItemStatusHandler extends MyTriggers {
	
	public override void onAfterUpdate(Map<Id,sObject> triggerOldMap) {
		List<WorkOrderLineItem> changedStatusWorkOrderLineItems = new List<WorkOrderLineItem>();
		
		for(SObject record : records) {
			if(record.getSObjectType() == Schema.WorkOrderLineItem.getSObjectType()
				&& record.get('WorkOrderId') != null
				&& record.get('Status') != triggerOldMap.get(record.Id).get('Status')) {
					changedStatusWorkOrderLineItems.add((WorkOrderLineItem)record);
			}
		}
		if(changedStatusWorkOrderLineItems.size() > 0) {
			updateWorkOrderStatus(changedStatusWorkOrderLineItems);
		}
	}

	public override void onBeforeUpdate(Map<Id,sObject> triggerOldMap) {
		List<WorkOrderLineItem> updateStatusWorkOrderLineItems = new List<WorkOrderLineItem>();

		for(SObject record : records) {
			if(record.getSObjectType() == Schema.WorkOrderLineItem.getSObjectType()
				&& record.get('HOT_IsUpdateStatus__c') == true) {
					updateStatusWorkOrderLineItems.add((WorkOrderLineItem)record);
			}
		}
		if(updateStatusWorkOrderLineItems.size() > 0) {
			updateWorkOrderLineItemStatus(updateStatusWorkOrderLineItems);
		}
	}

	private static void updateWorkOrderStatus(List<WorkOrderLineItem> changedWorkOrderLineItems) {
		List<WorkOrder> workOrdersToUpdate = new List<WorkOrder>();
		for(WorkOrderLineItem workOrderLineItem : changedWorkOrderLineItems) {
			WorkOrder workOrderToAdd = new WorkOrder(Id = workOrderLineItem.WorkOrderId, HOT_IsUpdateStatus__c = true);
			if(!workOrdersToUpdate.contains(workOrderToAdd)) {
				workOrdersToUpdate.add(workOrderToAdd);
			}
		}
		update workOrdersToUpdate;
	}

	private static void updateWorkOrderLineItemStatus(List<WorkOrderLineItem> workOrderLineItems) {
		List<ServiceAppointment> serviceAppointments = [SELECT ParentRecordId, Status FROM ServiceAppointment WHERE ParentRecordId IN: workOrderLineItems];
		Map<Id,List<ServiceAppointment>> serviceAppointmentMaps = new Map<Id, List<ServiceAppointment>>();
		
		for(ServiceAppointment serviceAppointment : serviceAppointments) {
			if(serviceAppointmentMaps.containsKey(serviceAppointment.ParentRecordId)) {
				serviceAppointmentMaps.get(serviceAppointment.ParentRecordId).add(serviceAppointment);
			} else {
				List<ServiceAppointment> serviceAppointmentList = new List<ServiceAppointment>();
				serviceAppointmentList.add(serviceAppointment);
				serviceAppointmentMaps.put(serviceAppointment.ParentRecordId, serviceAppointmentList);
			}
		}

		for(WorkOrderLineItem workOrderLineItem : workOrderLineItems) {
			Integer numberOfServiceAppointments = serviceAppointmentMaps.get(workOrderLineItem.Id).size();
			Integer numberOfScheduled = 0;
			Integer numberOfDispatched = 0;
			Integer numberOfInProgress = 0;
			Integer numberOfCompleted = 0;
			Integer numberOfPartiallyComplete = 0;
			Integer numberOfCannotComplete = 0;
			Integer numberOfCanceled = 0;
			
			for(ServiceAppointment serviceAppointment : serviceAppointmentMaps.get(workOrderLineItem.Id)) {
				if(serviceAppointment.Status == 'Scheduled') {
					numberOfScheduled++;
				}
				if(serviceAppointment.Status == 'Dispatched') {
					numberOfDispatched++;
				}
				if(serviceAppointment.Status == 'In Progress') {
					numberOfInProgress++;
				}
				if(serviceAppointment.Status == 'Completed') {
					numberOfCompleted++;
				}
				if(serviceAppointment.Status == 'Partially Complete') {
					numberOfPartiallyComplete++;
				}
				if(serviceAppointment.Status == 'Cannot Complete') {
					numberOfCannotComplete++;
				}
				if(serviceAppointment.Status == 'Canceled') {
					numberOfCanceled++;
				}
			}

			System.debug('numberOfServiceAppointments: ' + numberOfServiceAppointments);
			System.debug('numberOfScheduled: ' + numberOfScheduled);
			System.debug('numberOfDispatched: ' + numberOfDispatched);
			System.debug('numberOfInProgress: ' + numberOfInProgress);
			System.debug('numberOfCompleted: ' + numberOfCompleted);
			System.debug('numberOfPartiallyComplete: ' + numberOfPartiallyComplete);
			System.debug('numberOfCannotComplete: ' + numberOfCannotComplete);
			System.debug('numberOfCanceled: ' + numberOfCanceled);
			
			if(numberOfScheduled > 0) {
				workOrderLineItem.Status = 'Scheduled';
			}
			if(numberOfPartiallyComplete > 0) {
				workOrderLineItem.Status = 'Partially Complete';
			}
			if(numberOfCannotComplete > 0) {
				workOrderLineItem.Status = 'Partially Complete';
			}
			if(numberOfDispatched == numberOfServiceAppointments) {
				workOrderLineItem.Status = 'Dispatched';
			}
			if(numberOfInProgress == numberOfServiceAppointments) {
				workOrderLineItem.Status = 'In Progress';
			}
			if(numberOfCompleted == numberOfServiceAppointments) {
				workOrderLineItem.Status = 'Completed';
			}
			if(numberOfCannotComplete == numberOfServiceAppointments) {
				workOrderLineItem.Status = 'Cannot Complete';
			}
			if(numberOfCanceled == numberOfServiceAppointments) {
				workOrderLineItem.Status = 'Canceled';
			}
			workOrderLineItem.HOT_IsUpdateStatus__c = false;
		}
	}
}
