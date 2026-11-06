public with sharing class HOT_TjenesteleverandorReleaseService {
    @AuraEnabled
    public static void releaseServiceAppointments(List<ServiceAppointment> appointments) {
        if (appointments == null || appointments.isEmpty() || appointments.size() > 200) {
            throw new AuraHandledException('Velg mellom 1 og 200 oppdrag som skal frigis.');
        }

        Set<Id> requestedIds = new Set<Id>();
        for (ServiceAppointment appointment : appointments) {
            if (
                appointment == null ||
                appointment.Id == null ||
                !requestedIds.add(appointment.Id) ||
                appointment.HOT_DeadlineDate__c == null ||
                String.isBlank(appointment.HOT_FreelanceSubject__c) ||
                appointment.HOT_FreelanceSubject__c.length() > 255
            ) {
                throw new AuraHandledException('Alle oppdrag må ha en gyldig frist og et tema på maksimalt 255 tegn.');
            }
        }

        Map<Id, ServiceAppointment> currentAppointments = new Map<Id, ServiceAppointment>(
            [
                SELECT Id, Status, HOT_TjenesteleverandorStatus__c, HOT_IsReleasedToTjenesteleverandor__c
                FROM ServiceAppointment
                WHERE Id IN :requestedIds
                WITH USER_MODE
                FOR UPDATE
            ]
        );
        List<ServiceAppointment> updates = new List<ServiceAppointment>();
        for (ServiceAppointment input : appointments) {
            ServiceAppointment current = currentAppointments.get(input.Id);
            if (
                current == null ||
                current.Status != 'None' ||
                current.HOT_TjenesteleverandorStatus__c != 'Accepted' ||
                !current.HOT_IsReleasedToTjenesteleverandor__c
            ) {
                throw new AuraHandledException(
                    'Et eller flere oppdrag er ikke lenger tilgjengelige for frigivelse. Last inn listen på nytt.'
                );
            }
            updates.add(
                new ServiceAppointment(
                    Id = input.Id,
                    Status = 'Released to Freelance',
                    HOT_DeadlineDate__c = input.HOT_DeadlineDate__c,
                    HOT_FreelanceSubject__c = input.HOT_FreelanceSubject__c
                )
            );
        }

        try {
            update as user updates;
        } catch (DmlException error) {
            throw new AuraHandledException('Oppdragene ble ikke frigitt. ' + error.getDmlMessage(0));
        }
    }
}
