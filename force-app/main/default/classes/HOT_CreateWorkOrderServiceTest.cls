@isTest
private class HOT_CreateWorkOrderServiceTest {
	
	@isTest
	private static void createWorkOrdersNever() {
		WorkType workType = HOT_TestDataFactory.createWorkType();
		insert workType;
		HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
		insert request;

		HOT_CreateWorkOrderService inputVariable = new HOT_CreateWorkOrderService();
		inputVariable.requestId = request.Id;
		inputVariable.startDate = Datetime.now();
		inputVariable.endDate = Datetime.now().addHours(1);
		inputVariable.recurringType = 'Never';

		List<HOT_CreateWorkOrderService> inputVariables = new List<HOT_CreateWorkOrderService>();
		inputVariables.add(inputVariable);

		Test.startTest();
		HOT_CreateWorkOrderService.createWorkOrders(inputVariables);
		Test.stopTest();

		List<WorkOrder> workOrders = [SELECT Id, HOT_Request__c, StartDate, EndDate FROM WorkOrder];
		System.assertEquals(1, workOrders.size(), 'Det ble ikke opprettet korrekt antall arbeidsordre');
		System.assertEquals(request.Id, workOrders[0].HOT_Request__c, 'Arbeidsordre ble ikke knyttet til riktig forespørsel');
		System.assertEquals(inputVariable.startDate, workOrders[0].StartDate, 'Arbeidsordre ble ikke knyttet til riktig forespørsel');
		System.assertEquals(inputVariable.endDate, workOrders[0].EndDate, 'Arbeidsordre ble ikke knyttet til riktig forespørsel');
	}

	@isTest
	private static void createWorkOrdersDaily() {
		WorkType workType = HOT_TestDataFactory.createWorkType();
		insert workType;
		HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
		insert request;

		HOT_CreateWorkOrderService inputVariable = new HOT_CreateWorkOrderService();
		inputVariable.requestId = request.Id;
		inputVariable.startDate = Datetime.now();
		inputVariable.endDate = Datetime.now().addHours(1);
		inputVariable.recurringType = 'Daily';
		inputVariable.recurringEndDate = Date.today().addDays(10);

		List<HOT_CreateWorkOrderService> inputVariables = new List<HOT_CreateWorkOrderService>();
		inputVariables.add(inputVariable);

		Test.startTest();
		HOT_CreateWorkOrderService.createWorkOrders(inputVariables);
		Test.stopTest();

		List<WorkOrder> workOrders = [SELECT Id, HOT_Request__c, StartDate, EndDate FROM WorkOrder];
		System.assertEquals(11, workOrders.size(), 'Det ble ikke opprettet korrekt antall arbeidsordre');
	}

	@isTest
	private static void createWorkOrdersWeekly() {
		WorkType workType = HOT_TestDataFactory.createWorkType();
		insert workType;
		HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
		insert request;

		HOT_CreateWorkOrderService inputVariable = new HOT_CreateWorkOrderService();
		inputVariable.requestId = request.Id;
		inputVariable.startDate = Datetime.now();
		inputVariable.endDate = Datetime.now().addHours(1);
		inputVariable.recurringType = 'Weekly';
		inputVariable.recurringEndDate = Date.today().addDays(14);
		inputVariable.monday = true;
		inputVariable.tuesday = true;
		inputVariable.wendesday = true;
		inputVariable.thursday = true;
		inputVariable.friday = true;
		inputVariable.saturday = true;
		inputVariable.sunday = true;

		List<HOT_CreateWorkOrderService> inputVariables = new List<HOT_CreateWorkOrderService>();
		inputVariables.add(inputVariable);

		Test.startTest();
		HOT_CreateWorkOrderService.createWorkOrders(inputVariables);
		Test.stopTest();

		List<WorkOrder> workOrders = [SELECT Id, HOT_Request__c, StartDate, EndDate FROM WorkOrder];
		System.assertEquals(15, workOrders.size(), 'Det ble ikke opprettet korrekt antall arbeidsordre');
	}

	@isTest
	private static void createWorkOrdersMonthly() {
		WorkType workType = HOT_TestDataFactory.createWorkType();
		insert workType;
		HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
		insert request;

		HOT_CreateWorkOrderService inputVariable = new HOT_CreateWorkOrderService();
		inputVariable.requestId = request.Id;
		inputVariable.startDate = Datetime.now();
		inputVariable.endDate = Datetime.now().addHours(1);
		inputVariable.recurringType = 'Monthly';
		inputVariable.recurringEndDate = Date.today().addMonths(10);

		List<HOT_CreateWorkOrderService> inputVariables = new List<HOT_CreateWorkOrderService>();
		inputVariables.add(inputVariable);

		Test.startTest();
		HOT_CreateWorkOrderService.createWorkOrders(inputVariables);
		Test.stopTest();

		List<WorkOrder> workOrders = [SELECT Id, HOT_Request__c, StartDate, EndDate FROM WorkOrder];
		System.assertEquals(11, workOrders.size(), 'Det ble ikke opprettet korrekt antall arbeidsordre');
	}
}
