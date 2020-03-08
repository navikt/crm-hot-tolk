public with sharing class HOT_FieldServiceStatusHandler extends MyTriggers {

	public override void onAfterUpdate(Map<Id,sObject> triggerOldMap) {
		List<WorkOrder> changedStatusWorkOrders = new List<WorkOrder>();
		List<WorkOrderLineItem> changedStatusWorkOrderLineItems = new List<WorkOrderLineItem>();
		List<ServiceAppointment> changedStatusServiceAppointments = new List<ServiceAppointment>();
		
		for(SObject record : records) {
			if(record.getSObjectType() == Schema.WorkOrder.getSObjectType()
				&& record.get('HOT_Request__c') != null
				&& record.get('Status') != triggerOldMap.get(record.Id).get('Status')) {
					changedStatusWorkOrders.add((WorkOrder)record);
			}
			if(record.getSObjectType() == Schema.WorkOrderLineItem.getSObjectType()
				&& record.get('WorkOrderId') != null
				&& record.get('Status') != triggerOldMap.get(record.Id).get('Status')) {
					changedStatusWorkOrderLineItems.add((WorkOrderLineItem)record);
			}
			if(record.getSObjectType() == Schema.ServiceAppointment.getSObjectType()
				&& record.get('ParentRecordId') != null
				&& record.get('Status') != triggerOldMap.get(record.Id).get('Status')) {
					changedStatusServiceAppointments.add((ServiceAppointment)record);
			}
		}

		if(changedStatusWorkOrders.size() > 0) {
			updateRequestStatus(changedStatusWorkOrders);
		}
		if(changedStatusWorkOrderLineItems.size() > 0) {
			updateWorkOrderStatus(changedStatusWorkOrderLineItems);
		}
		if(changedStatusServiceAppointments.size() > 0) {
			updateWorkOrderLineItemStatus(changedStatusServiceAppointments);
		}
	}

	public override void onBeforeUpdate(Map<Id,sObject> triggerOldMap) {
		List<WorkOrder> updateStatusWorkOrders = new List<WorkOrder>();
		List<WorkOrderLineItem> updateStatusWorkOrderLineItems = new List<WorkOrderLineItem>();

		for(SObject record : records) {
			if(record.getSObjectType() == Schema.WorkOrder.getSObjectType()
				&& record.get('HOT_IsUpdateStatus__c') == true) {
					updateStatusWorkOrders.add((WorkOrder)record);
			}
			if(record.getSObjectType() == Schema.WorkOrderLineItem.getSObjectType()
				&& record.get('HOT_IsUpdateStatus__c') == true) {
					updateStatusWorkOrderLineItems.add((WorkOrderLineItem)record);
			}
		}

		if(updateStatusWorkOrders.size() > 0) {
			updateWorkOrderStatus(updateStatusWorkOrders);
		}
		if(updateStatusWorkOrderLineItems.size() > 0) {
			updateWorkOrderLineItemStatus(updateStatusWorkOrderLineItems);
		}
	}

	public static void updateRequestStatus(List<WorkOrder> changedWorkOrders) {
		Map<String, String> statusMap = new Map<String, String>(); // Map<Work Order Status, Request Status>
		statusMap.put('Ny', 'Godkjent');
		statusMap.put('Planlagt', 'Reservert');
		statusMap.put('Sendt', 'Tildelt');
		statusMap.put('Pågår', 'Pågår');
		statusMap.put('Fullført', 'Dekket');
		statusMap.put('Delvis fullført', '	Delvis dekket');
		statusMap.put('Kan ikke fullføre', 'Udekket');
		statusMap.put('Avbrutt', 'Avlyst');

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
			workOrdersToUpdate.add(new WorkOrder(Id = workOrderLineItem.WorkOrderId, HOT_IsUpdateStatus__c = true));
		}
		update workOrdersToUpdate;
	}

	private static void updateWorkOrderLineItemStatus(List<ServiceAppointment> changedServiceAppointments) {
		List<WorkOrderLineItem> workOrderLineItemsToUpdate = new List<WorkOrderLineItem>();
		for(ServiceAppointment serviceAppointment : changedServiceAppointments) {
			if(serviceAppointment.ParentRecordId.getSobjectType() == Schema.WorkOrderLineItem.getSObjectType()) {
				workOrderLineItemsToUpdate.add(new WorkOrderLineItem(Id = serviceAppointment.ParentRecordId, HOT_IsUpdateStatus__c = true));
			}
		}
		update workOrderLineItemsToUpdate;
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
			Integer numberOfPlanlagt = 0;
			Integer numberOfSendt = 0;
			Integer numberOfPagar = 0;
			Integer numberOfFullfort = 0;
			Integer numberOfDelvisFullfort = 0;
			Integer numberOfKanIkkeFullfore = 0;
			Integer numberOfAvbrutt = 0;
			
			for(WorkOrderLineItem workOrderLineItem : workOrderLineItemsMaps.get(workOrder.Id)) {
				if(workOrderLineItem.Status == 'Planlagt') {
					numberOfPlanlagt++;
				}
				if(workOrderLineItem.Status == 'Sendt') {
					numberOfSendt++;
				}
				if(workOrderLineItem.Status == 'Pågår') {
					numberOfPagar++;
				}
				if(workOrderLineItem.Status == 'Fullført') {
					numberOfFullfort++;
				}
				if(workOrderLineItem.Status == 'Delvis fullført') {
					numberOfDelvisFullfort++;
				}
				if(workOrderLineItem.Status == 'Kan ikke fullføre') {
					numberOfKanIkkeFullfore++;
				}
				if(workOrderLineItem.Status == 'Avbrutt') {
					numberOfAvbrutt++;
				}
			}

			System.debug('numberOfWorkOrderLineItem: ' + numberOfWorkOrderLineItem);
			System.debug('numberOfPlanlagt: ' + numberOfPlanlagt);
			System.debug('numberOfSendt: ' + numberOfSendt);
			System.debug('numberOfPagar: ' + numberOfPagar);
			System.debug('numberOfFullfort: ' + numberOfFullfort);
			System.debug('numberOfDelvisFullfort: ' + numberOfDelvisFullfort);
			System.debug('numberOfKanIkkeFullfore: ' + numberOfKanIkkeFullfore);
			System.debug('numberOfAvbrutt: ' + numberOfAvbrutt);
			
			if(numberOfPlanlagt > 0) {
				workOrder.Status = 'Planlagt';
			}
			if(numberOfDelvisFullfort > 0) {
				workOrder.Status = 'Delvis fullført';
			}
			if(numberOfKanIkkeFullfore > 0) {
				workOrder.Status = 'Delvis fullført';
			}
			if(numberOfSendt == numberOfWorkOrderLineItem) {
				workOrder.Status = 'Sendt';
			}
			if(numberOfPagar == numberOfWorkOrderLineItem) {
				workOrder.Status = 'Pågår';
			}
			if(numberOfFullfort == numberOfWorkOrderLineItem) {
				workOrder.Status = 'Fullført';
			}
			if(numberOfKanIkkeFullfore == numberOfWorkOrderLineItem) {
				workOrder.Status = 'Kan ikke fullføre';
			}
			if(numberOfAvbrutt == numberOfWorkOrderLineItem) {
				workOrder.Status = 'Avbrutt';
			}
			workOrder.HOT_IsUpdateStatus__c = false;
		}
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