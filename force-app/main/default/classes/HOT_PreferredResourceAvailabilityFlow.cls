/**
 * Calculates preferred resource warnings for auto scheduling in one invocable call.
 */
public without sharing class HOT_PreferredResourceAvailabilityFlow {
    private static final String NORWAY_TIMEZONE = 'Europe/Oslo';
    private static final String DATE_PATTERN = 'dd.MM.yyyy HH:mm';

    /**
     * Flow input payload.
     */
    public class Request {
        @InvocableVariable(required=true)
        public String parentRecordId;
    }

    /**
     * Flow output payload.
     */
    public class Response {
        @InvocableVariable
        public String warningDisplayText;

        @InvocableVariable
        public Boolean isFreelanceInterpreterAvailable;

        @InvocableVariable
        public Boolean isPreferredResource1Unavailable;

        @InvocableVariable
        public Boolean isPreferredResource2Unavailable;
    }

    /**
     * Evaluates availability for each input record.
     */
    @InvocableMethod(label='Check Preferred Resource Availability')
    public static List<Response> checkAvailability(List<Request> requests) {
        List<Response> responses = new List<Response>();
        for (Request requestItem : requests) {
            responses.add(processRecord(requestItem == null ? null : requestItem.parentRecordId));
        }
        return responses;
    }

    private static Response processRecord(String parentRecordId) {
        Response responseItem = new Response();
        if (String.isBlank(parentRecordId)) {
            return responseItem;
        }

        PreferredResourceContext preferredContext = getPreferredResourceContext(parentRecordId);
        List<WorkOrder> workOrders = getWorkOrders(parentRecordId);
        WorkOrderRange rangeItem = getWorkOrderRange(workOrders);

        if (rangeItem == null) {
            return responseItem;
        }

        Map<Id, HOT_Resource__c> preferredResourcesById = getPreferredResourcesById(preferredContext);
        List<ServiceAppointment> resource1Appointments = getOverlappingAppointments(
            preferredResourcesById.get(preferredContext.preferredResource1Id),
            rangeItem
        );
        List<ServiceAppointment> resource2Appointments = getOverlappingAppointments(
            preferredResourcesById.get(preferredContext.preferredResource2Id),
            rangeItem
        );

        applyAvailabilityEvaluation(
            responseItem,
            preferredContext,
            preferredResourcesById,
            workOrders,
            resource1Appointments,
            resource2Appointments
        );
        return responseItem;
    }

    private static List<WorkOrder> getWorkOrders(String parentRecordId) {
        return [
            SELECT Id, StartDate, EndDate
            FROM WorkOrder
            WHERE Id = :parentRecordId OR HOT_Request__c = :parentRecordId
            ORDER BY StartDate ASC
        ];
    }

    private static WorkOrderRange getWorkOrderRange(List<WorkOrder> workOrders) {
        if (workOrders.isEmpty()) {
            return null;
        }

        Datetime earliestStart = null;
        Datetime latestEnd = null;
        for (WorkOrder workOrderItem : workOrders) {
            if (workOrderItem.StartDate != null && (earliestStart == null || workOrderItem.StartDate < earliestStart)) {
                earliestStart = workOrderItem.StartDate;
            }
            if (workOrderItem.EndDate != null && (latestEnd == null || workOrderItem.EndDate > latestEnd)) {
                latestEnd = workOrderItem.EndDate;
            }
        }

        if (earliestStart == null || latestEnd == null) {
            return null;
        }

        WorkOrderRange rangeItem = new WorkOrderRange();
        rangeItem.earliestStart = earliestStart;
        rangeItem.latestEnd = latestEnd;
        return rangeItem;
    }

    private static Map<Id, HOT_Resource__c> getPreferredResourcesById(PreferredResourceContext preferredContext) {
        Set<Id> preferredResourceIds = new Set<Id>();
        if (preferredContext.preferredResource1Id != null) {
            preferredResourceIds.add(preferredContext.preferredResource1Id);
        }
        if (preferredContext.preferredResource2Id != null) {
            preferredResourceIds.add(preferredContext.preferredResource2Id);
        }

        if (preferredResourceIds.isEmpty()) {
            return new Map<Id, HOT_Resource__c>();
        }

        return new Map<Id, HOT_Resource__c>(
            [
                SELECT Id, Name, Service_Resource__c
                FROM HOT_Resource__c
                WHERE Id IN :preferredResourceIds
            ]
        );
    }

    private static List<ServiceAppointment> getOverlappingAppointments(
        HOT_Resource__c preferredResource,
        WorkOrderRange rangeItem
    ) {
        if (preferredResource == null) {
            return new List<ServiceAppointment>();
        }

        return [
            SELECT Id, EarliestStartTime, DueDate
            FROM ServiceAppointment
            WHERE
                HOT_ServiceResource__c = :preferredResource.Service_Resource__c
                AND Status != 'Annul'
                AND Status != 'Canceled'
                AND Status != 'Completed'
                AND EarliestStartTime < :rangeItem.latestEnd
                AND DueDate > :rangeItem.earliestStart
        ];
    }

    private static void applyAvailabilityEvaluation(
        Response responseItem,
        PreferredResourceContext preferredContext,
        Map<Id, HOT_Resource__c> preferredResourcesById,
        List<WorkOrder> workOrders,
        List<ServiceAppointment> resource1Appointments,
        List<ServiceAppointment> resource2Appointments
    ) {
        List<String> warningMessages = new List<String>();
        for (WorkOrder workOrderItem : workOrders) {
            evaluateResource(
                responseItem,
                warningMessages,
                1,
                preferredContext.preferredResource1Id,
                preferredResourcesById,
                workOrderItem,
                resource1Appointments
            );
            evaluateResource(
                responseItem,
                warningMessages,
                2,
                preferredContext.preferredResource2Id,
                preferredResourcesById,
                workOrderItem,
                resource2Appointments
            );
        }

        if (!warningMessages.isEmpty()) {
            responseItem.warningDisplayText = String.join(warningMessages, '<br/>') + '<br/>';
        }
    }

    private static void evaluateResource(
        Response responseItem,
        List<String> warningMessages,
        Integer preferredResourceNumber,
        Id preferredResourceId,
        Map<Id, HOT_Resource__c> preferredResourcesById,
        WorkOrder workOrderItem,
        List<ServiceAppointment> appointments
    ) {
        if (preferredResourceId == null) {
            return;
        }

        HOT_Resource__c preferredResource = preferredResourcesById.get(preferredResourceId);
        for (ServiceAppointment appointmentItem : appointments) {
            if (isOverlapping(workOrderItem, appointmentItem)) {
                warningMessages.add(buildWarningText(preferredResourceNumber, preferredResource, workOrderItem));
                if (preferredResourceNumber == 1) {
                    responseItem.isPreferredResource1Unavailable = true;
                } else {
                    responseItem.isPreferredResource2Unavailable = true;
                }
            } else {
                responseItem.isFreelanceInterpreterAvailable = true;
            }
        }
    }

    private static Boolean isOverlapping(WorkOrder workOrderItem, ServiceAppointment serviceAppointmentItem) {
        return workOrderItem.StartDate < serviceAppointmentItem.DueDate &&
            workOrderItem.EndDate > serviceAppointmentItem.EarliestStartTime;
    }

    private static String buildWarningText(
        Integer preferredResourceNumber,
        HOT_Resource__c preferredResource,
        WorkOrder workOrderItem
    ) {
        String resourceName = preferredResource == null ? '' : preferredResource.Name;
        String workOrderRange = formatNorwayRange(workOrderItem.StartDate, workOrderItem.EndDate);
        return 'Foretrukket ressurs ' +
            String.valueOf(preferredResourceNumber) +
            ' (' +
            resourceName +
            ') er opptatt i tidsrommet oppdraget er satt til: ' +
            workOrderRange +
            '.';
    }

    private static String formatNorwayRange(Datetime startDate, Datetime endDate) {
        if (startDate == null && endDate == null) {
            return '';
        }
        if (startDate != null && endDate != null) {
            return startDate.format(DATE_PATTERN, NORWAY_TIMEZONE) +
                ' - ' +
                endDate.format(DATE_PATTERN, NORWAY_TIMEZONE);
        }
        if (startDate != null) {
            return startDate.format(DATE_PATTERN, NORWAY_TIMEZONE);
        }
        return endDate.format(DATE_PATTERN, NORWAY_TIMEZONE);
    }

    private class PreferredResourceContext {
        public Id preferredResource1Id;
        public Id preferredResource2Id;
    }

    private class WorkOrderRange {
        public Datetime earliestStart;
        public Datetime latestEnd;
    }

    private static PreferredResourceContext getPreferredResourceContext(String parentRecordId) {
        PreferredResourceContext contextItem = new PreferredResourceContext();

        if (parentRecordId.startsWith('0WO')) {
            List<WorkOrder> workOrderRecords = [
                SELECT HOT_Request__r.PreferredResource1__c, HOT_Request__r.PreferredResource2__c
                FROM WorkOrder
                WHERE Id = :parentRecordId
                LIMIT 1
            ];
            if (!workOrderRecords.isEmpty() && workOrderRecords[0].HOT_Request__r != null) {
                contextItem.preferredResource1Id = workOrderRecords[0].HOT_Request__r.PreferredResource1__c;
                contextItem.preferredResource2Id = workOrderRecords[0].HOT_Request__r.PreferredResource2__c;
            }
            return contextItem;
        }

        List<HOT_Request__c> requestRecords = [
            SELECT PreferredResource1__c, PreferredResource2__c
            FROM HOT_Request__c
            WHERE Id = :parentRecordId
            LIMIT 1
        ];
        if (!requestRecords.isEmpty()) {
            contextItem.preferredResource1Id = requestRecords[0].PreferredResource1__c;
            contextItem.preferredResource2Id = requestRecords[0].PreferredResource2__c;
        }
        return contextItem;
    }
}
