public with sharing class HOT_AutoScheduleService {
    @InvocableVariable
    public String parentRecordId;
    @InvocableVariable
    public String parentRecordType;

    @InvocableMethod
    public static List<String> setAutoScheduleOnServiceAppointments(List<HOT_AutoScheduleService> inputVariables) {
        String parentRecordId = inputVariables[0].parentRecordId;
        String parentRecordType = inputVariables[0].parentRecordType;
        List<String> errors = new List<String>();
        String queryString;
        Set<String> serviceAppointmentFields = Schema.SObjectType.ServiceAppointment.fields.getMap().keySet();

        if (serviceAppointmentFields.contains('fsl__auto_schedule__c')) {
            if (parentRecordType == 'request') {
                queryString = 'SELECT Id, FSL__Auto_Schedule__c FROM ServiceAppointment WHERE HOT_Request__c = :parentRecordId AND HOT_ServiceResource__c = null';
            }
            if (parentRecordType == 'workOrder') {
                queryString = 'SELECT Id, FSL__Auto_Schedule__c FROM ServiceAppointment WHERE HOT_WorkOrderLineItem__r.WorkOrderId = :parentRecordId  AND HOT_ServiceResource__c = null';
            }

            List<ServiceAppointment> serviceAppointments = Database.query(queryString);

            if (serviceAppointments.isEmpty()) {
                errors.add('Det er ingen oppdrag på forespørselen, eller alle oppdragene er allerede tildelt en tolk.');
                return errors;
            }

            for (ServiceAppointment serviceAppointment : serviceAppointments) {
                serviceAppointment.put('FSL__Auto_Schedule__c', true);
            }
            try {
                update serviceAppointments;
            } catch (Exception e) {
                errors.add('Oppdatering av oppdraget feilet.');
            }
        } else {
            errors.add('Kan ikke kjøre denne koden i et miljø uten FSL-pakken.');
        }

        return errors;
    }
}
