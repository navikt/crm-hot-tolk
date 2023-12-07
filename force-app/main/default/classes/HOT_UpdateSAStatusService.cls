public without sharing class HOT_UpdateSAStatusService {
    @InvocableVariable
    public ServiceAppointment serviceAppointment;

    @InvocableMethod
    public static void updateServiceAppointmentStatus(List<HOT_UpdateSAStatusService> inputVariables) {
        HOT_UpdateSAStatusService input = inputVariables[0];
        ServiceAppointment serviceAppointment = input.serviceAppointment;
        ServiceAppointment serviceAppointmentToUpdate = new ServiceAppointment(Id = serviceAppointment.Id);
        List<String> errors = new List<String>();

        ServiceAppointment oldServiceAppointment = [
            SELECT Id, HOT_ServiceResource__r.RelatedRecordId
            FROM ServiceAppointment
            WHERE Id = :serviceAppointment.Id
        ];

        if (oldServiceAppointment.HOT_ServiceResource__r.RelatedRecordId == UserInfo.getUserId()) {
            serviceAppointmentToUpdate.Status = serviceAppointment.Status;
            if (serviceAppointment.Status == 'Completed') {
                serviceAppointmentToUpdate.ActualStartTime = serviceAppointment.ActualStartTime;
                serviceAppointmentToUpdate.ActualEndTime = serviceAppointment.ActualEndTime;
                serviceAppointmentToUpdate.HOT_DoNotCreateHAR__c = serviceAppointment.HOT_DoNotCreateHAR__c;
            }
            if (ServiceAppointment.Status == 'Canceled') {
                serviceAppointmentToUpdate.HOT_CancelComment__c = serviceAppointment.HOT_CancelComment__c;
                serviceAppointmentToUpdate.HOT_DoNotCreateHAR__c = serviceAppointment.HOT_DoNotCreateHAR__c;
                serviceAppointmentToUpdate.HOT_IsNotifyDispatcher__c = serviceAppointment.HOT_IsNotifyDispatcher__c;
            }
            if (ServiceAppointment.Status == 'None') {
                serviceAppointmentToUpdate.HOT_IsNotifyDispatcher__c = serviceAppointment.HOT_IsNotifyDispatcher__c;
                serviceAppointmentToUpdate.HOT_AssignedResourceId__c = serviceAppointment.HOT_AssignedResourceId__c;
                serviceAppointmentToUpdate.HOT_ServiceResource__c = serviceAppointment.HOT_ServiceResource__c;
                serviceAppointmentToUpdate.HOT_CanceledByInterpreter__c = serviceAppointment.HOT_CanceledByInterpreter__c;
                serviceAppointmentToUpdate.HOT_DoNotCreateHAR__c = serviceAppointment.HOT_DoNotCreateHAR__c;
                serviceAppointmentToUpdate.HOT_IsNotifyDispatcher__c = serviceAppointment.HOT_IsNotifyDispatcher__c;
            }
        } else {
            LoggerUtility logger = new LoggerUtility();
            logger.error(
                'Update of SA failed because the assigned resource is not the same as initator of the flow:\nSR: ' +
                oldServiceAppointment.HOT_ServiceResource__r.RelatedRecordId +
                ' Initiator: ' +
                UserInfo.getUserId(),
                oldServiceAppointment,
                CRM_ApplicationDomain.Domain.HOT
            );
            logger.publishSynch();
        }
        try {
            update serviceAppointmentToUpdate;
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
            logger.publishSynch();
            errors.add('Could not update request');
        }
    }
}
