@IsTest(IsParallel=false)
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
                Datetime.newInstanceGmt(Date.newInstance(2026, 11, 2), Time.newInstance(0, 0, 0, 0)).getTime(),
                new Map<String, Object>{ 'Id' => request.Id, 'Subject__c' => 'Updated series' }
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
            SELECT StartTime__c, EndTime__c, Subject__c
            FROM HOT_Request__c
            WHERE Id = :request.Id
        ];
        System.assertEquals(workOrders[0].StartDate, updatedRequest.StartTime__c);
        System.assertEquals(workOrders[0].EndDate, updatedRequest.EndTime__c);
        System.assertEquals('Updated series', updatedRequest.Subject__c);
    }

    @IsTest
    private static void recurringEditSupportsDaily() {
        assertRecurringEditCount('Daily', 29);
    }

    @IsTest
    private static void recurringEditSupportsWeekly() {
        assertRecurringEditCount('Weekly', 5);
    }

    @IsTest
    private static void recurringEditSupportsBiweekly() {
        assertRecurringEditCount('Biweekly', 3);
    }

    @IsTest
    private static void recurringEditSupportsEvery4Weeks() {
        assertRecurringEditCount('Every4Weeks', 2);
    }

    /**
     * Checks each recurrence type with a separate governor limit budget from test data setup.
     */
    private static void assertRecurringEditCount(String recurrenceType, Integer expectedCount) {
        Date startDate = Date.newInstance(2026, 10, 26);
        Datetime startTime = Datetime.newInstance(startDate, Time.newInstance(9, 0, 0, 0));
        assertRecurringEditMatchesCreation(
            recurrenceType,
            expectedCount,
            startTime,
            startTime.addHours(1),
            startDate.addDays(28),
            new List<String>{ 'monday' }
        );
    }

    /**
     * Compares every interval against the existing community creation path in the same timezone.
     */
    private static void assertRecurringEditMatchesCreation(
        String recurrenceType,
        Integer expectedCount,
        Datetime startTime,
        Datetime endTime,
        Date recurrenceEndDate,
        List<String> selectedDays
    ) {
        User caller = createRecurringEditCaller();
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c newRequest = HOT_TestDataFactory.createRequest(recurrenceType + ' creation', workType);
        insert newRequest;
        Long recurringEndDate = Datetime.newInstanceGmt(recurrenceEndDate, Time.newInstance(0, 0, 0, 0)).getTime();
        Map<String, Object> preview;
        System.runAs(caller) {
            Integer dmlBefore = Limits.getDmlStatements();
            Integer queriesBefore = Limits.getQueries();
            preview = HOT_CreateWorkOrderService.previewRecurringWorkOrders(
                startTime.getTime(),
                endTime.getTime(),
                recurringEndDate,
                recurrenceType,
                selectedDays
            );
            System.assertEquals(dmlBefore, Limits.getDmlStatements(), 'Preview must not change records');
            System.assertEquals(queriesBefore, Limits.getQueries(), 'Preview must not read records');
            HOT_CreateWorkOrderService.createWorkOrdersFromCommunity(
                newRequest.Id,
                new Map<String, Long>{ 'startTime' => startTime.getTime(), 'endTime' => endTime.getTime() },
                recurrenceType,
                selectedDays,
                recurringEndDate
            );
        }
        HOT_Request__c request = HOT_TestDataFactory.createRequest(recurrenceType + ' edit', workType);
        request.Orderer__c = caller.AccountId;
        insert request;
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
                recurrenceType,
                selectedDays,
                recurringEndDate,
                null
            );
        }
        Test.stopTest();

        System.assertEquals(
            expectedCount,
            [SELECT COUNT() FROM WorkOrder WHERE HOT_Request__c = :request.Id],
            'Unexpected occurrence count for ' + recurrenceType
        );
        List<WorkOrder> created = [
            SELECT StartDate, EndDate
            FROM WorkOrder
            WHERE HOT_Request__c = :newRequest.Id
            ORDER BY StartDate, EndDate
        ];
        List<WorkOrder> converted = [
            SELECT Id, StartDate, EndDate
            FROM WorkOrder
            WHERE HOT_Request__c = :request.Id
            ORDER BY StartDate, EndDate
        ];
        System.assertEquals(expectedCount, created.size(), 'Creation must produce the expected interval count');
        System.assertEquals(expectedCount, preview.get('count'), 'Preview count must match creation');
        List<Map<String, Object>> intervals = (List<Map<String, Object>>) preview.get('intervals');
        System.assertEquals(existingWorkOrder.Id, converted[0].Id, 'Existing Work Order must remain first');
        for (Integer i = 0; i < created.size(); i++) {
            System.assertEquals(created[i].StartDate.getTime(), intervals[i].get('startTime'), 'Preview start at ' + i);
            System.assertEquals(created[i].EndDate.getTime(), intervals[i].get('endTime'), 'Preview end at ' + i);
            System.assertEquals(created[i].StartDate, converted[i].StartDate, 'Start must match creation at ' + i);
            System.assertEquals(created[i].EndDate, converted[i].EndDate, 'End must match creation at ' + i);
        }
    }

    @IsTest
    private static void previewPreservesAutumnWeekdaySelection() {
        System.runAs(previewCaller('Europe/Paris')) {
            Map<String, Object> preview = HOT_CreateWorkOrderService.previewRecurringWorkOrders(
                Datetime.newInstanceGmt(2027, 10, 29, 22, 30, 0).getTime(),
                Datetime.newInstanceGmt(2027, 10, 29, 23, 30, 0).getTime(),
                Datetime.newInstanceGmt(2027, 11, 2, 0, 0, 0).getTime(),
                'Weekly',
                new List<String>{ 'sunday' }
            );
            System.assertEquals(2, preview.get('count'));
            System.assertEquals('2027-10-31', preview.get('firstDate'));
            System.assertEquals('2027-11-01', preview.get('lastDate'));
            System.assertEquals('Europe/Paris', preview.get('timeZone'));
            List<Map<String, Object>> intervals = (List<Map<String, Object>>) preview.get('intervals');
            System.assertEquals('01.11.2027 00:30', intervals[1].get('startLabel'));
        }
    }

    @IsTest
    private static void previewPreservesSpringWeekdaySelection() {
        System.runAs(previewCaller('Europe/Paris')) {
            Map<String, Object> preview = HOT_CreateWorkOrderService.previewRecurringWorkOrders(
                Datetime.newInstanceGmt(2027, 3, 26, 22, 30, 0).getTime(),
                Datetime.newInstanceGmt(2027, 3, 26, 23, 30, 0).getTime(),
                Datetime.newInstanceGmt(2027, 3, 30, 0, 0, 0).getTime(),
                'Weekly',
                new List<String>{ 'monday' }
            );
            System.assertEquals(1, preview.get('count'));
            System.assertEquals('2027-03-28', preview.get('firstDate'));
            List<Map<String, Object>> intervals = (List<Map<String, Object>>) preview.get('intervals');
            System.assertEquals('28.03.2027 23:30', intervals[0].get('startLabel'));
            System.assertEquals('29.03.2027 00:30', intervals[0].get('endLabel'));
        }
    }

    @IsTest
    private static void previewPreservesOvernightEndCorrection() {
        System.runAs(previewCaller('Europe/Paris')) {
            Map<String, Object> preview = HOT_CreateWorkOrderService.previewRecurringWorkOrders(
                Datetime.newInstanceGmt(2027, 10, 29, 21, 0, 0).getTime(),
                Datetime.newInstanceGmt(2027, 10, 30, 1, 0, 0).getTime(),
                Datetime.newInstanceGmt(2027, 10, 31, 0, 0, 0).getTime(),
                'Daily',
                new List<String>()
            );
            List<Map<String, Object>> intervals = (List<Map<String, Object>>) preview.get('intervals');
            System.assertEquals('30.10.2027 23:00', intervals[1].get('startLabel'));
            System.assertEquals('31.10.2027 02:00', intervals[1].get('endLabel'));
        }
    }

    @IsTest
    private static void previewUsesCallerTimezoneForEndBoundary() {
        System.runAs(previewCaller('America/New_York')) {
            Map<String, Object> preview = HOT_CreateWorkOrderService.previewRecurringWorkOrders(
                Datetime.newInstanceGmt(2027, 10, 30, 14, 0, 0).getTime(),
                Datetime.newInstanceGmt(2027, 10, 30, 15, 0, 0).getTime(),
                Datetime.newInstanceGmt(2027, 11, 2, 0, 0, 0).getTime(),
                'Daily',
                new List<String>()
            );
            System.assertEquals(3, preview.get('count'));
            System.assertEquals('2027-11-01', preview.get('lastDate'));
            List<Map<String, Object>> intervals = (List<Map<String, Object>>) preview.get('intervals');
            System.assertEquals('30.10.2027 10:00', intervals[0].get('startLabel'));
        }
    }

    @IsTest
    private static void previewReturnsEmptySeriesWithoutDml() {
        System.runAs(previewCaller('Europe/Paris')) {
            Integer dmlBefore = Limits.getDmlStatements();
            Map<String, Object> preview = HOT_CreateWorkOrderService.previewRecurringWorkOrders(
                Datetime.newInstanceGmt(2027, 10, 26, 8, 0, 0).getTime(),
                Datetime.newInstanceGmt(2027, 10, 26, 9, 0, 0).getTime(),
                Datetime.newInstanceGmt(2027, 10, 27, 0, 0, 0).getTime(),
                'Weekly',
                new List<String>{ 'monday' }
            );
            System.assertEquals(0, preview.get('count'));
            System.assertEquals(null, preview.get('firstDate'));
            System.assertEquals(null, preview.get('lastDate'));
            System.assertEquals(dmlBefore, Limits.getDmlStatements());
        }
    }

    @IsTest
    private static void previewRejectsInvalidParameters() {
        Long startTime = Datetime.newInstanceGmt(2027, 10, 26, 8, 0, 0).getTime();
        Long endTime = startTime + 3600000;
        Long seriesEnd = startTime + 86400000;
        List<List<Object>> invalidInputs = new List<List<Object>>{
            new List<Object>{ null, endTime, seriesEnd, 'Daily', new List<String>() },
            new List<Object>{ startTime, startTime, seriesEnd, 'Daily', new List<String>() },
            new List<Object>{ startTime, endTime, startTime, 'Daily', new List<String>() },
            new List<Object>{ startTime, endTime, startTime + 200L * 86400000, 'Daily', new List<String>() },
            new List<Object>{ startTime, endTime, seriesEnd, 'Monthly', new List<String>() },
            new List<Object>{ startTime, endTime, seriesEnd, 'Weekly', new List<String>() },
            new List<Object>{ startTime, endTime, seriesEnd, 'Weekly', new List<String>{ 'invalid' } }
        };
        for (List<Object> input : invalidInputs) {
            Boolean rejected = false;
            try {
                HOT_CreateWorkOrderService.previewRecurringWorkOrders(
                    (Long) input[0],
                    (Long) input[1],
                    (Long) input[2],
                    (String) input[3],
                    (List<String>) input[4]
                );
            } catch (AuraHandledException e) {
                rejected = true;
            }
            System.assert(rejected, 'Invalid preview input must fail explicitly');
        }
    }

    /**
     * Runs timezone calculations with an internal user and no request/account setup.
     */
    private static User previewCaller(String timeZoneId) {
        return new User(
            Alias = 'preview',
            Email = 'preview' + timeZoneId.replace('/', '.') + '@nav.no',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Preview',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_GB',
            ProfileId = UserInfo.getProfileId(),
            TimeZoneSidKey = timeZoneId,
            Username = 'preview.' + timeZoneId.replace('/', '.') + '.' + UserInfo.getOrganizationId() + '@example.com'
        );
    }

    @IsTest
    private static void recurringEditMatchesCreationAcrossAutumnDst() {
        assertRecurringEditMatchesCreation(
            'Daily',
            3,
            Datetime.newInstanceGmt(2027, 10, 29, 21, 0, 0),
            Datetime.newInstanceGmt(2027, 10, 30, 1, 0, 0),
            Date.newInstance(2027, 10, 31),
            new List<String>()
        );
    }

    @IsTest
    private static void recurringEditMatchesCreationAcrossSpringDst() {
        assertRecurringEditMatchesCreation(
            'Daily',
            3,
            Datetime.newInstanceGmt(2027, 3, 26, 22, 0, 0),
            Datetime.newInstanceGmt(2027, 3, 27, 2, 0, 0),
            Date.newInstance(2027, 3, 28),
            new List<String>()
        );
    }

    @IsTest
    private static void recurringEditMatchesCreationWeekdaysAcrossDst() {
        assertRecurringEditMatchesCreation(
            'Weekly',
            2,
            Datetime.newInstanceGmt(2027, 10, 29, 22, 30, 0),
            Datetime.newInstanceGmt(2027, 10, 29, 23, 30, 0),
            Date.newInstance(2027, 11, 2),
            new List<String>{ 'sunday' }
        );
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
                    Datetime.now().addDays(10).getTime(),
                    new Map<String, Object>{ 'Id' => request.Id, 'Subject__c' => 'Must not be saved' }
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
        System.assertEquals(
            'Ineligible edit',
            [SELECT Subject__c FROM HOT_Request__c WHERE Id = :request.Id].Subject__c
        );
    }

    /**
     * Creates a community caller with a person account for recurrence authorization tests.
     */
    private static User createRecurringEditCaller() {
        User admin;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            admin = HOT_TestDataFactory.getUsers(1, 'System Administrator', true, true)[0];
        }
        List<User> callers;
        System.runAs(admin) {
            Set<Id> accountIds = new Map<Id, Account>(HOT_TestDataFactory.getPersonAccounts(2)).keySet();
            callers = HOT_TestDataFactory.getEmployerCommunityUser(accountIds, 'Customer Community Plus User', true);
            Id permissionSetId = [SELECT Id FROM PermissionSet WHERE Name = 'HOT_Tolk_Bruker_v2'].Id;
            insert new PermissionSetAssignment(AssigneeId = callers[0].Id, PermissionSetId = permissionSetId);
        }
        return [SELECT Id, AccountId FROM User WHERE Id = :callers[0].Id];
    }

    /**
     * Verifies that Work Order validation failure rolls back the preceding request edits.
     */
    @IsTest
    private static void recurringEditRollsBackOnWorkOrderFailure() {
        User caller = createRecurringEditCaller();
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('Original subject', workType);
        request.Orderer__c = caller.AccountId;
        insert request;
        WorkOrder workOrder = HOT_TestDataFactory.createWorkOrder(request, workType);
        insert workOrder;
        HOT_Request__c original = [SELECT StartTime__c, EndTime__c FROM HOT_Request__c WHERE Id = :request.Id];
        Boolean rejected = false;
        Test.startTest();
        System.runAs(caller) {
            try {
                HOT_CreateWorkOrderService.createRecurringWorkOrdersFromEdit(
                    request.Id,
                    workOrder.Id,
                    Datetime.now().addDays(1).getTime(),
                    Datetime.now().addDays(1).addHours(25).getTime(),
                    'Daily',
                    new List<String>(),
                    Datetime.now().addDays(3).getTime(),
                    new Map<String, Object>{ 'Id' => request.Id, 'Subject__c' => 'Must be rolled back' }
                );
            } catch (AuraHandledException e) {
                rejected = true;
            }
        }
        Test.stopTest();
        System.assert(rejected, 'Work Orders lasting over 24 hours must fail the entire operation');
        HOT_Request__c saved = [SELECT Subject__c, StartTime__c, EndTime__c FROM HOT_Request__c WHERE Id = :request.Id];
        System.assertEquals('Original subject', saved.Subject__c);
        System.assertEquals(original.StartTime__c, saved.StartTime__c);
        System.assertEquals(original.EndTime__c, saved.EndTime__c);
        WorkOrder unchanged = [SELECT StartDate, EndDate FROM WorkOrder WHERE Id = :workOrder.Id];
        System.assertEquals(workOrder.StartDate, unchanged.StartDate);
        System.assertEquals(workOrder.EndDate, unchanged.EndDate);
        System.assertEquals(1, [SELECT COUNT() FROM WorkOrder WHERE HOT_Request__c = :request.Id]);
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
        workOrder = [SELECT Id, StartDate, EndDate FROM WorkOrder WHERE Id = :workOrder.Id];
        HOT_Request__c originalRequest = [SELECT StartTime__c, EndTime__c FROM HOT_Request__c WHERE Id = :request.Id];
        User internalCaller = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        for (Integer scenario = 0; scenario < 3; scenario++) {
            if (scenario == 1) {
                update new HOT_Request__c(Id = request.Id, Account__c = otherAccount.Id);
            } else if (scenario == 2) {
                update new HOT_Request__c(Id = request.Id, Orderer__c = null);
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
                            Datetime.now().addDays(3).getTime(),
                            new Map<String, Object>{ 'Id' => request.Id, 'Subject__c' => 'Unauthorized change' }
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
