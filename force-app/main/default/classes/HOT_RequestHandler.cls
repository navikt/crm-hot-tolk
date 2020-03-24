public with sharing class HOT_RequestHandler extends MyTriggers {
	
	public override void onAfterUpdate(Map<Id,sObject> triggerOldMap) {
		List<HOT_Request__c> changedStatusRequests = new List<HOT_Request__c>();
		
		for(SObject record : records) {
			HOT_Request__c request = (HOT_Request__c)record;
			if(request.Status__c != triggerOldMap.get(request.Id).get('Status__c') && request.Status__c == 'Avlyst') {
				changedStatusRequests.add(request);
			}
		}
		if(changedStatusRequests.size() > 0) {
			updateChildRecords(changedStatusRequests);
		}
	}

	private static void updateChildRecords(List<HOT_Request__c> changedRequests) {
		List<WorkOrder> workOrders = [SELECT Status FROM WorkOrder WHERE HOT_Request__c IN :changedRequests];
		List<WorkOrderLineItem> workOrderLineItems = [SELECT Status FROM WorkOrderLineItem WHERE WorkOrderId IN :workOrders];
		List<ServiceAppointment> serviceAppointments = [SELECT Status FROM ServiceAppointment WHERE ParentRecordId IN :workOrderLineItems];

		// We only need to update Service Appointment, since the status is updated from SA -> WOLI -> WO in other tigger logic
		for(ServiceAppointment serviceAppointment : serviceAppointments) {
			serviceAppointment.Status = 'Avbrutt';
		}
		if(serviceAppointments.size() > 0) {
			update serviceAppointments;
		}
	}
}