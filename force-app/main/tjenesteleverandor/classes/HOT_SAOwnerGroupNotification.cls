public without sharing class HOT_SAOwnerGroupNotification {
    public static final String STATUS_FAILED = 'Failed';
    public static final String STATUS_MISSING_RECIPIENT = 'MissingRecipient';
    public static final String STATUS_QUEUED = 'Queued';
    public static final String STATUS_SENT = 'Sent';
    public static final String STATUS_SKIPPED = 'Skipped';

    public class Request {
        @InvocableVariable(required=true label='Service Appointment Id')
        public Id serviceAppointmentId;

        @InvocableVariable(required=true label='Title')
        public String title;

        @InvocableVariable(required=true label='Body')
        public String body;
    }

    public class Result {
        @InvocableVariable(label='Service Appointment Id')
        public Id serviceAppointmentId;

        @InvocableVariable(label='Status')
        public String status;

        @InvocableVariable(label='Queued')
        public Boolean queued;

        @InvocableVariable(label='Sent')
        public Boolean sent;

        @InvocableVariable(label='Skipped')
        public Boolean skipped;

        @InvocableVariable(label='Missing Recipient')
        public Boolean missingRecipient;

        @InvocableVariable(label='Message')
        public String message;
    }

    public class WorkItem {
        public Id serviceAppointmentId;
        public String title;
        public String body;
    }

    @InvocableMethod(
        label='Notify Service Appointment Owner Group'
        description='Queues custom notifications to the formidler group derived from the ServiceAppointment owner.'
        category='HOT Tolketjeneste'
        iconName='slds:standard:service_appointment'
    )
    public static List<Result> send(List<Request> requests) {
        List<Result> results = new List<Result>();
        if (requests == null || requests.isEmpty()) {
            return results;
        }

        List<WorkItem> workItems = collectWorkItems(requests, results);
        if (workItems.isEmpty()) {
            return results;
        }

        try {
            System.enqueueJob(new HOT_SAOwnerGroupNotificationQueueable(workItems));
        } catch (Exception exceptionThrown) {
            logException(exceptionThrown);
            for (Result result : results) {
                if (result.status == STATUS_QUEUED) {
                    setStatus(result, STATUS_FAILED, 'Could not queue notification job.');
                }
            }
        }

        return results;
    }

    private static List<WorkItem> collectWorkItems(List<Request> requests, List<Result> results) {
        List<WorkItem> workItems = new List<WorkItem>();
        Set<Id> collectedServiceAppointmentIds = new Set<Id>();

        for (Request request : requests) {
            if (
                request?.serviceAppointmentId == null ||
                String.isBlank(request.title) ||
                String.isBlank(request.body)
            ) {
                results.add(
                    createResult(request?.serviceAppointmentId, STATUS_SKIPPED, 'Invalid notification request.')
                );
                continue;
            }
            if (collectedServiceAppointmentIds.contains(request.serviceAppointmentId)) {
                results.add(
                    createResult(request.serviceAppointmentId, STATUS_SKIPPED, 'Duplicate notification request.')
                );
                continue;
            }
            collectedServiceAppointmentIds.add(request.serviceAppointmentId);

            WorkItem workItem = new WorkItem();
            workItem.serviceAppointmentId = request.serviceAppointmentId;
            workItem.title = request.title;
            workItem.body = request.body;
            workItems.add(workItem);
            results.add(createResult(request.serviceAppointmentId, STATUS_QUEUED, 'Notification job queued.'));
        }

        return workItems;
    }

    public static Result createResult(Id serviceAppointmentId, String status, String message) {
        Result result = new Result();
        result.serviceAppointmentId = serviceAppointmentId;
        setStatus(result, status, message);
        return result;
    }

    private static void setStatus(Result result, String status, String message) {
        result.status = status;
        result.message = message;
        result.queued = status == STATUS_QUEUED;
        result.sent = status == STATUS_SENT;
        result.skipped = status == STATUS_SKIPPED;
        result.missingRecipient = status == STATUS_MISSING_RECIPIENT;
    }

    private static void logException(Exception exceptionThrown) {
        LoggerUtility logger = new LoggerUtility();
        logger.exception(exceptionThrown, CRM_ApplicationDomain.Domain.HOT);
        logger.publishSynch();
    }
}
