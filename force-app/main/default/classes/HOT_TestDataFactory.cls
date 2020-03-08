@istest
public class HOT_TestDataFactory {
	
	public static HOT_Request__c createRequest(String subject, WorkType workType) {
		HOT_Request__c request = new HOT_Request__c();
		request.Subject__c = subject;
		request.Status__c = 'Åpen';
		request.NumberOfInterpreters__c = 1;
		request.InterpretationMethod__c = workType.Id;
		request.StartTime__c = Datetime.now();
		request.EndTime__c = request.StartTime__c.addHours(1);
		return request;
	}
	
	public static WorkOrder createWorkOrder(HOT_Request__c request, WorkType workType) {
		WorkOrder workOrder = new WorkOrder();
		workOrder.HOT_Request__c = request.Id;
		workOrder.Status = 'Ny';
		workOrder.HOT_NumberOfInterpreters__c = 1;
		workOrder.StartDate = Datetime.now();
		workOrder.EndDate = workOrder.StartDate.addHours(1);
		workOrder.WorkTypeId = workType.Id;
		return workOrder;
	}

	public static WorkOrderLineItem createWorkOrderLineItem(WorkOrder workOrder, WorkType workType) {
		WorkOrderLineItem workOrderLineItem = new WorkOrderLineItem();
		workOrderLineItem.WorkOrderId = workOrder.Id;
		workOrderLineItem.Status = 'Ny';
		workOrderLineItem.HOT_NumberOfInterpreters__c = 1;
		workOrderLineItem.StartDate = Datetime.now();
		workOrderLineItem.EndDate = workOrderLineItem.StartDate.addHours(1);
		workOrderLineItem.WorkTypeId = workType.Id;
		return workOrderLineItem;
	}

	public static ServiceAppointment createServiceAppointment(WorkOrderLineItem workOrderLineItem) {
		ServiceAppointment serviceAppointment = new ServiceAppointment();
		serviceAppointment.ParentRecordId = workOrderLineItem.Id;
		serviceAppointment.Status = 'Ingen';
		serviceAppointment.EarliestStartTime = Datetime.now();
		serviceAppointment.DueDate = serviceAppointment.EarliestStartTime.addHours(1);
		return serviceAppointment;
	}

	public static WorkType createWorkType() {
		WorkType workType = new WorkType();
		workType.Name = 'workTypeName';
		workType.EstimatedDuration = 1;
		return workType;
	}
}
