public with sharing class HOT_WorkOrderLineItemStatusHandler extends MyTriggers {
	
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
			Integer numberOfPlanlagt = 0;
			Integer numberOfSendt = 0;
			Integer numberOfPagar = 0;
			Integer numberOfFullfort = 0;
			Integer numberOfDelvisFullfort = 0;
			Integer numberOfKanIkkeFullfore = 0;
			Integer numberOfAvbrutt = 0;
			
			for(ServiceAppointment serviceAppointment : serviceAppointmentMaps.get(workOrderLineItem.Id)) {
				if(serviceAppointment.Status == 'Planlagt') {
					numberOfPlanlagt++;
				}
				if(serviceAppointment.Status == 'Sendt') {
					numberOfSendt++;
				}
				if(serviceAppointment.Status == 'Pågår') {
					numberOfPagar++;
				}
				if(serviceAppointment.Status == 'Fullført') {
					numberOfFullfort++;
				}
				if(serviceAppointment.Status == 'Delvis fullført') {
					numberOfDelvisFullfort++;
				}
				if(serviceAppointment.Status == 'Kan ikke fullføre') {
					numberOfKanIkkeFullfore++;
				}
				if(serviceAppointment.Status == 'Avbrutt') {
					numberOfAvbrutt++;
				}
			}

			System.debug('numberOfServiceAppointments: ' + numberOfServiceAppointments);
			System.debug('numberOfPlanlagt: ' + numberOfPlanlagt);
			System.debug('numberOfSendt: ' + numberOfSendt);
			System.debug('numberOfPagar: ' + numberOfPagar);
			System.debug('numberOfFullfort: ' + numberOfFullfort);
			System.debug('numberOfDelvisFullfort: ' + numberOfDelvisFullfort);
			System.debug('numberOfKanIkkeFullfore: ' + numberOfKanIkkeFullfore);
			System.debug('numberOfAvbrutt: ' + numberOfAvbrutt);
			
			if(numberOfPlanlagt > 0) {
				workOrderLineItem.Status = 'Planlagt';
			}
			if(numberOfDelvisFullfort > 0) {
				workOrderLineItem.Status = 'Delvis fullført';
			}
			if(numberOfKanIkkeFullfore > 0) {
				workOrderLineItem.Status = 'Delvis fullført';
			}
			if(numberOfSendt == numberOfServiceAppointments) {
				workOrderLineItem.Status = 'Sendt';
			}
			if(numberOfPagar == numberOfServiceAppointments) {
				workOrderLineItem.Status = 'Pågår';
			}
			if(numberOfFullfort == numberOfServiceAppointments) {
				workOrderLineItem.Status = 'Fullført';
			}
			if(numberOfKanIkkeFullfore == numberOfServiceAppointments) {
				workOrderLineItem.Status = 'Kan ikke fullføre';
			}
			if(numberOfAvbrutt == numberOfServiceAppointments) {
				workOrderLineItem.Status = 'Avbrutt';
			}
			workOrderLineItem.HOT_IsUpdateStatus__c = false;
		}
	}
}
