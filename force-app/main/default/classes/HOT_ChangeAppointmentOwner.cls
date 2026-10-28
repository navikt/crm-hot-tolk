public with sharing class HOT_ChangeAppointmentOwner {
    public class Input {
        @InvocableVariable(required=true)
        public List<Id> serviceAppointmentIds;
        @InvocableVariable(required=true)
        public String ownerQueueName;
    }

    @InvocableMethod(label='Endre eier på markerte oppdrag')
    public static void changeOwner(List<Input> inputs) {
        Savepoint savepoint = Database.setSavepoint();
        try {
            updateAppointments(inputs);
        } catch (Exception error) {
            Database.rollback(savepoint);
            LoggerUtility logger = new LoggerUtility();
            logger.exception(error, CRM_ApplicationDomain.Domain.HOT);
            logger.publishSynch();
            throw error;
        }
    }

    private static void updateAppointments(List<Input> inputs) {
        Set<String> queueNames = new Set<String>();
        Set<Id> appointmentIds = new Set<Id>();
        for (Input input : inputs) {
            if (input.serviceAppointmentIds == null || input.serviceAppointmentIds.isEmpty()) {
                throw new OwnerChangeException('Marker minst ett oppdrag i listevisningen.');
            }
            if (String.isBlank(input.ownerQueueName)) {
                throw new OwnerChangeException('Velg ny eier.');
            }
            queueNames.add(input.ownerQueueName);
            appointmentIds.addAll(input.serviceAppointmentIds);
        }

        Map<String, Id> queueIdsByName = new Map<String, Id>();
        for (Group queue : [SELECT Id, Name FROM Group WHERE Type = 'Queue' AND Name IN :queueNames]) {
            queueIdsByName.put(queue.Name.toLowerCase(), queue.Id);
        }
        Map<Id, ServiceAppointment> selectedAppointments = new Map<Id, ServiceAppointment>(
            [
                SELECT Id
                FROM ServiceAppointment
                WHERE Id IN :appointmentIds
            ]
        );
        if (selectedAppointments.size() != appointmentIds.size()) {
            throw new OwnerChangeException('Ett eller flere markerte oppdrag finnes ikke eller er utilgjengelige.');
        }

        Map<Id, ServiceAppointment> updates = new Map<Id, ServiceAppointment>();
        for (Input input : inputs) {
            Id ownerId = queueIdsByName.get(input.ownerQueueName.toLowerCase());
            if (ownerId == null) {
                throw new OwnerChangeException('Fant ikke eierkøen: ' + input.ownerQueueName);
            }
            for (Id appointmentId : input.serviceAppointmentIds) {
                if (updates.containsKey(appointmentId) && updates.get(appointmentId).OwnerId != ownerId) {
                    throw new OwnerChangeException('Samme oppdrag kan ikke flyttes til flere eiere samtidig.');
                }
                updates.put(appointmentId, new ServiceAppointment(Id = appointmentId, OwnerId = ownerId));
            }
        }
        update as user updates.values();
    }

    private class OwnerChangeException extends Exception {
    }
}
