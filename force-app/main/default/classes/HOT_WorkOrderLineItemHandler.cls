public with sharing class HOT_WorkOrderLineItemHandler extends MyTriggers {
	
	public override void onBeforeInsert(){
		setStatusDefault((List<WorkOrderLineItem>) records);
	}

	public override void onAfterInsert() {
		createChildRecords((List<WorkOrderLineItem>) records);
	}

	public static void createChildRecords(List<WorkOrderLineItem> workOrderLineItems){
		List<Id> workOrderIds = new List<Id>();
		for(WorkOrderLineItem workOrderLineItem:workOrderLineItems){
			workOrderIds.add(workOrderLineItem.WorkOrderId);
		}
		Map<Id, WorkOrder> workOrders = new Map<Id, WorkOrder>([SELECT Id, OwnerId, HOT_Request__c, HOT_Request__r.PreferredInterpreter1__c, HOT_Request__r.PreferredInterpreter2__c FROM WorkOrder WHERE Id IN :workOrderIds]);

		List<ServiceAppointment> serviceAppointments = new List<ServiceAppointment>();
		for(WorkOrderLineItem workOrderLineItem:workOrderLineItems){
			for(Integer numberOfInterpreters=0; numberOfInterpreters < workOrderLineItem.HOT_NumberOfInterpreters__c; numberOfInterpreters++){
				ServiceAppointment serviceAppointment = new ServiceAppointment();

				serviceAppointment.ParentRecordId = workOrderLineItem.Id;
				serviceAppointment.City = workOrderLineItem.City;
				serviceAppointment.Description = workOrderLineItem.Description;
				serviceAppointment.DueDate = workOrderLineItem.EndDate;
				serviceAppointment.HOT_InterpretationPostalCity__c = workOrderLineItem.HOT_InterpretationPostalCity__c;
				serviceAppointment.HOT_InterpretationPostalCode__c = workOrderLineItem.HOT_InterpretationPostalCode__c;
				serviceAppointment.HOT_InterpretationStreet__c = workOrderLineItem.HOT_InterpretationPostalStreet__c;
				serviceAppointment.OwnerId = workOrders.get(workOrderLineItem.WorkOrderId).OwnerId;
				serviceAppointment.PostalCode = workOrderLineItem.PostalCode;
				serviceAppointment.EarliestStartTime = workOrderLineItem.StartDate;
				serviceAppointment.Street = workOrderLineItem.Street;
				serviceAppointment.Subject = workOrderLineItem.Subject;
				serviceAppointment.SchedStartTime = workOrderLineItem.StartDate;
				serviceAppointment.SchedEndTime = workOrderLineItem.EndDate;
				serviceAppointment.HOT_Request__c = workOrders.get(workOrderLineItem.WorkOrderId).HOT_Request__c;
				if(Math.mod(numberOfInterpreters, 2) == 1 && workOrders.get(workOrderLineItem.WorkOrderId).HOT_Request__r.PreferredInterpreter2__c != null){
					serviceAppointment.HOT_PreferredInterpreter__c = workOrders.get(workOrderLineItem.WorkOrderId).HOT_Request__r.PreferredInterpreter2__c;
				}
				else{
					serviceAppointment.HOT_PreferredInterpreter__c = workOrders.get(workOrderLineItem.WorkOrderId).HOT_Request__r.PreferredInterpreter1__c;
				}

				serviceAppointments.add(serviceAppointment);
			}
			
		}
		insert serviceAppointments;
	}

	public static void setStatusDefault(List<WorkOrderLineItem> workOrderLines){
		for(WorkOrderLineItem workOrderLine : workOrderLines){
			workOrderLine.Status = 'New';
		}
	}
}
