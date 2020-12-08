public without sharing class HOT_WorkOrderListController {
	
	@AuraEnabled(cacheable = true)
	public static List<WorkOrder> getMyWorkOrders(){
		Map<Id, WorkOrder> workOrders = new Map<Id, WorkOrder>();
		Id userId = UserInfo.getUserId();
		User user = [SELECT Id, AccountId, Name FROM User WHERE Id = : userId];
		if(user.AccountId != null){
			workOrders = new Map<Id, WorkOrder>([SELECT Id, StartDate, EndDate, Subject, Address, Street, City, PostalCode, Status, HOT_ExternalWorkOrderStatus__c, HOT_RequestName__c, HOT_Interpreters__c, HOT_Request__r.Orderer__c, HOT_IsCancelable__c FROM WorkOrder WHERE HOT_Request__r.Account__c = :user.AccountId AND StartDate >= :DateTime.NOW() ORDER BY StartDate]);
		}
		workOrders = getAndSetInterpreters(workOrders);
		workOrders = getRowActions(workOrders);
		return workOrders.values();
	}

	@AuraEnabled(cacheable = true) 
	public static List<WorkOrder> getWorkOrdersFromRequest(String requestNumber){
		Map<Id, WorkOrder> workOrders = new Map<Id, WorkOrder>();
		Id userId = UserInfo.getUserId();
		User user = [SELECT Id, AccountId, Name FROM User WHERE Id = : userId];
		if(user.AccountId != null && requestNumber != null){
			workOrders = new Map<Id, WorkOrder>([SELECT Id, StartDate, EndDate, Subject, Address, Street, City, PostalCode, Status, HOT_ExternalWorkOrderStatus__c, HOT_RequestName__c, HOT_Interpreters__c, HOT_Request__r.Orderer__c, HOT_IsCancelable__c FROM WorkOrder WHERE HOT_Request__r.Name = :requestNumber AND (HOT_Request__r.Account__c = :user.AccountId OR HOT_Request__r.Orderer__c = :user.AccountId) AND StartDate >= :DateTime.NOW() ORDER BY StartDate]);
		}
		workOrders = getAndSetInterpreters(workOrders);
		workOrders = getRowActions(workOrders);
		return workOrders.values();
	}

	public static Map<Id, WorkOrder> getAndSetInterpreters(Map<Id, WorkOrder> workOrders){
		Map<Id, WorkOrderLineItem> workOrderLineItems = new Map<Id, WorkOrderLineItem>([SELECT Id, WorkOrderId FROM WorkOrderLineItem WHERE WorkOrderId IN :workOrders.keySet()]);
		List<ServiceAppointment> serviceAppointments = [SELECT Id, ParentRecordId, HOT_ServiceResource__r.Name FROM ServiceAppointment WHERE ParentRecordId IN :workOrderLineItems.keySet()];
		for(ServiceAppointment serviceAppointment:serviceAppointments){
			if(serviceAppointment.HOT_ServiceResource__r.Name != null){
				if(workOrders.get(workOrderLineItems.get(serviceAppointment.ParentRecordId).WorkOrderId).HOT_Interpreters__c == null){
					workOrders.get(workOrderLineItems.get(serviceAppointment.ParentRecordId).WorkOrderId).HOT_Interpreters__c = serviceAppointment.HOT_ServiceResource__r.Name + ', ';
				}
				else{
					workOrders.get(workOrderLineItems.get(serviceAppointment.ParentRecordId).WorkOrderId).HOT_Interpreters__c += serviceAppointment.HOT_ServiceResource__r.Name + ', ';
				}
			}
		}
		for(Id id : workOrders.keySet()){
			if(workOrders.get(id).HOT_Interpreters__c != null){
				if(workOrders.get(id).HOT_Interpreters__c.right(2) == ', '){
					workOrders.get(id).HOT_Interpreters__c = workOrders.get(id).HOT_Interpreters__c.removeEnd(', ');
			}
			}
		}
		return workOrders;
	}
	
	public static Map<Id, WorkOrder> getRowActions(Map<Id, WorkOrder> workOrders){
		User user = [SELECT AccountId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
		if(user.AccountId != null){
			Id accountId = user.AccountId;
			for(Id workOrderId:workOrders.keySet()){
				if(workOrders.get(workOrderId).Status != 'Canceled' && workOrders.get(workOrderId).HOT_Request__r.Orderer__c == AccountId){
					workOrders.get(workOrderId).HOT_IsCancelable__c = true;
				}
			}
		}
		return workOrders;
	}
}
