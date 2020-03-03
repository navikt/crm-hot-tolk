@istest
public class HOT_TestDataFactory {
	
	public static HOT_Request__c createRequest(String subject, WorkType workType) {
		HOT_Request__c request = new HOT_Request__c();
		request.Subject__c = subject;
		request.Status__c = 'Open';
		request.NumberOfInterpreters__c = 1;
		request.InterpretationMethod__c = workType.Id;
		request.StartTime__c = Datetime.now();
		request.EndTime__c = request.StartTime__c.addHours(1);
		return request;
	}
	
	public static WorkOrder createWorkOrder(HOT_Request__c request, WorkType workType) {
		WorkOrder workOrder = new WorkOrder();
		workOrder.HOT_Request__c = request.Id;
		workOrder.HOT_NumberOfInterpreters__c = 1;
		workOrder.WorkTypeId = workType.Id;
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

	public static WorkType createWorkType() {
		WorkType workType = new WorkType();
		workType.Name = 'workTypeName';
		workType.EstimatedDuration = 1;
		return workType;
	}
}
