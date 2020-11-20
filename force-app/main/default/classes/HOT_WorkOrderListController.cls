public with sharing class HOT_WorkOrderListController {
	
	
	@AuraEnabled(cacheable = true)
	public static List<WorkOrder> getWorkOrders(){
		return [SELECT Id, StartDate, EndDate, Subject, Address, Street, City, PostalCode FROM WorkOrder];
	}
}
