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

    /**
     * Converts the only open Work Order on an open request into the first occurrence of a recurring series.
     */
    @AuraEnabled
    public static void createRecurringWorkOrdersFromEdit(
        Id requestId,
        Id workOrderId,
        Long startTime,
        Long endTime,
        String recurringType,
        List<String> recurringDays,
        Long recurringEndDate,
        Map<String, Object> requestChanges
    ) {
        if (
            requestId == null ||
            workOrderId == null ||
            startTime == null ||
            endTime == null ||
            recurringEndDate == null
        ) {
            throw new AuraHandledException('Bestillingen kunne ikke gjentas. Kontroller dato og tid.');
        }

        Datetime requestedStart = Datetime.newInstance(startTime);
        Datetime requestedEnd = Datetime.newInstance(endTime);
        Date recurrenceEndDate = Datetime.newInstance(recurringEndDate).date();

        if (requestedEnd <= requestedStart) {
            throw new AuraHandledException('Slutt tid må være etter start tid.');
        }
        if (recurrenceEndDate <= requestedStart.date()) {
            throw new AuraHandledException('Sluttdato må være etter startdato.');
        }

        Set<String> selectedDays = new Set<String>();
        if (recurringDays != null) {
            selectedDays.addAll(recurringDays);
        }
        if (
            recurringType != 'Daily' &&
            recurringType != 'Weekly' &&
            recurringType != 'Biweekly' &&
            recurringType != 'Every4Weeks'
        ) {
            throw new AuraHandledException('Ugyldig gjentagelsestype.');
        }
        if (recurringType != 'Daily' && selectedDays.isEmpty()) {
            throw new AuraHandledException('Må velge minst en dag.');
        }

        Id callerAccountId = [SELECT AccountId FROM User WHERE Id = :UserInfo.getUserId()].AccountId;
        if (callerAccountId == null) {
            logRecurringEditAccessDenied(requestId);
            throw new AuraHandledException('Du har ikke tilgang til å redigere denne bestillingen.');
        }

        HOT_Request__c request;
        List<WorkOrder> workOrders;
        try {
            List<HOT_Request__c> authorizedRequests = [
                SELECT Id, Status__c
                FROM HOT_Request__c
                WHERE Id = :requestId AND Orderer__c = :callerAccountId
                FOR UPDATE
            ];
            if (authorizedRequests.isEmpty()) {
                logRecurringEditAccessDenied(requestId);
                throw new AuraHandledException('Bestillingen kunne ikke gjentas. Oppdater siden og prøv igjen.');
            }
            request = authorizedRequests[0];
            workOrders = [
                SELECT Id, StartDate, EndDate, HOT_ExternalWorkOrderStatus__c
                FROM WorkOrder
                WHERE HOT_Request__c = :requestId AND Status != 'Annul'
                FOR UPDATE
            ];
        } catch (QueryException e) {
            throw new AuraHandledException('Bestillingen kunne ikke gjentas. Oppdater siden og prøv igjen.');
        }

        if (
            request.Status__c != 'Åpen' ||
            workOrders.size() != 1 ||
            workOrders[0].Id != workOrderId ||
            workOrders[0].HOT_ExternalWorkOrderStatus__c != 'Åpen'
        ) {
            throw new AuraHandledException(
                'Bestillingen kan ikke gjentas fordi status eller tidspunkt har blitt endret. Oppdater siden og prøv igjen.'
            );
        }

        List<WorkOrder> occurrences = getRecurringWorkOrders(
            requestId,
            requestedStart,
            requestedEnd,
            recurrenceEndDate,
            recurringType,
            selectedDays
        );
        if (occurrences.isEmpty()) {
            throw new AuraHandledException('Valgte gjentagelsesdager finnes ikke i perioden.');
        }
        if (occurrences.size() > 200) {
            throw new AuraHandledException('Kan ikke opprette mer enn 200 arbeidsordre av gangen.');
        }

        List<WorkOrder> additionalWorkOrders = new List<WorkOrder>();
        for (Integer i = 0; i < occurrences.size(); i++) {
            if (i == 0) {
                workOrders[0].StartDate = occurrences[i].StartDate;
                workOrders[0].EndDate = occurrences[i].EndDate;
            } else {
                additionalWorkOrders.add(occurrences[i]);
            }
        }

        Savepoint savepoint = Database.setSavepoint();
        try {
            if (requestChanges != null) {
                HOT_Request__c editedRequest = getRecurringRequestChanges(requestId, requestChanges);
                update editedRequest;
            }
            update workOrders[0];
            if (!additionalWorkOrders.isEmpty()) {
                insert additionalWorkOrders;
            }
            HOT_Request__c savedRequest = [
                SELECT StartTime__c, EndTime__c, NumberOfWorkOrders__c
                FROM HOT_Request__c
                WHERE Id = :requestId
            ];
            if (
                savedRequest.StartTime__c != workOrders[0].StartDate ||
                savedRequest.EndTime__c != workOrders[0].EndDate ||
                savedRequest.NumberOfWorkOrders__c != occurrences.size()
            ) {
                throw new AuraHandledException('Bestillingen ble ikke oppdatert med alle tidspunktene.');
            }
        } catch (Exception e) {
            Database.rollback(savepoint);
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, request, CRM_ApplicationDomain.Domain.HOT);
            logger.publishSynch();
            throw new AuraHandledException('Opprettelsen av gjentagende arbeidsordre feilet. Prøv igjen.');
        }
    }

    /**
     * Limits request edits to form fields and enforces the caller's object and field permissions.
     */
    private static HOT_Request__c getRecurringRequestChanges(Id requestId, Map<String, Object> changes) {
        if (changes.get('Id') != null && String.valueOf(changes.get('Id')) != String.valueOf(requestId)) {
            throw new AuraHandledException('Ugyldig bestilling.');
        }
        if (!Schema.sObjectType.HOT_Request__c.isUpdateable()) {
            throw new AuraHandledException('Du har ikke tilgang til å redigere denne bestillingen.');
        }
        Set<String> editableFields = new Set<String>{
            'Subject__c',
            'MeetingStreet__c',
            'MeetingPostalCity__c',
            'MeetingPostalCode__c',
            'InterpretationStreet__c',
            'InterpretationPostalCode__c',
            'InterpretationPostalCity__c',
            'Description__c',
            'IsFileConsent__c',
            'IsOrdererWantStatusUpdateOnSMS__c',
            'IsScreenInterpreter__c',
            'UserPreferredInterpreter__c',
            'AssignmentType__c',
            'UserInterpretationMethod__c',
            'InterpretationMethodType__c',
            'OrdererEmail__c',
            'OrdererPhone__c',
            'IsNotNotifyAccount__c',
            'UserName__c',
            'UserPersonNumber__c',
            'UserPhone__c',
            'OrganizationNumber__c',
            'InvoiceReference__c',
            'IsOtherEconomicProvicer__c',
            'AdditionalInvoiceText__c'
        };
        Map<String, Schema.SObjectField> fields = Schema.sObjectType.HOT_Request__c.fields.getMap();
        HOT_Request__c updateRecord = new HOT_Request__c(Id = requestId);
        for (String fieldName : changes.keySet()) {
            if (editableFields.contains(fieldName)) {
                if (!fields.get(fieldName).getDescribe().isUpdateable()) {
                    throw new AuraHandledException('Du har ikke tilgang til å endre feltet ' + fieldName + '.');
                }
                updateRecord.put(fieldName, changes.get(fieldName));
            }
        }
        return updateRecord;
    }

    /**
     * Publishes an access denial event without reading the requested record.
     */
    private static void logRecurringEditAccessDenied(Id requestId) {
        LoggerUtility logger = new LoggerUtility('Authorization');
        logger.warning(
            'Request edit authorization failed: createRecurringWorkOrdersFromEdit',
            new HOT_Request__c(Id = requestId),
            CRM_ApplicationDomain.Domain.HOT
        );
        logger.publish();
    }

    /**
     * Preserves creation's weekday selection before DST correction, including its week-skipping rules.
     */
    private static List<Integer> getRecurringDayOffsets(
        Datetime startDate,
        Date endDate,
        String recurringType,
        Set<String> selectedDays
    ) {
        List<Integer> occurrenceOffsets = new List<Integer>();
        Integer numberOfDays = startDate.date().daysBetween(endDate);
        for (Integer offset = 0; offset <= numberOfDays; offset++) {
            String dayName = startDate.addDays(offset).format('EEEE').toLowerCase();

            if (recurringType == 'Daily' || selectedDays.contains(dayName)) {
                occurrenceOffsets.add(offset);
            }

            if (recurringType == 'Biweekly' && dayName == 'sunday') {
                offset += 7;
            } else if (recurringType == 'Every4Weeks' && dayName == 'sunday') {
                offset += 21;
            }
        }
        return occurrenceOffsets;
    }

    /**
     * Calculates intervals without DML, preserving creation's start-based DST correction for both endpoints.
     */
    private static List<WorkOrder> getRecurringWorkOrders(
        Id requestId,
        Datetime startDate,
        Datetime endDate,
        Date recurringEndDate,
        String recurringType,
        Set<String> selectedDays
    ) {
        TimeZone tz = UserInfo.getTimeZone();
        List<WorkOrder> occurrences = new List<WorkOrder>();
        for (Integer offset : getRecurringDayOffsets(startDate, recurringEndDate, recurringType, selectedDays)) {
            Datetime occurrenceStart = startDate.addDays(offset);
            Datetime occurrenceEnd = endDate.addDays(offset);
            Integer os = tz.getOffset(occurrenceStart) - tz.getOffset(startDate);
            occurrences.add(
                new WorkOrder(
                    HOT_Request__c = requestId,
                    StartDate = occurrenceStart.addHours(-os / 3600000),
                    EndDate = occurrenceEnd.addHours(-os / 3600000)
                )
            );
        }
        return occurrences;
    }

    /**
     * Converts the creation service's weekday flags to the shared generator's selection.
     */
    private static Set<String> getSelectedDays(HOT_CreateWorkOrderService input) {
        Map<String, Boolean> flags = new Map<String, Boolean>{
            'monday' => input.monday,
            'tuesday' => input.tuesday,
            'wednesday' => input.wednesday,
            'thursday' => input.thursday,
            'friday' => input.friday,
            'saturday' => input.saturday,
            'sunday' => input.sunday
        };
        Set<String> selectedDays = new Set<String>();
        for (String dayName : flags.keySet()) {
            if (flags.get(dayName) == true) {
                selectedDays.add(dayName);
            }
        }
        return selectedDays;
    }

    /**
     * Previews the form's series in the caller's timezone without reading or changing any records.
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> previewRecurringWorkOrders(
        Long startTime,
        Long endTime,
        Long recurringEndDate,
        String recurringType,
        List<String> recurringDays
    ) {
        if (startTime == null || endTime == null || recurringEndDate == null) {
            throw new AuraHandledException('Kontroller dato og tid.');
        }
        Datetime startDate = Datetime.newInstance(startTime);
        Datetime endDate = Datetime.newInstance(endTime);
        Date seriesEndDate = Datetime.newInstance(recurringEndDate).date();
        if (endDate <= startDate) {
            throw new AuraHandledException('Slutt tid må være etter start tid.');
        }
        if (seriesEndDate <= startDate.date()) {
            throw new AuraHandledException('Sluttdato må være etter startdato.');
        }
        // Matches the form's duration limit and bounds work for this publicly callable calculation.
        if (recurringEndDate - startTime > 199L * 86400000) {
            throw new AuraHandledException(
                'Du kan ikke legge inn gjentagende bestilling med en varighet på over 6 måneder'
            );
        }
        if (!new Set<String>{ 'Daily', 'Weekly', 'Biweekly', 'Every4Weeks' }.contains(recurringType)) {
            throw new AuraHandledException('Ugyldig gjentagelsestype.');
        }
        Set<String> selectedDays = new Set<String>();
        if (recurringDays != null) {
            selectedDays.addAll(recurringDays);
        }
        Set<String> validDays = new Set<String>{
            'monday',
            'tuesday',
            'wednesday',
            'thursday',
            'friday',
            'saturday',
            'sunday'
        };
        if (!validDays.containsAll(selectedDays)) {
            throw new AuraHandledException('Ugyldig gjentagelsesdag.');
        }
        if (recurringType != 'Daily' && selectedDays.isEmpty()) {
            throw new AuraHandledException('Må velge minst en dag.');
        }
        List<WorkOrder> occurrences = getRecurringWorkOrders(
            null,
            startDate,
            endDate,
            seriesEndDate,
            recurringType,
            selectedDays
        );
        String timeZoneId = UserInfo.getTimeZone().getID();
        List<Map<String, Object>> intervals = new List<Map<String, Object>>();
        for (WorkOrder occurrence : occurrences) {
            intervals.add(
                new Map<String, Object>{
                    'startTime' => occurrence.StartDate.getTime(),
                    'endTime' => occurrence.EndDate.getTime(),
                    'startLabel' => occurrence.StartDate.format('dd.MM.yyyy HH:mm', timeZoneId),
                    'endLabel' => occurrence.EndDate.format('dd.MM.yyyy HH:mm', timeZoneId)
                }
            );
        }
        return new Map<String, Object>{
            'firstDate' => occurrences.isEmpty() ? null : occurrences[0].StartDate.format('yyyy-MM-dd', timeZoneId),
            'lastDate' => occurrences.isEmpty()
                ? null
                : occurrences[occurrences.size() - 1].StartDate.format('yyyy-MM-dd', timeZoneId),
            'count' => occurrences.size(),
            'timeZone' => timeZoneId,
            'intervals' => intervals
        };
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

            workOrders = getRecurringWorkOrders(
                input.requestId,
                input.startDate,
                input.endDate,
                input.recurringEndDate,
                input.recurringType,
                new Set<String>()
            );

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

            workOrders = getRecurringWorkOrders(
                input.requestId,
                input.startDate,
                input.endDate,
                input.recurringEndDate,
                input.recurringType,
                getSelectedDays(input)
            );

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

            workOrders = getRecurringWorkOrders(
                input.requestId,
                input.startDate,
                input.endDate,
                input.recurringEndDate,
                input.recurringType,
                getSelectedDays(input)
            );

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

            workOrders = getRecurringWorkOrders(
                input.requestId,
                input.startDate,
                input.endDate,
                input.recurringEndDate,
                input.recurringType,
                getSelectedDays(input)
            );

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
