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

        if (input.recurringType == 'Never') {
            WorkOrder workOrder = new workOrder(
                HOT_Request__c = input.requestId,
                StartDate = input.startDate,
                EndDate = input.endDate
            );

            try {
                insert workOrder;
            } catch (Exception e) {
                errors.add('Opprettelsen av arbeidsordren feilet.');
                logger.exception(e, request, CRM_ApplicationDomain.Domain.HOT);
                logger.publishSynch();
            }

            return errors;
        } else if (input.recurringType == 'Daily') {
            List<WorkOrder> workOrders = new List<WorkOrder>();
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
                WorkOrder workOrder = new workOrder(
                    HOT_Request__c = input.requestId,
                    StartDate = startDate,
                    EndDate = endDate
                );
                workOrders.add(workOrder);
            }

            try {
                insert workOrders;
            } catch (Exception e) {
                errors.add('Opprettelsen av arbeidsordrene feilet.');
                logger.exception(e, request, CRM_ApplicationDomain.Domain.HOT);
                logger.publishSynch();
            }

            return errors;
        } else if (input.recurringType == 'Weekly') {
            List<WorkOrder> workOrders = new List<WorkOrder>();
            Integer numberOfRecurrences = input.startDate.date().daysBetween(input.recurringEndDate);

            for (Integer i = 0; i <= numberOfRecurrences; i++) {
                Datetime startDate = input.startDate.addDays(i);
                Datetime endDate = input.endDate.addDays(i);
                String dayOfWeek = startDate.format('EEEE');
                Integer os = tz.getOffset(startDate) - tz.getOffset(oldStartDate);
                startDate = startDate.addHours(-os / 3600000);
                endDate = endDate.addHours(-os / 3600000);

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
                    workOrders.add(workOrder);
                }
            }

            if (workOrders.size() > maxNumberOfRecurrences) {
                errors.add('Kan ikke opprette mer enn 200 arbeidsordre av gangen');
                return errors;
            }

            try {
                insert workOrders;
            } catch (Exception e) {
                errors.add('Opprettelsen av arbeidsordrene feilet.');
                logger.exception(e, request, CRM_ApplicationDomain.Domain.HOT);
                logger.publishSynch();
            }

            return errors;
        } else if (input.recurringType == 'Biweekly') {
            List<WorkOrder> workOrders = new List<WorkOrder>();
            Integer numberOfRecurrences = input.startDate.date().daysBetween(input.recurringEndDate);

            for (Integer i = 0; i <= numberOfRecurrences; i++) {
                Datetime startDate = input.startDate.addDays(i);
                Datetime endDate = input.endDate.addDays(i);
                String dayOfWeek = startDate.format('EEEE');
                Integer os = tz.getOffset(startDate) - tz.getOffset(oldStartDate);
                startDate = startDate.addHours(-os / 3600000);
                endDate = endDate.addHours(-os / 3600000);
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
                    workOrders.add(workOrder);
                }
                if (dayOfWeek == 'Sunday') {
                    i = i + 7;
                }
            }

            if (workOrders.size() > maxNumberOfRecurrences) {
                errors.add('Kan ikke opprette mer enn 200 arbeidsordre av gangen');
                return errors;
            }

            try {
                insert workOrders;
            } catch (Exception e) {
                errors.add('Opprettelsen av arbeidsordrene feilet.');
                logger.exception(e, request, CRM_ApplicationDomain.Domain.HOT);
                logger.publishSynch();
            }

            return errors;
        } else if (input.recurringType == 'Every4Weeks') {
            List<WorkOrder> workOrders = new List<WorkOrder>();
            Integer numberOfRecurrences = input.startDate.date().daysBetween(input.recurringEndDate);

            for (Integer i = 0; i <= numberOfRecurrences; i++) {
                Datetime startDate = input.startDate.addDays(i);
                Datetime endDate = input.endDate.addDays(i);
                String dayOfWeek = startDate.format('EEEE');
                Integer os = tz.getOffset(startDate) - tz.getOffset(oldStartDate);
                startDate = startDate.addHours(-os / 3600000);
                endDate = endDate.addHours(-os / 3600000);
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
                    workOrders.add(workOrder);
                }
                if (dayOfWeek == 'Sunday') {
                    i = i + 21;
                }
            }

            if (workOrders.size() > maxNumberOfRecurrences) {
                errors.add('Kan ikke opprette mer enn 200 arbeidsordre av gangen');
                return errors;
            }

            try {
                insert workOrders;
            } catch (Exception e) {
                errors.add('Opprettelsen av arbeidsordrene feilet.');
                logger.exception(e, request, CRM_ApplicationDomain.Domain.HOT);
                logger.publishSynch();
            }

            return errors;
        } else if (input.recurringType == 'Monthly') {
            List<WorkOrder> workOrders = new List<WorkOrder>();
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
                WorkOrder workOrder = new workOrder(
                    HOT_Request__c = input.requestId,
                    StartDate = startDate,
                    EndDate = endDate
                );
                if (startDate.date() <= input.recurringEndDate) {
                    workOrders.add(workOrder);
                }
            }

            try {
                insert workOrders;
            } catch (Exception e) {
                errors.add('Opprettelsen av arbeidsordrene feilet.');
                logger.exception(e, request, CRM_ApplicationDomain.Domain.HOT);
                logger.publishSynch();
            }

            return errors;
        }

        return errors;
    }
}
