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
        System.assertEquals(
            request.Id,
            workOrders[0].HOT_Request__c,
            'Arbeidsordre ble ikke knyttet til riktig forespørsel'
        );
        System.assertEquals(
            inputVariable.startDate,
            workOrders[0].StartDate,
            'Arbeidsordre ble ikke knyttet til riktig forespørsel'
        );
        System.assertEquals(
            inputVariable.endDate,
            workOrders[0].EndDate,
            'Arbeidsordre ble ikke knyttet til riktig forespørsel'
        );
    }

    @isTest
    private static void createOver200WorkOrdersToFail() {
        Boolean errorOccured = false;
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;

        HOT_CreateWorkOrderService inputVariable = new HOT_CreateWorkOrderService();
        inputVariable.requestId = request.Id;
        inputVariable.startDate = Datetime.now();
        inputVariable.endDate = Datetime.now().addHours(1);
        inputVariable.recurringType = 'Daily';
        inputVariable.recurringEndDate = Date.today().addDays(201);

        List<HOT_CreateWorkOrderService> inputVariables = new List<HOT_CreateWorkOrderService>();
        inputVariables.add(inputVariable);

        Test.startTest();
        try {
            HOT_CreateWorkOrderService.createWorkOrders(inputVariables);
        } catch (Exception e) {
            errorOccured = e.getMessage().length() > 0 ? true : false;
        }
        Test.stopTest();
        List<WorkOrder> workOrders = [SELECT Id, HOT_Request__c, StartDate, EndDate FROM WorkOrder];
        System.assertEquals(true, errorOccured, 'Det ble opprettet feil antall AO-er');
        System.assertEquals(0, workOrders.size(), 'Det ble opprettet feil antall AO-er');
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
        inputVariable.recurringEndDate = Date.today().addDays(13);
        inputVariable.monday = true;
        inputVariable.tuesday = true;
        inputVariable.wednesday = true;
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
        System.assertEquals(14, workOrders.size(), 'Det ble ikke opprettet korrekt antall arbeidsordre');
    }

    @isTest
    private static void createWorkOrdersBiweekly() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;

        HOT_CreateWorkOrderService inputVariable = new HOT_CreateWorkOrderService();
        inputVariable.requestId = request.Id;
        inputVariable.startDate = Datetime.now();
        inputVariable.endDate = Datetime.now().addHours(1);
        inputVariable.recurringType = 'Biweekly';
        inputVariable.recurringEndDate = Date.today().addDays(27);
        inputVariable.monday = true;
        inputVariable.tuesday = true;
        inputVariable.wednesday = true;
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
        System.assertEquals(14, workOrders.size(), 'Det ble ikke opprettet korrekt antall arbeidsordre');
    }

    @isTest
    private static void createWorkOrdersMonthly_1() {
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

    @isTest
    private static void createWorkOrdersMonthly_2() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;

        HOT_CreateWorkOrderService inputVariable = new HOT_CreateWorkOrderService();
        inputVariable.requestId = request.Id;
        inputVariable.startDate = Datetime.now();
        inputVariable.endDate = Datetime.now().addHours(1);
        inputVariable.recurringType = 'Monthly';
        inputVariable.recurringEndDate = Date.today().addMonths(10).addDays(10);

        List<HOT_CreateWorkOrderService> inputVariables = new List<HOT_CreateWorkOrderService>();
        inputVariables.add(inputVariable);

        Test.startTest();
        HOT_CreateWorkOrderService.createWorkOrders(inputVariables);
        Test.stopTest();

        List<WorkOrder> workOrders = [SELECT Id, HOT_Request__c, StartDate, EndDate FROM WorkOrder];
        System.assertEquals(11, workOrders.size(), 'Det ble ikke opprettet korrekt antall arbeidsordre');
    }

    @isTest
    private static void Error_EndTimeBeforeStartTime() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;

        HOT_CreateWorkOrderService inputVariable = new HOT_CreateWorkOrderService();
        inputVariable.requestId = request.Id;
        inputVariable.startDate = Datetime.now().addHours(1);
        inputVariable.endDate = Datetime.now();
        inputVariable.recurringType = 'Never';

        List<HOT_CreateWorkOrderService> inputVariables = new List<HOT_CreateWorkOrderService>();
        inputVariables.add(inputVariable);

        Test.startTest();
        List<String> errors = HOT_CreateWorkOrderService.createWorkOrders(inputVariables);
        Test.stopTest();

        List<WorkOrder> workOrders = [SELECT Id, HOT_Request__c, StartDate, EndDate FROM WorkOrder];
        System.assertEquals(0, workOrders.size(), 'Det ble feilaktig opprettet arbeidsordre');
        System.assertEquals(1, errors.size(), 'Det ble feilaktig opprettet arbeidsordre');
    }
    @isTest
    private static void Error_recurringEndDateEqualStartDate() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;

        HOT_CreateWorkOrderService inputVariable = new HOT_CreateWorkOrderService();
        inputVariable.requestId = request.Id;
        inputVariable.startDate = Datetime.now();
        inputVariable.endDate = Datetime.now().addHours(1);
        inputVariable.recurringType = 'Monthly';
        inputVariable.recurringEndDate = Date.today();

        List<HOT_CreateWorkOrderService> inputVariables = new List<HOT_CreateWorkOrderService>();
        inputVariables.add(inputVariable);

        Test.startTest();
        List<String> errors = HOT_CreateWorkOrderService.createWorkOrders(inputVariables);
        Test.stopTest();

        List<WorkOrder> workOrders = [SELECT Id, HOT_Request__c, StartDate, EndDate FROM WorkOrder];
        System.assertEquals(0, workOrders.size(), 'Det ble feilaktig opprettet arbeidsordre');
        System.assertEquals(1, errors.size(), 'Det ble feilaktig opprettet arbeidsordre');
    }
    @isTest
    private static void Error_WeeklyAllDaysFalse() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;

        HOT_CreateWorkOrderService inputVariable = new HOT_CreateWorkOrderService();
        inputVariable.requestId = request.Id;
        inputVariable.startDate = Datetime.now();
        inputVariable.endDate = Datetime.now().addHours(1);
        inputVariable.recurringType = 'Weekly';
        inputVariable.recurringEndDate = Date.today().addDays(7);
        inputVariable.monday = false;
        inputVariable.tuesday = false;
        inputVariable.wednesday = false;
        inputVariable.thursday = false;
        inputVariable.friday = false;
        inputVariable.saturday = false;
        inputVariable.sunday = false;

        List<HOT_CreateWorkOrderService> inputVariables = new List<HOT_CreateWorkOrderService>();
        inputVariables.add(inputVariable);

        Test.startTest();
        List<String> errors = HOT_CreateWorkOrderService.createWorkOrders(inputVariables);
        Test.stopTest();

        List<WorkOrder> workOrders = [SELECT Id, HOT_Request__c, StartDate, EndDate FROM WorkOrder];
        System.assertEquals(0, workOrders.size(), 'Det ble feilaktig opprettet arbeidsordre');
        System.assertEquals(1, errors.size(), 'Det ble feilaktig opprettet arbeidsordre');
    }
    @isTest
    private static void Error_Daily201() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;

        HOT_CreateWorkOrderService inputVariable = new HOT_CreateWorkOrderService();
        inputVariable.requestId = request.Id;
        inputVariable.startDate = Datetime.now();
        inputVariable.endDate = Datetime.now().addHours(1);
        inputVariable.recurringType = 'Daily';
        inputVariable.recurringEndDate = Date.today().addDays(201);

        List<HOT_CreateWorkOrderService> inputVariables = new List<HOT_CreateWorkOrderService>();
        inputVariables.add(inputVariable);

        Test.startTest();
        List<String> errors = HOT_CreateWorkOrderService.createWorkOrders(inputVariables);
        Test.stopTest();

        List<WorkOrder> workOrders = [SELECT Id, HOT_Request__c, StartDate, EndDate FROM WorkOrder];
        System.assertEquals(0, workOrders.size(), 'Det ble feilaktig opprettet arbeidsordre');
        System.assertEquals(1, errors.size(), 'Det ble feilaktig opprettet arbeidsordre');
    }
    @isTest
    private static void Error_Weekly201() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;

        HOT_CreateWorkOrderService inputVariable = new HOT_CreateWorkOrderService();
        inputVariable.requestId = request.Id;
        inputVariable.startDate = Datetime.now();
        inputVariable.endDate = Datetime.now().addHours(1);
        inputVariable.recurringType = 'Weekly';
        inputVariable.recurringEndDate = Date.today().addDays(201);
        inputVariable.monday = true;
        inputVariable.tuesday = true;
        inputVariable.wednesday = true;
        inputVariable.thursday = true;
        inputVariable.friday = true;
        inputVariable.saturday = true;
        inputVariable.sunday = true;

        List<HOT_CreateWorkOrderService> inputVariables = new List<HOT_CreateWorkOrderService>();
        inputVariables.add(inputVariable);

        Test.startTest();
        List<String> errors = HOT_CreateWorkOrderService.createWorkOrders(inputVariables);
        Test.stopTest();

        List<WorkOrder> workOrders = [SELECT Id, HOT_Request__c, StartDate, EndDate FROM WorkOrder];
        System.assertEquals(0, workOrders.size(), 'Det ble feilaktig opprettet arbeidsordre');
        System.assertEquals(1, errors.size(), 'Det ble feilaktig opprettet arbeidsordre');
    }
    @isTest
    private static void Error_Monthly201() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;

        HOT_CreateWorkOrderService inputVariable = new HOT_CreateWorkOrderService();
        inputVariable.requestId = null;
        inputVariable.startDate = Datetime.now();
        inputVariable.endDate = Datetime.now().addHours(1);
        inputVariable.recurringType = 'Monthly';
        inputVariable.recurringEndDate = Date.today().addDays(6100);

        List<HOT_CreateWorkOrderService> inputVariables = new List<HOT_CreateWorkOrderService>();
        inputVariables.add(inputVariable);

        Test.startTest();
        List<String> errors = HOT_CreateWorkOrderService.createWorkOrders(inputVariables);
        Test.stopTest();

        List<WorkOrder> workOrders = [SELECT Id, HOT_Request__c, StartDate, EndDate FROM WorkOrder];
        System.assertEquals(0, workOrders.size(), 'Det ble feilaktig opprettet arbeidsordre');
        System.assertEquals(1, errors.size(), 'Det ble feilaktig opprettet arbeidsordre');
    }
    @isTest
    private static void Error_TypeNULL() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;

        HOT_CreateWorkOrderService inputVariable = new HOT_CreateWorkOrderService();
        inputVariable.requestId = request.Id;
        inputVariable.startDate = Datetime.now();
        inputVariable.endDate = Datetime.now().addHours(1);

        List<HOT_CreateWorkOrderService> inputVariables = new List<HOT_CreateWorkOrderService>();
        inputVariables.add(inputVariable);

        Test.startTest();
        List<String> errors = HOT_CreateWorkOrderService.createWorkOrders(inputVariables);
        Test.stopTest();

        List<WorkOrder> workOrders = [SELECT Id, HOT_Request__c, StartDate, EndDate FROM WorkOrder];
        System.assertEquals(0, workOrders.size(), 'Det ble feilaktig opprettet arbeidsordre');
        System.assertEquals(0, errors.size(), 'Det ble feilaktig opprettet arbeidsordre');
    }
    @isTest
    private static void Error_NeverRequestNULL() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;

        HOT_CreateWorkOrderService inputVariable = new HOT_CreateWorkOrderService();
        inputVariable.requestId = null;
        inputVariable.startDate = Datetime.now();
        inputVariable.endDate = Datetime.now().addHours(1);
        inputVariable.recurringType = 'Never';

        List<HOT_CreateWorkOrderService> inputVariables = new List<HOT_CreateWorkOrderService>();
        inputVariables.add(inputVariable);

        Test.startTest();
        List<String> errors = HOT_CreateWorkOrderService.createWorkOrders(inputVariables);
        Test.stopTest();

        List<WorkOrder> workOrders = [SELECT Id, HOT_Request__c, StartDate, EndDate FROM WorkOrder];
        System.assertEquals(0, workOrders.size(), 'Det ble feilaktig opprettet arbeidsordre');
        System.assertEquals(1, errors.size(), 'Det ble feilaktig opprettet arbeidsordre');
    }
    @isTest
    private static void Error_DailyRequestNULL() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;

        HOT_CreateWorkOrderService inputVariable = new HOT_CreateWorkOrderService();
        inputVariable.requestId = null;
        inputVariable.startDate = Datetime.now();
        inputVariable.endDate = Datetime.now().addHours(1);
        inputVariable.recurringType = 'Daily';
        inputVariable.recurringEndDate = Date.today().addDays(1);

        List<HOT_CreateWorkOrderService> inputVariables = new List<HOT_CreateWorkOrderService>();
        inputVariables.add(inputVariable);

        Test.startTest();
        List<String> errors = HOT_CreateWorkOrderService.createWorkOrders(inputVariables);
        Test.stopTest();

        List<WorkOrder> workOrders = [SELECT Id, HOT_Request__c, StartDate, EndDate FROM WorkOrder];
        System.assertEquals(0, workOrders.size(), 'Det ble feilaktig opprettet arbeidsordre');
        System.assertEquals(1, errors.size(), 'Det ble feilaktig opprettet arbeidsordre');
    }
    @isTest
    private static void Error_WeeklyRequestNULL() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;

        HOT_CreateWorkOrderService inputVariable = new HOT_CreateWorkOrderService();
        inputVariable.requestId = null;
        inputVariable.startDate = Datetime.now();
        inputVariable.endDate = Datetime.now().addHours(1);
        inputVariable.recurringType = 'Weekly';
        inputVariable.recurringEndDate = Date.today().addDays(7);
        inputVariable.monday = true;
        inputVariable.tuesday = true;
        inputVariable.wednesday = true;
        inputVariable.thursday = true;
        inputVariable.friday = true;
        inputVariable.saturday = true;
        inputVariable.sunday = true;

        List<HOT_CreateWorkOrderService> inputVariables = new List<HOT_CreateWorkOrderService>();
        inputVariables.add(inputVariable);

        Test.startTest();
        List<String> errors = HOT_CreateWorkOrderService.createWorkOrders(inputVariables);
        Test.stopTest();

        List<WorkOrder> workOrders = [SELECT Id, HOT_Request__c, StartDate, EndDate FROM WorkOrder];
        System.assertEquals(0, workOrders.size(), 'Det ble feilaktig opprettet arbeidsordre');
        System.assertEquals(1, errors.size(), 'Det ble feilaktig opprettet arbeidsordre');
    }
    @isTest
    private static void Error_MonthlyRequestNULL() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;

        HOT_CreateWorkOrderService inputVariable = new HOT_CreateWorkOrderService();
        inputVariable.requestId = null;
        inputVariable.startDate = Datetime.now();
        inputVariable.endDate = Datetime.now().addHours(1);
        inputVariable.recurringType = 'Monthly';
        inputVariable.recurringEndDate = Date.today().addDays(60);

        List<HOT_CreateWorkOrderService> inputVariables = new List<HOT_CreateWorkOrderService>();
        inputVariables.add(inputVariable);

        Test.startTest();
        List<String> errors = HOT_CreateWorkOrderService.createWorkOrders(inputVariables);
        Test.stopTest();

        List<WorkOrder> workOrders = [SELECT Id, HOT_Request__c, StartDate, EndDate FROM WorkOrder];
        System.assertEquals(0, workOrders.size(), 'Det ble feilaktig opprettet arbeidsordre');
        System.assertEquals(1, errors.size(), 'Det ble feilaktig opprettet arbeidsordre');
    }

    @isTest
    private static void createWorkOrdersfromCommunity() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;

        String requestId = (String) request.Id;
        Map<String, Long> times = new Map<String, Long>();
        times.put('startTime', Datetime.now().addHours(1).getTime());
        times.put('endTime', Datetime.now().addHours(2).getTime());
        String recurringType = 'Never';
        List<String> recurringDays = new List<String>{ 'monday', 'tuesday' };
        Long recurringEndDate = Datetime.now().addDays(30).getTime();

        Test.startTest();
        HOT_CreateWorkOrderService.createWorkOrdersFromCommunity(
            requestId,
            times,
            recurringType,
            recurringDays,
            recurringEndDate
        );
        Test.stopTest();

        List<WorkOrder> workOrders = [SELECT Id, HOT_Request__c, StartDate, EndDate FROM WorkOrder];
        System.assertEquals(1, workOrders.size(), 'Det ble ikke opprettet korrekt antall arbeidsordre');
    }
    @isTest
    private static void Error_TooManyWorkOrders() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('TEST', workType);
        insert request;

        HOT_CreateWorkOrderService inputVariable = new HOT_CreateWorkOrderService();
        inputVariable.requestId = null;
        inputVariable.startDate = DateTime.now();
        inputVariable.endDate = inputVariable.startDate.addHours(3);
        inputVariable.recurringType = 'Biweekly';
        inputVariable.monday = true;
        inputVariable.tuesday = true;
        inputVariable.wednesday = true;
        inputVariable.thursday = true;
        inputVariable.friday = true;
        inputVariable.saturday = true;
        inputVariable.sunday = true;
        inputVariable.recurringEndDate = Date.today().addDays(2000);

        List<HOT_CreateWorkOrderService> inputVariables = new List<HOT_CreateWorkOrderService>();
        inputVariables.add(inputVariable);

        Test.startTest();
        List<String> errors = HOT_CreateWorkOrderService.createWorkOrders(inputVariables);
        Test.stopTest();

        List<WorkOrder> workOrders = [SELECT Id, HOT_Request__c, StartDate, EndDate FROM WorkOrder];
        System.assertEquals(0, workOrders.size(), 'Det ble feilaktig opprettet arbeidsordre');
        System.assertEquals(1, errors.size(), 'Kan ikke opprette mere en 200 arbeidsordre av gangen');
    }
}
