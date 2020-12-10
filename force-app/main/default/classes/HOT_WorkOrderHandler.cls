public without sharing class HOT_WorkOrderHandler extends MyTriggers {
	
	public override void onBeforeInsert(){
		setDefaultFields((List<WorkOrder>) records);
	}
	
	public override void onAfterInsert() {
		List<Id> requestIds = new List<Id>();
		for(WorkOrder workOrder:(List<WorkOrder>) records){
			requestIds.add(workOrder.HOT_Request__c);
		}
		List<WorkOrder> approvedWorkOrders = new List<WorkOrder>();
		Map<Id, HOT_Request__c> requests = new Map<Id, HOT_Request__c>([SELECT Id, Status__c FROM HOT_Request__c WHERE Id IN :requestIds]);
		for(WorkOrder workOrder:(List<WorkOrder>) records){
			if(requests.get(workOrder.HOT_Request__c).Status__c != 'Åpen' && requests.get(workOrder.HOT_Request__c).Status__c != 'Avlyst' && requests.get(workOrder.HOT_Request__c).Status__c != 'Annullert'){
				approvedWorkOrders.add(workOrder);
			}
		}
		if(approvedWorkOrders.size()>0){
			createChildRecords(approvedWorkOrders);
		}
		updateRequests((List<WorkOrder>) records);
	}
	public override void onAfterUpdate(Map<Id,sObject> triggerOldMap) {
		List<WorkOrder> updatedWorkOrders = new List<WorkOrder>();

		//Om status eller tidspunkt på WorkOrder er endret, kan det ha ført til at den førstkommende, ikke-avlyste WorkOrderen har endret seg
		for(WorkOrder record : (List<WorkOrder>) records) {
			System.debug('record: ' + record);
			if(record.Status != triggerOldMap.get(record.Id).get('Status')
				||
				record.StartDate != triggerOldMap.get(record.Id).get('StartDate')
				||
				record.EndDate != triggerOldMap.get(record.Id).get('EndDate')) {
					updatedWorkOrders.add(record);
			}
		}

		if(updatedWorkOrders.size() > 0) {
			updateRequests(updatedWorkOrders);
		}
	}
	public override void onAfterDelete() {
		updateRequests((List<WorkOrder>) records);
	}
	public override void onAfterUndelete() {
		updateRequests((List<WorkOrder>) records);
	}


	public static void createChildRecords(List<WorkOrder> workOrders){

		//Getting parent requests
		List<Id> requestIds = new List<Id>();
		for(WorkOrder workOrder : workOrders){
			requestIds.add(workOrder.HOT_Request__c);
		}
		Map<Id, HOT_Request__c> requests = new Map<Id, HOT_Request__c>([SELECT Id, InterpretationMethod__r.Id, InterpretationMethodSecondary__r.Id, NumberOfInterpreters__c, NumberOfInterpretersSecondary__c 
																		FROM HOT_Request__c WHERE Id IN :requestIds]);

		//Each workOrder should have 1 or more childs (workOrderLineItems)
		List<WorkOrderLineItem> workOrderLineItems = new List<WorkOrderLineItem>();
		for(WorkOrder workOrder:workOrders){
			
			//Check if status New

			//Fetching the workTypes from parent requests. If the request only has 1 workType, only one child workOrderLineItem should be created
			Map<Id, Decimal> workTypes = new Map<Id, Decimal>();
			workTypes.put(requests.get(workOrder.HOT_Request__c).InterpretationMethod__r.Id, requests.get(workOrder.HOT_Request__c).NumberOfInterpreters__c);
			if(requests.get(workOrder.HOT_Request__c).InterpretationMethodSecondary__c != null){
				workTypes.put(requests.get(workOrder.HOT_Request__c).InterpretationMethodSecondary__r.Id, requests.get(workOrder.HOT_Request__c).NumberOfInterpretersSecondary__c);
			}

			//If there are no child workOrderLineItems for this workOrder, they should be created 
			if(workOrder.LineItemCount == 0){
				for(Id workTypeId:workTypes.keySet()){
					WorkOrderLineItem workOrderLineItem = new WorkOrderLineItem();
					workOrderLineItem.WorkOrderId = workOrder.Id;
					workOrderLineItem.City = workOrder.City;
					workOrderLineItem.Description = workOrder.Description;
					workOrderLineItem.EndDate = workOrder.EndDate;
					workOrderLineItem.HOT_InterpretationPostalCity__c = workOrder.HOT_InterpretationPostalCity__c;
					workOrderLineItem.HOT_InterpretationPostalCode__c = workOrder.HOT_InterpretationPostalCode__c;
					workOrderLineItem.HOT_InterpretationPostalStreet__c = workOrder.HOT_InterpretationStreet__c;
					workOrderLineItem.PostalCode = workOrder.PostalCode;
					workOrderLineItem.StartDate = workOrder.StartDate;
					workOrderLineItem.Street = workOrder.Street;
					workOrderLineItem.Subject = workOrder.Subject;
					workOrderLineItem.WorkTypeId = workTypeId;
					workOrderLineItem.HOT_NumberOfInterpreters__c = workTypes.get(workTypeId);
		
					workOrderLineItems.add(workOrderLineItem);
				}
			}
		}
		insert workOrderLineItems;
	}

	public static void setDefaultFields(List<WorkOrder> workOrders){
		List<Id> requestIds = new List<Id>();
		List<Id> accountIds = new List<Id>();
		for(WorkOrder workOrder : workOrders){
			requestIds.add(workOrder.HOT_Request__c);
			accountIds.add(workOrder.AccountId);
		}
		Map<Id, Account> accounts = new Map<Id, Account>([SELECT Id, PersonContactId FROM Account WHERE Id IN :accountIds]);
		Map<Id, HOT_Request__c> requests = new Map<Id, HOT_Request__c>([SELECT Id, ServiceTerritory__c, Status__c, OwnerId, Subject__c, Description__c, Account__c, 
																		InterpretationStreet__c, InterpretationPostalCode__c, InterpretationPostalCity__c, MeetingStreet__c, MeetingPostalCity__c, MeetingPostalCode__c
																		FROM HOT_Request__c WHERE Id IN :requestIds]);
		for(WorkOrder workOrder : workOrders){
			//Setting default status for WorkOrder
			workOrder.Status = 'New';
			if(workOrder.HOT_Request__c != null) {
				//Setting owner of WorkOrder based on owner of Request
					workOrder.OwnerId = workOrder.HOT_RequestOwnerId__c;
					System.debug('workOrder.OwnerId: ' + workOrder.OwnerId);

				//Setting fields of WorkOrder based on Request, if the fields are not filled in, and the fields on Request have values.
				if(workOrder.ServiceTerritory == null && requests.get(workOrder.HOT_Request__c).ServiceTerritory__c != null){
					workOrder.ServiceTerritoryId = requests.get(workOrder.HOT_Request__c).ServiceTerritory__c;
				}
				if(workOrder.Subject == null && requests.get(workOrder.HOT_Request__c).Subject__c != null){
					workOrder.Subject = requests.get(workOrder.HOT_Request__c).Subject__c;
				}
				if(workOrder.Description == null && requests.get(workOrder.HOT_Request__c).Description__c != null){
					workOrder.Description = requests.get(workOrder.HOT_Request__c).Description__c;
				}
				if(workOrder.AccountId == null && requests.get(workOrder.HOT_Request__c).Account__c != null){
					workOrder.AccountId = requests.get(workOrder.HOT_Request__c).Account__c;
				}
				if(workOrder.ContactId == null && requests.get(workOrder.HOT_Request__c).Account__c != null && accounts.get(requests.get(workOrder.HOT_Request__c).Account__c).PersonContactId != null){
					workOrder.ContactId = accounts.get(requests.get(workOrder.HOT_Request__c).Account__c).PersonContactId;
				}
				if(workOrder.HOT_InterpretationStreet__c == null && requests.get(workOrder.HOT_Request__c).InterpretationStreet__c != null){
					workOrder.HOT_InterpretationStreet__c = requests.get(workOrder.HOT_Request__c).InterpretationStreet__c;
				}
				if(workOrder.HOT_InterpretationPostalCode__c == null && requests.get(workOrder.HOT_Request__c).InterpretationPostalCode__c != null){
					workOrder.HOT_InterpretationPostalCode__c = requests.get(workOrder.HOT_Request__c).InterpretationPostalCode__c;
				}
				if(workOrder.HOT_InterpretationPostalCity__c == null && requests.get(workOrder.HOT_Request__c).InterpretationPostalCity__c != null){
					workOrder.HOT_InterpretationPostalCity__c = requests.get(workOrder.HOT_Request__c).InterpretationPostalCity__c;
				}
				if(workOrder.Street == null && requests.get(workOrder.HOT_Request__c).MeetingStreet__c != null){
					workOrder.Street = requests.get(workOrder.HOT_Request__c).MeetingStreet__c;
				}
				if(workOrder.City == null && requests.get(workOrder.HOT_Request__c).MeetingPostalCity__c != null){
					workOrder.City = requests.get(workOrder.HOT_Request__c).MeetingPostalCity__c;
				}
				if(workOrder.PostalCode == null && requests.get(workOrder.HOT_Request__c).MeetingPostalCode__c != null){
					workOrder.PostalCode = requests.get(workOrder.HOT_Request__c).MeetingPostalCode__c;
				}
			}
		}
	}

	public static void updateRequests(List<WorkOrder> workOrders){
		List<Id> requestIds = new List<Id>();
		for(WorkOrder workOrder:workOrders){
			requestIds.add(workOrder.HOT_Request__c);
		}
		List<HOT_Request__c> requests = [SELECT Id, NumberOfWorkOrders__c, StartTime__c, EndTime__c, (SELECT Id, StartDate, EndDate FROM HOT_Request__c.Work_Orders__r WHERE Status NOT IN ('Annul', 'Canceled') ORDER BY StartDate) FROM HOT_Request__c WHERE Id IN :requestIds];
		for(HOT_Request__c request:requests){
			request.NumberOfWorkOrders__c = request.Work_Orders__r.size();
			if(request.Work_Orders__r.size()>0){
				request.StartTime__c = request.Work_Orders__r[0].StartDate;
				request.EndTime__c = request.Work_Orders__r[0].EndDate;
			}
		}
		update requests;
	}

}


