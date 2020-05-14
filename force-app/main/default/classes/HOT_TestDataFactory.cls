@istest
public class HOT_TestDataFactory {

	public static HOT_Request__c createRequest( String subject, WorkType workType ) {
		HOT_Request__c request = new HOT_Request__c();
		request.Subject__c = subject;
		request.Status__c = 'Åpen';
		request.NumberOfInterpreters__c = 1;
		request.InterpretationMethod__c = workType.Id;
		request.StartTime__c = Datetime.now().addHours( 1 );
		request.EndTime__c = request.StartTime__c.addHours( 2 );
		request.AssignmentType__c = 'Work';

		return request;
	}

	public static WorkOrder createWorkOrder( HOT_Request__c request, WorkType workType ) {
		WorkOrder workOrder = new WorkOrder();
		workOrder.HOT_Request__c = request.Id;
		workOrder.Status = 'Ny';
		workOrder.HOT_NumberOfInterpreters__c = 1;
		workOrder.StartDate = Datetime.now().addHours( 1 );
		workOrder.EndDate = workOrder.StartDate.addHours( 2 );
		workOrder.WorkTypeId = workType.Id;

		return workOrder;
	}

	public static WorkOrderLineItem createWorkOrderLineItem( WorkOrder workOrder, WorkType workType ) {
		WorkOrderLineItem workOrderLineItem = new WorkOrderLineItem();
		workOrderLineItem.WorkOrderId = workOrder.Id;
		workOrderLineItem.Status = 'Ny';
		workOrderLineItem.HOT_NumberOfInterpreters__c = 1;
		workOrderLineItem.StartDate = Datetime.now().addHours( 1 );
		workOrderLineItem.EndDate = workOrderLineItem.StartDate.addHours( 2 );
		workOrderLineItem.WorkTypeId = workType.Id;

		return workOrderLineItem;
	}

	public static ServiceAppointment createServiceAppointment( WorkOrderLineItem workOrderLineItem ) {
		ServiceAppointment serviceAppointment = new ServiceAppointment();
		serviceAppointment.ParentRecordId = workOrderLineItem.Id;
		serviceAppointment.Status = 'Ingen';
		serviceAppointment.EarliestStartTime = Datetime.now().addHours( 1 );
		serviceAppointment.DueDate = serviceAppointment.EarliestStartTime.addHours( 2 );

		return serviceAppointment;
	}

	public static WorkType createWorkType() {
		WorkType workType = new WorkType();
		workType.Name = 'workTypeName';
		workType.EstimatedDuration = 1;

		return workType;
	}

	public static Account createAccount( boolean isPersonAccount ) {
		if ( isPersonAccount ) {
			String personAccountRecordTypeId = Schema.getGlobalDescribe().get( 'Account' ).getDescribe().getRecordTypeInfosByDeveloperName().get( 'PersonAccount' ).getRecordTypeId();
			Account account = new Account( RecordTypeId = personAccountRecordTypeId, FirstName = 'Test', LastName = 'User', PersonEmail = 'HOT_testaccount@nav.hot.no' );

			return account;
		}
		else{
			return new Account( Name = 'Test AS' );
		}

	}

	public static Person__c createPerson(  ) {
		Person__c person = new Person__c();
		person.INT_Confidential__c = 'UGRADERT';
		person.Name = '12345678901';
		person.INT_LastName__c = 'Last';
		person.INT_FirstName__c = 'First';

		return person;
	}

	public static User createUser( Profile ProfileId, Account account ) {
		User user = createUser( 'User', ProfileId );
		user.ContactId = account.PersonContactId;

		return user;
	}

	public static User createUser( String lastName, Profile ProfileId ) {
		User user = new User (
			Username = 'HOT.' + lastName + '@nav.hot.no',
			LastName = lastName,
			Email = 'HOT_testuser@nav.hot.no',
			Alias = lastName,
			CommunityNickname = lastName,
			TimeZoneSidKey = 'Europe/Paris',
			LocaleSidKey = 'no_NO',
			EmailEncodingKey = 'UTF-8',
			LanguageLocaleKey = 'no',
			ProfileId = ProfileId.id
			);

		return user;
	}

	public static ServiceResource createServiceResource( Id userId )
	{
		ServiceResource resource = new ServiceResource(
			Name = 'Service Resource',
			RelatedRecordId = userId,
			IsActive = true,
			ResourceType = 'T'
			);

		return resource;
	}

	public static AssignedResource createAssignedResource( Id serviceAppointmentId, Id serviceResourceId ) {
		AssignedResource assignedResource = new AssignedResource(
			ServiceAppointmentId = serviceAppointmentId,
			ServiceResourceId = serviceResourceId
			);

		return assignedResource;
	}
}