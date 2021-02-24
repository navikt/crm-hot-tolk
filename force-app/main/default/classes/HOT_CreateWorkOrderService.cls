public without sharing class HOT_CreateWorkOrderService {
    @InvocableVariable
    public String requestId;
    @InvocableVariable
    public Datetime startDate;
    @InvocableVariable
    public Datetime endDate;
    @InvocableVariable
    public String recurringType;
    @InvocableVariable
    public Boolean monday;
    @InvocableVariable
    public Boolean tuesday;
    @InvocableVariable
    public Boolean wednesday;
    @InvocableVariable
    public Boolean thursday;
    @InvocableVariable
    public Boolean friday;
    @InvocableVariable
    public Boolean saturday;
    @InvocableVariable
    public Boolean sunday;
    @InvocableVariable
    public Date recurringEndDate;

    @AuraEnabled
    public static List<String> checkInputsFromCommunity(
        String requestId,
        Map<String, Long> times,
        String recurringType,
        List<String> recurringDays,
        Long recurringEndDate
    ) {
        HOT_CreateWorkOrderService createWorkOrderService = new HOT_CreateWorkOrderService();
        createWorkOrderService.requestId = requestId;
        createWorkOrderService.startDate = DateTime.newInstance(times.get('startTime'));
        createWorkOrderService.endDate = DateTime.newInstance(times.get('endTime'));
        createWorkOrderService.recurringType = recurringType;
        createWorkOrderService.monday = recurringDays.contains('monday');
        createWorkOrderService.tuesday = recurringDays.contains('tuesday');
        createWorkOrderService.wednesday = recurringDays.contains('wednesday');
        createWorkOrderService.thursday = recurringDays.contains('thursday');
        createWorkOrderService.friday = recurringDays.contains('friday');
        createWorkOrderService.saturday = recurringDays.contains('saturday');
        createWorkOrderService.sunday = recurringDays.contains('sunday');
        createWorkOrderService.recurringEndDate = DateTime.newInstance(recurringEndDate).date();
        Map<String, List<WorkOrder>> workOrderErrorMap = getWorkOrders(
            new List<HOT_CreateWorkOrderService>{ createWorkOrderService }
        );
        workOrderErrorMap.remove('records');
        return new List<String>(workOrderErrorMap.keySet());
    }
    @AuraEnabled
    public static List<String> createWorkOrdersFromCommunity(
        String requestId,
        Map<String, Long> times,
        String recurringType,
        List<String> recurringDays,
        Long recurringEndDate
    ) {
        HOT_CreateWorkOrderService createWorkOrderService = new HOT_CreateWorkOrderService();
        createWorkOrderService.requestId = requestId;
        createWorkOrderService.startDate = DateTime.newInstance(times.get('startTime'));
        createWorkOrderService.endDate = DateTime.newInstance(times.get('endTime'));
        createWorkOrderService.recurringType = recurringType;
        createWorkOrderService.monday = recurringDays.contains('monday');
        createWorkOrderService.tuesday = recurringDays.contains('tuesday');
        createWorkOrderService.wednesday = recurringDays.contains('wednesday');
        createWorkOrderService.thursday = recurringDays.contains('thursday');
        createWorkOrderService.friday = recurringDays.contains('friday');
        createWorkOrderService.saturday = recurringDays.contains('saturday');
        createWorkOrderService.sunday = recurringDays.contains('sunday');
        createWorkOrderService.recurringEndDate = DateTime.newInstance(recurringEndDate).date();
        List<String> errors = createWorkOrders(new List<HOT_CreateWorkOrderService>{ createWorkOrderService });
        return errors;
    }

    @InvocableMethod
    public static List<String> createWorkOrders(List<HOT_CreateWorkOrderService> inputVariables) {
        Map<String, List<WorkOrder>> workOrderErrorMap = getWorkOrders(inputVariables);
        System.debug('---------------------------------');
        System.debug(workOrderErrorMap);
        System.debug(workOrderErrorMap.size());
        if (workOrderErrorMap.keySet().size() == 1) {
            try {
                System.debug('Inserting records');
                System.debug(workOrderErrorMap.get('records'));
                insert workOrderErrorMap.get('records');
            } catch (Exception e) {
                return new List<String>{ 'Opprettelsen av arbeidsordrene feilet.' };
            }
        }
        workOrderErrorMap.remove('records');
        return new List<String>(workOrderErrorMap.keySet());
    }

    public static Map<String, List<WorkOrder>> getWorkOrders(List<HOT_CreateWorkOrderService> inputVariables) {
        Map<String, List<WorkOrder>> returnMap = new Map<String, List<WorkOrder>>();
        returnMap.put('records', new List<WorkOrder>());

        HOT_CreateWorkOrderService input = inputVariables[0];
        Integer maxNumberOfRecurrences = 200;

        TimeZone tz = UserInfo.getTimeZone();

        if (input.endDate <= input.startDate) {
            returnMap.put('Slutt tid må være etter start tid.', null);
            return returnMap;
        }

        if (input.recurringType != 'Never' && input.recurringEndDate <= input.startDate.date()) {
            returnMap.put('Sluttdato må være etter startdato.', null);
            return returnMap;
        }

        if (
            (input.recurringType == 'Weekly' ||
            input.recurringType == 'Biweekly') &&
            !input.monday &&
            !input.tuesday &&
            !input.wednesday &&
            !input.thursday &&
            !input.friday &&
            !input.saturday &&
            !input.sunday
        ) {
            returnMap.put('Må velge minst en dag.', null);
            return returnMap;
        }

        if (input.recurringType == 'Never') {
            WorkOrder workOrder = new workOrder(
                HOT_Request__c = input.requestId,
                StartDate = input.startDate,
                EndDate = input.endDate
            );
            returnMap.get('records').add(workOrder);

            return returnMap;
        } else if (input.recurringType == 'Daily') {
            Integer numberOfRecurrences = input.startDate.date().daysBetween(input.recurringEndDate);

            if (numberOfRecurrences > maxNumberOfRecurrences) {
                returnMap.put('Kan ikke opprette mere en 200 arbeidsordre av gangen', null);
                return returnMap;
            }

            for (Integer i = 0; i <= numberOfRecurrences; i++) {
                Datetime startDate = input.startDate.addDays(i);
                Datetime endDate = input.endDate.addDays(i);
                Integer os = tz.getOffset(startDate);
                startDate = startDate.addHours(1 - os / 3600000);
                endDate = endDate.addHours(1 - os / 3600000);
                WorkOrder workOrder = new workOrder(
                    HOT_Request__c = input.requestId,
                    StartDate = startDate,
                    EndDate = endDate
                );
                returnMap.get('records').add(workOrder);
            }

            return returnMap;
        } else if (input.recurringType == 'Weekly') {
            Integer numberOfRecurrences = input.startDate.date().daysBetween(input.recurringEndDate);

            for (Integer i = 0; i <= numberOfRecurrences; i++) {
                Datetime startDate = input.startDate.addDays(i);
                Datetime endDate = input.endDate.addDays(i);
                String dayOfWeek = startDate.format('EEEE');
                Integer os = tz.getOffset(startDate);
                startDate = startDate.addHours(1 - os / 3600000);
                endDate = endDate.addHours(1 - os / 3600000);

                System.debug('dayOfWeek: ' + dayOfWeek);
                if (
                    input.monday && dayOfWeek == 'Monday' ||
                    input.tuesday && dayOfWeek == 'Tuesday' ||
                    input.wednesday && dayOfWeek == 'Wednesday' ||
                    input.thursday && dayOfWeek == 'Thursday' ||
                    input.friday && dayOfWeek == 'Friday' ||
                    input.saturday && dayOfWeek == 'Saturday' ||
                    input.sunday && dayOfWeek == 'Sunday'
                ) {
                    WorkOrder workOrder = new workOrder(
                        HOT_Request__c = input.requestId,
                        StartDate = startDate,
                        EndDate = endDate
                    );
                    returnMap.get('records').add(workOrder);
                }
            }

            if (returnMap.get('records').size() > maxNumberOfRecurrences) {
                returnMap.put('Kan ikke opprette mere en 200 arbeidsordre av gangen', null);
                return returnMap;
            }

            return returnMap;
        } else if (input.recurringType == 'Biweekly') {
            Integer numberOfRecurrences = input.startDate.date().daysBetween(input.recurringEndDate);

            for (Integer i = 0; i <= numberOfRecurrences; i++) {
                Datetime startDate = input.startDate.addDays(i);
                Datetime endDate = input.endDate.addDays(i);
                String dayOfWeek = startDate.format('EEEE');
                Integer os = tz.getOffset(startDate);
                startDate = startDate.addHours(1 - os / 3600000);
                endDate = endDate.addHours(1 - os / 3600000);
                System.debug('dayOfWeek: ' + dayOfWeek);
                if (
                    input.monday && dayOfWeek == 'Monday' ||
                    input.tuesday && dayOfWeek == 'Tuesday' ||
                    input.wednesday && dayOfWeek == 'Wednesday' ||
                    input.thursday && dayOfWeek == 'Thursday' ||
                    input.friday && dayOfWeek == 'Friday' ||
                    input.saturday && dayOfWeek == 'Saturday' ||
                    input.sunday && dayOfWeek == 'Sunday'
                ) {
                    WorkOrder workOrder = new workOrder(
                        HOT_Request__c = input.requestId,
                        StartDate = startDate,
                        EndDate = endDate
                    );
                    returnMap.get('records').add(workOrder);
                }
                if (dayOfWeek == 'Sunday') {
                    i = i + 7;
                }
            }

            if (returnMap.get('records').size() > maxNumberOfRecurrences) {
                returnMap.put('Kan ikke opprette mere en 200 arbeidsordre av gangen', null);
                return returnMap;
            }

            return returnMap;
        } else if (input.recurringType == 'Monthly') {
            Integer numberOfRecurrences = input.startDate.date().monthsBetween(input.recurringEndDate);

            if (numberOfRecurrences > maxNumberOfRecurrences) {
                returnMap.put('Kan ikke opprette mere en 200 arbeidsordre av gangen', null);
                return returnMap;
            }

            for (Integer i = 0; i <= numberOfRecurrences; i++) {
                Datetime startDate = input.startDate.addMonths(i);
                Datetime endDate = input.endDate.addMonths(i);
                Integer os = tz.getOffset(startDate);
                startDate = startDate.addHours(1 - os / 3600000);
                endDate = endDate.addHours(1 - os / 3600000);
                WorkOrder workOrder = new workOrder(
                    HOT_Request__c = input.requestId,
                    StartDate = startDate,
                    EndDate = endDate
                );
                if (startDate.date() <= input.recurringEndDate) {
                    returnMap.get('records').add(workOrder);
                }
            }
            return returnMap;
        }

        return returnMap;
    }
}
