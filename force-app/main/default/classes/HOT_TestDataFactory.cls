@istest
public class HOT_TestDataFactory {
	
	public static HOT_Request__c createRequest() {
		HOT_Request__c request = new HOT_Request__c();
		request.Subject__c = 'TEST';
		request.Status__c = 'Open';
		return request;
	}
	
	public static WorkOrder createWorkOrder(HOT_Request__c request) {
		WorkOrder workOrder = new WorkOrder();
		workOrder.HOT_Request__c = request.Id;
		workOrder.Status = 'New';
		return workOrder;
	}

	public static WorkOrderLineItem createWorkOrderLineItem(WorkOrder workOrder) {
		WorkOrderLineItem workOrderLineItem = new WorkOrderLineItem();
		workOrderLineItem.WorkOrderId = workOrder.Id;
		workOrderLineItem.Status = 'New';
		return workOrderLineItem;
	}

	public static ServiceAppointment createServiceAppointment(WorkOrderLineItem workOrderLineItem) {
		ServiceAppointment serviceAppointment = new ServiceAppointment();
		serviceAppointment.ParentRecordId = workOrderLineItem.Id;
		serviceAppointment.Status = 'None';
		return serviceAppointment;
	}
}
