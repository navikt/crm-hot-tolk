public without sharing class HOT_ServiceProviderTransferSADispatcher {
    private static final Set<String> TRANSFERABLE_STATUSES = new Set<String>{
        'None',
        'Released to Freelance',
        'Scheduled',
        'Dispatched',
        'In Progress'
    };

    public class Request {
        @InvocableVariable(required=true label='Service Appointment IDs')
        public List<Id> recordIds;

        @InvocableVariable(required=true label='New Dispatcher User ID')
        public Id dispatcherId;
    }

    public class TransferException extends Exception {
        // Marks expected validation errors while transferring service appointments.
    }

    @InvocableMethod(label='Transfer Service Appointment Dispatcher')
    public static void transfer(List<Request> requests) {
        if (requests == null || requests.isEmpty()) {
            throw new TransferException('Velg oppdrag som skal overføres.');
        }
        if (
            !Schema.sObjectType.ServiceAppointment.isUpdateable() ||
            !Schema.sObjectType.ServiceAppointment.fields.HOT_TLDispatcher__c.isUpdateable()
        ) {
            throw new TransferException('Du har ikke tilgang til å endre formidler på oppdragene.');
        }

        Map<Id, Id> dispatcherByAppointment = new Map<Id, Id>();
        Set<Id> dispatcherIds = new Set<Id>();
        for (Request request : requests) {
            if (
                request == null ||
                request.recordIds == null ||
                request.recordIds.isEmpty() ||
                request.dispatcherId == null ||
                request.dispatcherId.getSObjectType() != User.SObjectType
            ) {
                throw new TransferException('Oppdrag eller formidler mangler eller er ugyldig.');
            }
            dispatcherIds.add(request.dispatcherId);
            for (Id appointmentId : request.recordIds) {
                if (
                    appointmentId == null ||
                    appointmentId.getSObjectType() != ServiceAppointment.SObjectType ||
                    dispatcherByAppointment.containsKey(appointmentId)
                ) {
                    throw new TransferException('Et oppdrag er ugyldig eller valgt flere ganger.');
                }
                dispatcherByAppointment.put(appointmentId, request.dispatcherId);
            }
        }

        Set<Id> validDispatchers = new Set<Id>();
        for (ServiceResource resource : [
            SELECT RelatedRecordId
            FROM ServiceResource
            WHERE
                RelatedRecordId IN :dispatcherIds
                AND IsActive = TRUE
                AND HOT_IsTjenesteleverandorDispatcher__c = TRUE
                AND CRM_Domain__c = 'HOT'
        ]) {
            validDispatchers.add(resource.RelatedRecordId);
        }
        Set<Id> activeUsers = new Map<Id, User>([SELECT Id FROM User WHERE Id IN :validDispatchers AND IsActive = TRUE])
            .keySet();
        if (!activeUsers.containsAll(dispatcherIds)) {
            throw new TransferException('Valgt bruker er ikke en aktiv tjenesteleverandør-formidler.');
        }

        Set<Id> appointmentIds = dispatcherByAppointment.keySet();
        List<ServiceAppointment> appointments = [
            SELECT Id, Status, HOT_TjenesteleverandorStatus__c, HOT_IsReleasedToTjenesteleverandor__c
            FROM ServiceAppointment
            WHERE Id IN :appointmentIds
            FOR UPDATE
        ];
        if (appointments.size() != appointmentIds.size()) {
            throw new TransferException('Du har ikke tilgang til alle de valgte oppdragene.');
        }

        List<Id> idsToCheck = new List<Id>(appointmentIds);
        Set<Id> editableIds = new Set<Id>();
        Integer offset = 0;
        while (offset < idsToCheck.size()) {
            Set<Id> batchIds = new Set<Id>();
            Integer batchSize = 0;
            while (batchSize < 200 && offset < idsToCheck.size()) {
                batchIds.add(idsToCheck[offset]);
                offset++;
                batchSize++;
            }
            for (UserRecordAccess access : [
                SELECT RecordId, HasEditAccess
                FROM UserRecordAccess
                WHERE UserId = :UserInfo.getUserId() AND RecordId IN :batchIds
            ]) {
                if (access.HasEditAccess) {
                    editableIds.add(access.RecordId);
                }
            }
        }

        List<ServiceAppointment> updates = new List<ServiceAppointment>();
        for (ServiceAppointment appointment : appointments) {
            if (
                !editableIds.contains(appointment.Id) ||
                !TRANSFERABLE_STATUSES.contains(appointment.Status) ||
                appointment.HOT_TjenesteleverandorStatus__c == 'Transferred' ||
                !appointment.HOT_IsReleasedToTjenesteleverandor__c
            ) {
                throw new TransferException('Et eller flere oppdrag er ikke lenger tilgjengelige for overføring.');
            }
            updates.add(
                new ServiceAppointment(
                    Id = appointment.Id,
                    HOT_TLDispatcher__c = dispatcherByAppointment.get(appointment.Id)
                )
            );
        }
        update updates;
    }
}
