@istest
public class HOT_TestDataFactory {
		
	public static HOT_Request__c createRequest(String subject, WorkType workType) {
		HOT_Request__c request = new HOT_Request__c();
		request.Subject__c = subject;
		request.Status__c = 'Åpen';
		request.NumberOfInterpreters__c = 1;
		request.InterpretationMethod__c = workType.Id;
		request.StartTime__c = Datetime.now().addHours(1);
		request.EndTime__c = request.StartTime__c.addHours(2);
		return request;
	}
	
	public static WorkOrder createWorkOrder(HOT_Request__c request, WorkType workType) {
		WorkOrder workOrder = new WorkOrder();
		workOrder.HOT_Request__c = request.Id;
		workOrder.Status = 'Ny';
		workOrder.HOT_NumberOfInterpreters__c = 1;
		workOrder.StartDate = Datetime.now().addHours(1);
		workOrder.EndDate = workOrder.StartDate.addHours(2);
		workOrder.WorkTypeId = workType.Id;
		return workOrder;
	}

	public static WorkOrderLineItem createWorkOrderLineItem(WorkOrder workOrder, WorkType workType) {
		WorkOrderLineItem workOrderLineItem = new WorkOrderLineItem();
		workOrderLineItem.WorkOrderId = workOrder.Id;
		workOrderLineItem.Status = 'Ny';
		workOrderLineItem.HOT_NumberOfInterpreters__c = 1;
		workOrderLineItem.StartDate = Datetime.now().addHours(1);
		workOrderLineItem.EndDate = workOrderLineItem.StartDate.addHours(2);
		workOrderLineItem.WorkTypeId = workType.Id;
		return workOrderLineItem;
	}

	public static ServiceAppointment createServiceAppointment(WorkOrderLineItem workOrderLineItem) {
		ServiceAppointment serviceAppointment = new ServiceAppointment();
		serviceAppointment.ParentRecordId = workOrderLineItem.Id;
		serviceAppointment.Status = 'Ingen';
		serviceAppointment.EarliestStartTime = Datetime.now().addHours(1);
		serviceAppointment.DueDate = serviceAppointment.EarliestStartTime.addHours(2);
		return serviceAppointment;
	}

	public static WorkType createWorkType() {
		WorkType workType = new WorkType();
		workType.Name = 'workTypeName';
		workType.EstimatedDuration = 1;
		return workType;
	}

	public static Account createAccount(boolean isPersonAccount) {
		if(isPersonAccount){
			String personAccountRecordTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
			Account account = new Account(RecordTypeId = personAccountRecordTypeId, FirstName = 'Test', LastName = 'User', PersonEmail = 'HOT_testaccount@nav.hot.no');
			
			return account;
		}
		else{
			return new Account(Name = 'Test AS');
		}
		
	}
	
	public static Person__c createPerson(Account account) {
		Person__c person = new Person__c(CRM_Account__c=account.Id);
		return person;
	}

	public static User createUser(Profile ProfileID, Account account) {
		User user = new User (
			Username = 'HOT_testuser@nav.hot.no', 
			LastName = 'user', 
			Email = 'HOT_testuser@nav.hot.no', 
			Alias = 'user', 
			CommunityNickname = 'user', 
			TimeZoneSidKey ='Europe/Paris', 
			LocaleSidKey ='no_NO', 
			EmailEncodingKey ='UTF-8', 
			LanguageLocaleKey ='no',
			ProfileId = profileID.id, 
			ContactId=account.PersonContactId
		);
		return user;
	}

}