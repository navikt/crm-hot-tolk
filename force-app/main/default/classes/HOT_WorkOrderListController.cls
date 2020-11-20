public without sharing class HOT_WorkOrderListController {
	
	
	@AuraEnabled(cacheable = true)
	public static List<WorkOrder> getWorkOrders(String requestNumber){
		List<WorkOrder> workOrders = new List<WorkOrder>();
		if(requestNumber == null){
			workOrders = [SELECT Id, StartDate, EndDate, Subject, Address, Street, City, PostalCode FROM WorkOrder];
		}
		else{
			workOrders = [SELECT Id, StartDate, EndDate, Subject, Address, Street, City, PostalCode FROM WorkOrder WHERE HOT_Request__r.Name = :requestNumber];
		}
		return workOrders;
	}
}
