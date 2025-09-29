@IsTest(IsParallel=true)
private class HOT_DuplicateHandlerTest {
    @TestSetup
    static void testSetup() {
        Person__c person = HOT_TestDataFactory.createPerson();
        insert person;

        Account account = [SELECT Id FROM Account WHERE CRM_Person__c = :person.Id];

        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('subject', workType);
        request.Account__c = account.Id;
        insert request;
        request.Status__c = 'Godkjent';
        update request;
    }

    @IsTest
    static void getOverlappingRecordsFromRequestIdTest() {
        Account account = [SELECT Id FROM Account];
        HOT_Request__c request = [SELECT Id FROM HOT_Request__c];
        List<HOT_Request__c> result = HOT_DuplicateHandler.getOverlappingRecordsFromRequestId(account.Id, request.Id);
        System.assertEquals(true, result.isEmpty(), 'Faultly found duplicates');
    }
    @IsTest
    static void getOverlappingRecordsFromWorkOrderIdTest() {
        Account account = [SELECT Id FROM Account];
        WorkOrder workOrder = [SELECT Id FROM WorkOrder];
        List<WorkOrder> result = HOT_DuplicateHandler.getOverlappingRecordsFromWorkOrderId(account.Id, workOrder.Id);
        System.assertEquals(true, result.isEmpty(), 'Faultly found duplicates');
    }

    @IsTest
    static void checkDuplicatesTest() {
        Account account = [SELECT Id FROM Account];
        HOT_Request__c oldRequest = [SELECT Id, StartTime__c, EndTime__c FROM HOT_Request__c];
        Map<String, Map<String, Long>> times = new Map<String, Map<String, Long>>();
        Map<String, Long> timeMap = new Map<String, Long>();
        timeMap.put('startTime', DateTime.now().addHours(1).getTime());
        timeMap.put('endTime', DateTime.now().addHours(2).getTime());
        timeMap.put('isNew', 1);
        times.put('1', timeMap);
        List<HOT_Request__c> result = HOT_DuplicateHandler.checkDuplicates(account.Id, times);
        System.assertEquals(false, result.isEmpty(), 'could not find duplicates');
    }

    @IsTest
    static void startTimeEqualTest() {
        Account account = [SELECT Id FROM Account];
        HOT_Request__c oldRequest = [SELECT Id, StartTime__c, EndTime__c FROM HOT_Request__c];
        Map<String, Map<String, Datetime>> workOrderDatetimes = new Map<String, Map<String, Datetime>>();
        workOrderDatetimes.put('0', createDateTimeMap(oldRequest.StartTime__c, oldRequest.EndTime__c.addHours(3)));

        Map<Id, String> result = HOT_DuplicateHandler.getOverlappingRecords(account.Id, workOrderDatetimes, false);
        System.assertEquals(false, result.isEmpty(), 'could not find duplicates');
    }
    @IsTest
    static void endTimeEqualTest() {
        Account account = [SELECT Id FROM Account];
        HOT_Request__c oldRequest = [SELECT Id, StartTime__c, EndTime__c FROM HOT_Request__c];
        Map<String, Map<String, Datetime>> workOrderDatetimes = new Map<String, Map<String, Datetime>>();
        workOrderDatetimes.put('0', createDateTimeMap(oldRequest.StartTime__c.addHours(-3), oldRequest.EndTime__c));

        Map<Id, String> result = HOT_DuplicateHandler.getOverlappingRecords(account.Id, workOrderDatetimes, false);
        System.assertEquals(false, result.isEmpty(), 'could not find duplicates');
    }

    @IsTest
    static void startTimeInIntervalTest() {
        Account account = [SELECT Id FROM Account];
        HOT_Request__c oldRequest = [SELECT Id, StartTime__c, EndTime__c FROM HOT_Request__c];
        Map<String, Map<String, Datetime>> workOrderDatetimes = new Map<String, Map<String, Datetime>>();
        workOrderDatetimes.put(
            '0',
            createDateTimeMap(oldRequest.StartTime__c.addHours(1), oldRequest.EndTime__c.addHours(1))
        );

        Map<Id, String> result = HOT_DuplicateHandler.getOverlappingRecords(account.Id, workOrderDatetimes, false);
        System.assertEquals(false, result.isEmpty(), 'could not find duplicates');
    }
    @IsTest
    static void endTimeInIntervalTest() {
        Account account = [SELECT Id FROM Account];
        HOT_Request__c oldRequest = [SELECT Id, StartTime__c, EndTime__c FROM HOT_Request__c];
        Map<String, Map<String, Datetime>> workOrderDatetimes = new Map<String, Map<String, Datetime>>();
        workOrderDatetimes.put('0', createDateTimeMap(oldRequest.StartTime__c, oldRequest.EndTime__c.addHours(-1)));

        Map<Id, String> result = HOT_DuplicateHandler.getOverlappingRecords(account.Id, workOrderDatetimes, false);
        System.assertEquals(false, result.isEmpty(), 'could not find duplicates');
    }
    @IsTest
    static void overlappingIntevalTest() {
        Account account = [SELECT Id FROM Account];
        HOT_Request__c oldRequest = [SELECT Id, StartTime__c, EndTime__c FROM HOT_Request__c];
        Map<String, Map<String, Datetime>> workOrderDatetimes = new Map<String, Map<String, Datetime>>();
        workOrderDatetimes.put(
            '0',
            createDateTimeMap(oldRequest.StartTime__c.addHours(-1), oldRequest.EndTime__c.addHours(1))
        );

        Map<Id, String> result = HOT_DuplicateHandler.getOverlappingRecords(account.Id, workOrderDatetimes, true);
        System.assertEquals(false, result.isEmpty(), 'could not find duplicates');
    }
    @IsTest
    static void successiveTest() {
        Account account = [SELECT Id FROM Account];
        HOT_Request__c oldRequest = [SELECT Id, StartTime__c, EndTime__c FROM HOT_Request__c];
        Map<String, Map<String, Datetime>> workOrderDatetimes = new Map<String, Map<String, Datetime>>();
        workOrderDatetimes.put('0', createDateTimeMap(oldRequest.EndTime__c, oldRequest.EndTime__c.addHours(2)));

        Map<Id, String> result = HOT_DuplicateHandler.getOverlappingRecords(account.Id, workOrderDatetimes, false);
        System.assertEquals(true, result.isEmpty(), 'Faultly found duplicates');
    }

    static Map<String, Datetime> createDateTimeMap(Datetime startDate, Datetime endDate) {
        Map<String, Datetime> tempMap = new Map<String, Datetime>();
        tempMap.put('StartDate', startDate);
        tempMap.put('EndDate', endDate);
        return tempMap;
    }
}
