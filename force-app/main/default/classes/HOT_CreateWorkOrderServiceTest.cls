@IsTest(IsParallel=true)
private class HOT_CreateWorkOrderServiceTest {
    @IsTest
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

    @IsTest
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
        inputVariable.recurringEndDate = Date.today().addDays(250);

        List<HOT_CreateWorkOrderService> inputVariables = new List<HOT_CreateWorkOrderService>();
        inputVariables.add(inputVariable);

        Test.startTest();
        HOT_CreateWorkOrderService.createWorkOrders(inputVariables);
        Test.stopTest();
    }

    @IsTest
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

    @IsTest
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

    @IsTest
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

    @IsTest
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

    @IsTest
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

    @IsTest
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
    @IsTest
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
    @IsTest
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
    @IsTest
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
    @IsTest
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
    @IsTest
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
        inputVariable.recurringEndDate = Date.today().addDays(6200);

        List<HOT_CreateWorkOrderService> inputVariables = new List<HOT_CreateWorkOrderService>();
        inputVariables.add(inputVariable);

        Test.startTest();
        List<String> errors = HOT_CreateWorkOrderService.createWorkOrders(inputVariables);
        Test.stopTest();

        List<WorkOrder> workOrders = [SELECT Id, HOT_Request__c, StartDate, EndDate FROM WorkOrder];
        System.assertEquals(0, workOrders.size(), 'Det ble feilaktig opprettet arbeidsordre');
        System.assertEquals(1, errors.size(), 'Det ble feilaktig opprettet arbeidsordre');
    }
    @IsTest
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
    @IsTest
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
        System.assertEquals(0, errors.size(), 'Det ble feilaktig opprettet arbeidsordre');
    }
    @IsTest
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
        System.assertEquals(0, errors.size(), 'Det ble feilaktig opprettet arbeidsordre');
    }
    @IsTest
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
        System.assertEquals(0, errors.size(), 'Det ble feilaktig opprettet arbeidsordre');
    }
    @IsTest
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
        System.assertEquals(0, errors.size(), 'Det ble feilaktig opprettet arbeidsordre');
    }

    @IsTest
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
    @IsTest
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

    @IsTest
    private static void createRecurringWorkOrdersFromEditMovesExistingToFirstWeeklyOccurrence() {
        User caller = createRecurringEditCaller();
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('Weekly edit', workType);
        request.Orderer__c = caller.AccountId;
        insert request;

        Date tuesday = Date.newInstance(2026, 10, 27);
        Datetime startTime = Datetime.newInstance(tuesday, Time.newInstance(9, 0, 0, 0));
        Datetime endTime = startTime.addHours(1);
        WorkOrder existingWorkOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        existingWorkOrder.StartDate = startTime;
        existingWorkOrder.EndDate = endTime;
        insert existingWorkOrder;

        Test.startTest();
        System.runAs(caller) {
            HOT_CreateWorkOrderService.createRecurringWorkOrdersFromEdit(
                request.Id,
                existingWorkOrder.Id,
                startTime.getTime(),
                endTime.getTime(),
                'Weekly',
                new List<String>{ 'wednesday', 'friday' },
                Datetime.newInstanceGmt(Date.newInstance(2026, 11, 2), Time.newInstance(0, 0, 0, 0)).getTime()
            );
        }
        Test.stopTest();

        List<WorkOrder> workOrders = [
            SELECT Id, StartDate, EndDate
            FROM WorkOrder
            WHERE HOT_Request__c = :request.Id
            ORDER BY StartDate
        ];
        System.assertEquals(2, workOrders.size(), 'Weekly recurrence should create selected weekdays only');
        System.assertEquals(existingWorkOrder.Id, workOrders[0].Id, 'Existing Work Order must be first occurrence');
        System.assertEquals(
            Datetime.newInstance(Date.newInstance(2026, 10, 28), Time.newInstance(9, 0, 0, 0)),
            workOrders[0].StartDate,
            'Existing Work Order should move to the first selected weekday'
        );
        System.assertEquals(
            Datetime.newInstance(Date.newInstance(2026, 10, 30), Time.newInstance(9, 0, 0, 0)),
            workOrders[1].StartDate,
            'Additional Work Order should be created for the next selected weekday'
        );
        HOT_Request__c updatedRequest = [
            SELECT StartTime__c, EndTime__c
            FROM HOT_Request__c
            WHERE Id = :request.Id
        ];
        System.assertEquals(workOrders[0].StartDate, updatedRequest.StartTime__c);
        System.assertEquals(workOrders[0].EndDate, updatedRequest.EndTime__c);
    }

    @IsTest
    private static void createRecurringWorkOrdersFromEditSupportsAllFormRecurrenceTypes() {
        User caller = createRecurringEditCaller();
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        Date startDate = Date.newInstance(2026, 10, 26);
        Datetime startTime = Datetime.newInstance(startDate, Time.newInstance(9, 0, 0, 0));
        Datetime endTime = startTime.addHours(1);
        Date recurrenceEndDate = startDate.addDays(28);
        Map<String, Integer> expectedCounts = new Map<String, Integer>{
            'Daily' => 29,
            'Weekly' => 5,
            'Biweekly' => 3,
            'Every4Weeks' => 2
        };

        for (String recurrenceType : expectedCounts.keySet()) {
            HOT_Request__c request = HOT_TestDataFactory.createRequest(recurrenceType + ' edit', workType);
            request.Orderer__c = caller.AccountId;
            insert request;
            WorkOrder existingWorkOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
            existingWorkOrder.StartDate = startTime;
            existingWorkOrder.EndDate = endTime;
            insert existingWorkOrder;

            System.runAs(caller) {
                HOT_CreateWorkOrderService.createRecurringWorkOrdersFromEdit(
                    request.Id,
                    existingWorkOrder.Id,
                    startTime.getTime(),
                    endTime.getTime(),
                    recurrenceType,
                    new List<String>{ 'monday' },
                    Datetime.newInstanceGmt(recurrenceEndDate, Time.newInstance(0, 0, 0, 0)).getTime()
                );
            }

            System.assertEquals(
                expectedCounts.get(recurrenceType),
                [SELECT COUNT() FROM WorkOrder WHERE HOT_Request__c = :request.Id],
                'Unexpected occurrence count for ' + recurrenceType
            );
            WorkOrder updatedExisting = [
                SELECT StartDate
                FROM WorkOrder
                WHERE Id = :existingWorkOrder.Id
            ];
            System.assertEquals(
                startTime,
                updatedExisting.StartDate,
                'First matching Monday remains the first occurrence'
            );
        }
    }

    @IsTest
    private static void createRecurringWorkOrdersFromEditRejectsIneligibleWorkOrderWithoutChangingIt() {
        User caller = createRecurringEditCaller();
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('Ineligible edit', workType);
        request.Orderer__c = caller.AccountId;
        insert request;
        WorkOrder existingWorkOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert existingWorkOrder;
        existingWorkOrder.Status = 'Completed';
        update existingWorkOrder;
        Datetime originalStart = [SELECT StartDate FROM WorkOrder WHERE Id = :existingWorkOrder.Id].StartDate;
        Datetime originalRequestStart = [
            SELECT StartTime__c
            FROM HOT_Request__c
            WHERE Id = :request.Id
        ]
        .StartTime__c;

        Boolean threwException = false;
        System.runAs(caller) {
            try {
                HOT_CreateWorkOrderService.createRecurringWorkOrdersFromEdit(
                    request.Id,
                    existingWorkOrder.Id,
                    Datetime.now().addDays(1).getTime(),
                    Datetime.now().addDays(1).addHours(1).getTime(),
                    'Daily',
                    new List<String>(),
                    Datetime.now().addDays(10).getTime()
                );
            } catch (AuraHandledException e) {
                threwException = true;
            }
        }

        System.assertEquals(true, threwException, 'A non-open Work Order must not be changed into a series');
        System.assertEquals(
            originalStart,
            [SELECT StartDate FROM WorkOrder WHERE Id = :existingWorkOrder.Id].StartDate,
            'Rejected recurrence must preserve the existing interval'
        );
        System.assertEquals(
            originalRequestStart,
            [SELECT StartTime__c FROM HOT_Request__c WHERE Id = :request.Id].StartTime__c,
            'Rejected recurrence must preserve the request interval'
        );
    }

    /**
     * Creates a community caller with a person account for recurrence authorization tests.
     */
    private static User createRecurringEditCaller() {
        User admin = HOT_TestDataFactory.getUsers(1, 'System Administrator', true, true)[0];
        List<User> callers;
        System.runAs(admin) {
            Set<Id> accountIds = new Map<Id, Account>(HOT_TestDataFactory.getPersonAccounts(2)).keySet();
            callers = HOT_TestDataFactory.getEmployerCommunityUser(accountIds, 'Customer Community Plus User', true);
        }
        return [SELECT Id, AccountId FROM User WHERE Id = :callers[0].Id];
    }

    /**
     * Verifies that knowing request and Work Order IDs does not grant edit permission.
     */
    @IsTest
    private static void recurringEditRejectsUnauthorizedCallers() {
        User caller = createRecurringEditCaller();
        Account otherAccount = [
            SELECT Id
            FROM Account
            WHERE IsPersonAccount = TRUE AND Id != :caller.AccountId
            LIMIT 1
        ];
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('Unauthorized edit', workType);
        request.Orderer__c = otherAccount.Id;
        request.Account__c = caller.AccountId;
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder;
        HOT_Request__c originalRequest = [SELECT StartTime__c, EndTime__c FROM HOT_Request__c WHERE Id = :request.Id];
        User internalCaller = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        for (Integer scenario = 0; scenario < 3; scenario++) {
            if (scenario == 1) {
                request.Account__c = otherAccount.Id;
                update request;
            } else if (scenario == 2) {
                request.Orderer__c = null;
                update request;
            }
            for (User unauthorizedCaller : new List<User>{ caller, internalCaller }) {
                System.runAs(unauthorizedCaller) {
                    Boolean rejected = false;
                    try {
                        HOT_CreateWorkOrderService.createRecurringWorkOrdersFromEdit(
                            request.Id,
                            workOrder.Id,
                            Datetime.now().addDays(1).getTime(),
                            Datetime.now().addDays(1).addHours(1).getTime(),
                            'Daily',
                            new List<String>(),
                            Datetime.now().addDays(3).getTime()
                        );
                    } catch (AuraHandledException e) {
                        rejected = true;
                    }
                    System.assert(rejected, 'Only the orderer account may create a recurring series');
                }
            }
        }
        WorkOrder unchanged = [SELECT StartDate, EndDate FROM WorkOrder WHERE Id = :workOrder.Id];
        System.assertEquals(workOrder.StartDate, unchanged.StartDate);
        System.assertEquals(workOrder.EndDate, unchanged.EndDate);
        System.assertEquals(1, [SELECT COUNT() FROM WorkOrder WHERE HOT_Request__c = :request.Id]);
        HOT_Request__c unchangedRequest = [SELECT StartTime__c, EndTime__c FROM HOT_Request__c WHERE Id = :request.Id];
        System.assertEquals(originalRequest.StartTime__c, unchangedRequest.StartTime__c);
        System.assertEquals(originalRequest.EndTime__c, unchangedRequest.EndTime__c);
    }
}
