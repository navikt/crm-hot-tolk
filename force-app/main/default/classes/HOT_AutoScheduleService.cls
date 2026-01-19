public with sharing class HOT_AutoScheduleService {
    @InvocableVariable
    public String parentRecordId;
    @InvocableVariable
    public String parentRecordType;
    @InvocableVariable
    public Boolean isAutoDispatched;

    @InvocableMethod
    public static List<String> setAutoScheduleOnServiceAppointments(List<HOT_AutoScheduleService> inputVariables) {
        String parentRecordId = inputVariables[0].parentRecordId;
        String parentRecordType = inputVariables[0].parentRecordType;
        Boolean isValueDispatched = inputVariables[0].isAutoDispatched;
        List<String> errors = new List<String>();
        String queryString;
        String queryStringFSLPolicy;
        Set<String> serviceAppointmentFields = Schema.SObjectType.ServiceAppointment.fields.getMap().keySet();
        List<String> statusesToInclude = new List<String>{ 'None', 'Released to Freelance' };


        if (serviceAppointmentFields.contains('fsl__auto_schedule__c')) {
            if (parentRecordType == 'request') {
                queryString = 'SELECT Id, FSL__Auto_Schedule__c, HOT_PreferredResource__c, HOT_AutoDispatch__c, HOT_Request__r.PreferredResource1__c, FROM ServiceAppointment WHERE HOT_Request__c = :parentRecordId AND HOT_ServiceResource__c = null AND Status IN :statusesToInclude';
            }
            if (parentRecordType == 'workOrder') {
                queryString = 'SELECT Id, FSL__Auto_Schedule__c, HOT_PreferredResource__c, HOT_AutoDispatch__c, HOT_Request__r.PreferredResource1__c FROM ServiceAppointment WHERE HOT_WorkOrderLineItem__r.WorkOrderId = :parentRecordId  AND HOT_ServiceResource__c = null AND Status IN :statusesToInclude';
            }
            queryStringFSLPolicy = 'SELECT Id FROM FSL__Scheduling_Policy__c WHERE Name = \'Ubegrenset\' LIMIT 1';

            List<ServiceAppointment> serviceAppointments = Database.query(queryString);
            SObject fslPolicy = Database.query(queryStringFSLPolicy);

            if (serviceAppointments.isEmpty()) {
                errors.add('Det finnes ingen oppdrag å planlegge, eller alle oppdragene er allerede tildelt en tolk.');
                return errors;
            }

            for (ServiceAppointment serviceAppointment : serviceAppointments) {
                serviceAppointment.put('FSL__Auto_Schedule__c', true);

                if (isValueDispatched) {
                  serviceAppointment.put('HOT_AutoDispatch__c', true);
                }

                if (
                    serviceAppointment.HOT_Request__r.PreferredResource1__c != null ||
                    serviceAppointment.HOT_PreferredResource__c != null
                ) {
                    serviceAppointment.put('FSL__Scheduling_Policy_Used__c', fslPolicy.Id);
                }
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
