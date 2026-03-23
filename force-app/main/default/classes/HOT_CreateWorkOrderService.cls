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
    public static void createWorkOrdersFromCommunity(
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
        createWorkOrders(new List<HOT_CreateWorkOrderService>{ createWorkOrderService });
    }

    @InvocableMethod
    public static List<String> createWorkOrders(List<HOT_CreateWorkOrderService> inputVariables) {
        HOT_CreateWorkOrderService input = inputVariables[0];
        Integer maxNumberOfRecurrences = 200;
        List<String> errors = new List<String>();
        LoggerUtility logger = new LoggerUtility();
        HOT_Request__c request = new HOT_Request__c(Id = input.requestId);

        TimeZone tz = UserInfo.getTimeZone();
        Datetime oldStartDate = input.startDate;

        if (input.endDate <= input.startDate) {
            errors.add('Slutt tid må være etter start tid.');
            return errors;
        }

        if (input.recurringType != 'Never' && input.recurringEndDate <= input.startDate.date()) {
            errors.add('Sluttdato må være etter startdato.');
            return errors;
        }

        if (
            (input.recurringType == 'Weekly' ||
            input.recurringType == 'Biweekly' ||
            input.recurringType == 'Every4Weeks') &&
            !input.monday &&
            !input.tuesday &&
            !input.wednesday &&
            !input.thursday &&
            !input.friday &&
            !input.saturday &&
            !input.sunday
        ) {
            errors.add('Må velge minst en dag.');
            return errors;
        }

        Map<Date, List<WorkOrder>> existingByDate = new Map<Date, List<WorkOrder>>();
        for (WorkOrder wo : [
            SELECT Id, StartDate, EndDate, Status
            FROM WorkOrder
            WHERE HOT_Request__c = :input.requestId AND Status != 'Canceled' AND Status != 'Annul'
        ]) {
            Date d = wo.StartDate.date();
            if (!existingByDate.containsKey(d)) {
                existingByDate.put(d, new List<WorkOrder>());
            }
            existingByDate.get(d).add(wo);
        }

        List<WorkOrder> workOrdersToInsert = new List<WorkOrder>();
        List<WorkOrder> workOrdersToCancel = new List<WorkOrder>();
        Set<Id> cancelIds = new Set<Id>();
        Set<String> plannedInsertKeys = new Set<String>();

        try {
            if (input.recurringType == 'Never') {
                handleOccurrence(
                    input.requestId,
                    input.startDate,
                    input.endDate,
                    existingByDate,
                    cancelIds,
                    workOrdersToCancel,
                    plannedInsertKeys,
                    workOrdersToInsert
                );
            } else if (input.recurringType == 'Daily') {
                Integer numberOfRecurrences = input.startDate.date().daysBetween(input.recurringEndDate);

                if (numberOfRecurrences > maxNumberOfRecurrences) {
                    errors.add('Kan ikke opprette flere enn 200 arbeidsordre av gangen');
                    return errors;
                }

                for (Integer i = 0; i <= numberOfRecurrences; i++) {
                    Datetime startDate = input.startDate.addDays(i);
                    Datetime endDate = input.endDate.addDays(i);
                    Integer os = tz.getOffset(startDate) - tz.getOffset(oldStartDate);
                    startDate = startDate.addHours(-os / 3600000);
                    endDate = endDate.addHours(-os / 3600000);

                    handleOccurrence(
                        input.requestId,
                        startDate,
                        endDate,
                        existingByDate,
                        cancelIds,
                        workOrdersToCancel,
                        plannedInsertKeys,
                        workOrdersToInsert
                    );
                }
            } else if (
                input.recurringType == 'Weekly' ||
                input.recurringType == 'Biweekly' ||
                input.recurringType == 'Every4Weeks'
            ) {
                Integer numberOfRecurrences = input.startDate.date().daysBetween(input.recurringEndDate);

                Integer jumpAfterSunday = 0;
                if (input.recurringType == 'Biweekly')
                    jumpAfterSunday = 7;
                if (input.recurringType == 'Every4Weeks')
                    jumpAfterSunday = 21;

                for (Integer i = 0; i <= numberOfRecurrences; i++) {
                    Datetime startDate = input.startDate.addDays(i);
                    Datetime endDate = input.endDate.addDays(i);
                    String dayOfWeek = startDate.format('EEEE');
                    Integer os = tz.getOffset(startDate) - tz.getOffset(oldStartDate);
                    startDate = startDate.addHours(-os / 3600000);
                    endDate = endDate.addHours(-os / 3600000);

                    if (
                        input.monday && dayOfWeek == 'Monday' ||
                        input.tuesday && dayOfWeek == 'Tuesday' ||
                        input.wednesday && dayOfWeek == 'Wednesday' ||
                        input.thursday && dayOfWeek == 'Thursday' ||
                        input.friday && dayOfWeek == 'Friday' ||
                        input.saturday && dayOfWeek == 'Saturday' ||
                        input.sunday && dayOfWeek == 'Sunday'
                    ) {
                        handleOccurrence(
                            input.requestId,
                            startDate,
                            endDate,
                            existingByDate,
                            cancelIds,
                            workOrdersToCancel,
                            plannedInsertKeys,
                            workOrdersToInsert
                        );
                    }

                    if (jumpAfterSunday > 0 && dayOfWeek == 'Sunday') {
                        i = i + jumpAfterSunday;
                    }
                }

                if (workOrdersToInsert.size() > maxNumberOfRecurrences) {
                    errors.add('Kan ikke opprette mer enn 200 arbeidsordre av gangen');
                    return errors;
                }
            } else if (input.recurringType == 'Monthly') {
                Integer numberOfRecurrences = input.startDate.date().monthsBetween(input.recurringEndDate);

                if (numberOfRecurrences > maxNumberOfRecurrences) {
                    errors.add('Kan ikke opprette mer enn 200 arbeidsordre av gangen');
                    return errors;
                }

                for (Integer i = 0; i <= numberOfRecurrences; i++) {
                    Datetime startDate = input.startDate.addMonths(i);
                    Datetime endDate = input.endDate.addMonths(i);
                    Integer os = tz.getOffset(startDate) - tz.getOffset(oldStartDate);
                    startDate = startDate.addHours(-os / 3600000);
                    endDate = endDate.addHours(-os / 3600000);

                    if (startDate.date() <= input.recurringEndDate) {
                        handleOccurrence(
                            input.requestId,
                            startDate,
                            endDate,
                            existingByDate,
                            cancelIds,
                            workOrdersToCancel,
                            plannedInsertKeys,
                            workOrdersToInsert
                        );
                    }
                }
            }

            if (!workOrdersToCancel.isEmpty()) {
                update workOrdersToCancel;
            }
            if (!workOrdersToInsert.isEmpty()) {
                insert workOrdersToInsert;
            }
        } catch (Exception e) {
            errors.add('Opprettelsen av arbeidsordrene feilet.');
            logger.exception(e, request, CRM_ApplicationDomain.Domain.HOT);
            logger.publishSynch();
        }

        return errors;
    }

    private static void handleOccurrence(
        String requestId,
        Datetime startDate,
        Datetime endDate,
        Map<Date, List<WorkOrder>> existingByDate,
        Set<Id> cancelIds,
        List<WorkOrder> workOrdersToCancel,
        Set<String> plannedInsertKeys,
        List<WorkOrder> workOrdersToInsert
    ) {
        Date d = startDate.date();
        String key = startDate.format('yyyy-MM-dd HH:mm') + '|' + endDate.format('yyyy-MM-dd HH:mm');

        if (plannedInsertKeys.contains(key)) {
            return;
        }

        List<WorkOrder> existing = existingByDate.get(d);
        if (existing != null && !existing.isEmpty()) {
            Boolean hasExact = false;
            for (WorkOrder ex : existing) {
                String exKey = ex.StartDate.format('yyyy-MM-dd HH:mm') + '|' + ex.EndDate.format('yyyy-MM-dd HH:mm');
                if (exKey == key) {
                    hasExact = true;
                    break;
                }
            }

            if (hasExact) {
                return;
            }

            for (WorkOrder ex : existing) {
                if (!cancelIds.contains(ex.Id)) {
                    cancelIds.add(ex.Id);
                    ex.Status = 'Canceled';
                    workOrdersToCancel.add(ex);
                }
            }
        }

        plannedInsertKeys.add(key);
        workOrdersToInsert.add(new WorkOrder(HOT_Request__c = requestId, StartDate = startDate, EndDate = endDate));
    }
}
