public without sharing class HOT_UpdateChildRecordsService {
    @InvocableVariable
    public HOT_Request__c request;

    @InvocableVariable
    public Boolean isAddressChoice;
    @InvocableVariable
    public Boolean isSubjectChoice;
    @InvocableVariable
    public Boolean isDescriptionChoice;
    @InvocableVariable
    public Boolean isScreenInterpreterChoice;
    @InvocableVariable
    public Boolean isDispatcherChoice;

    @InvocableMethod
    public static List<String> updateChildRecordsFromRequest(List<HOT_UpdateChildRecordsService> inputVariables) {
        List<String> woStatuses = new List<String>{ 'New', 'Scheduled', 'Dispatched' };
        List<String> woliStatuses = new List<String>{ 'New', 'Scheduled', 'Dispatched' };
        List<String> saStatuses = new List<String>{ 'None', 'Released to Freelance', 'Scheduled', 'Dispatched' };
        HOT_UpdateChildRecordsService input = inputVariables[0];
        HOT_Request__c request = input.request;
        List<String> errors = new List<String>();

        HOT_Request__c requestToUpdate = new HOT_Request__c(Id = request.Id);
        if (input.isAddressChoice) {
            requestToUpdate.InterpretationStreet__c = request.InterpretationStreet__c;
            requestToUpdate.InterpretationPostalCode__c = request.InterpretationPostalCode__c;
            requestToUpdate.InterpretationPostalCity__c = request.InterpretationPostalCity__c;
            requestToUpdate.MeetingStreet__c = request.MeetingStreet__c;
            requestToUpdate.MeetingPostalCode__c = request.MeetingPostalCode__c;
            requestToUpdate.MeetingPostalCity__c = request.MeetingPostalCity__c;
        }
        if (input.isSubjectChoice) {
            requestToUpdate.Subject__c = request.Subject__c;
        }
        if (input.isDescriptionChoice) {
            requestToUpdate.Description__c = request.Description__c;
        }
        if (input.isScreenInterpreterChoice) {
            requestToUpdate.IsScreenInterpreter__c = request.IsScreenInterpreter__c;
        }
        if (input.isDispatcherChoice) {
            requestToUpdate.Dispatcher__c = request.Dispatcher__c;
        }

        try {
            update requestToUpdate;
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
            logger.publishSynch();
            errors.add('Could not update request');
        }

        Map<Id, WorkOrder> workOrders = new Map<Id, WorkOrder>(
            [
                SELECT
                    Id,
                    Status,
                    HOT_InterpretationStreet__c,
                    HOT_InterpretationPostalCode__c,
                    HOT_InterpretationPostalCity__c,
                    Street,
                    PostalCode,
                    City,
                    Subject,
                    Description
                FROM WorkOrder
                WHERE HOT_Request__c = :request.Id AND Status IN :woStatuses
            ]
        );
        Map<Id, WorkOrderLineItem> workOrderLineItems = new Map<Id, WorkOrderLineItem>(
            [
                SELECT
                    Id,
                    Status,
                    HOT_InterpretationPostalStreet__c,
                    HOT_InterpretationPostalCode__c,
                    HOT_InterpretationPostalCity__c,
                    Street,
                    PostalCode,
                    City,
                    Subject,
                    Description
                FROM WorkOrderLineItem
                WHERE WorkOrder.HOT_Request__c = :request.Id AND Status IN :woliStatuses
            ]
        );
        Map<Id, ServiceAppointment> serviceAppointments = new Map<Id, ServiceAppointment>(
            [
                SELECT
                    Id,
                    Status,
                    HOT_InterpretationStreet__c,
                    HOT_InterpretationPostalCode__c,
                    HOT_InterpretationPostalCity__c,
                    Street,
                    PostalCode,
                    City,
                    Subject,
                    Description,
                    HOT_IsScreenInterpreterNew__c
                FROM ServiceAppointment
                WHERE HOT_Request__c = :request.Id AND Status IN :saStatuses
            ]
        );

        //Updates WorkOrders
        for (WorkOrder workOrder : workOrders.values()) {
            if (input.isAddressChoice) {
                workOrder.HOT_InterpretationStreet__c = request.InterpretationStreet__c;
                workOrder.HOT_InterpretationPostalCode__c = request.InterpretationPostalCode__c;
                workOrder.HOT_InterpretationPostalCity__c = request.InterpretationPostalCity__c;
                workOrder.Street = request.MeetingStreet__c;
                workOrder.PostalCode = request.MeetingPostalCode__c;
                workOrder.City = request.MeetingPostalCity__c;
            }
            if (input.isSubjectChoice) {
                workOrder.Subject = request.Subject__c;
            }
            if (input.isDescriptionChoice) {
                workOrder.Description = request.Description__c;
            }
        }
        try {
            update workOrders.values();
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
            logger.publishSynch();
            errors.add('Could not update workOrders');
        }
        //Updates WorkOrderLineItems
        for (WorkOrderLineItem workOrderLineItem : workOrderLineItems.values()) {
            if (input.isAddressChoice) {
                workOrderLineItem.HOT_InterpretationPostalStreet__c = request.InterpretationStreet__c;
                workOrderLineItem.HOT_InterpretationPostalCode__c = request.InterpretationPostalCode__c;
                workOrderLineItem.HOT_InterpretationPostalCity__c = request.InterpretationPostalCity__c;
                workOrderLineItem.Street = request.MeetingStreet__c;
                workOrderLineItem.PostalCode = request.MeetingPostalCode__c;
                workOrderLineItem.City = request.MeetingPostalCity__c;
            }
            if (input.isSubjectChoice) {
                workOrderLineItem.Subject = request.Subject__c;
            }
            if (input.isDescriptionChoice) {
                workOrderLineItem.Description = request.Description__c;
            }
        }

        try {
            update workOrderLineItems.values();
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
            logger.publishSynch();
            errors.add('Could not update workOrderLineItems');
        }

        //Updates ServiceAppointment
        for (ServiceAppointment serviceAppointment : serviceAppointments.values()) {
            if (input.isAddressChoice) {
                serviceAppointment.HOT_InterpretationStreet__c = request.InterpretationStreet__c;
                serviceAppointment.HOT_InterpretationPostalCode__c = request.InterpretationPostalCode__c;
                serviceAppointment.HOT_InterpretationPostalCity__c = request.InterpretationPostalCity__c;
                serviceAppointment.Street = request.MeetingStreet__c;
                serviceAppointment.PostalCode = request.MeetingPostalCode__c;
                serviceAppointment.City = request.MeetingPostalCity__c;
            }
            if (input.isSubjectChoice) {
                serviceAppointment.Subject = request.Subject__c;
            }
            if (input.isDescriptionChoice) {
                serviceAppointment.Description = request.Description__c;
            }
            if (input.isScreenInterpreterChoice) {
                serviceAppointment.HOT_IsScreenInterpreterNew__c = request.IsScreenInterpreter__c;
            }
            if (input.isDispatcherChoice) {
                serviceAppointment.HOT_DispatcherNew__c = request.Dispatcher__c;
            }
        }

        try {
            update serviceAppointments.values();
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
            logger.publishSynch();
            errors.add('Could not update serviceAppointments');
        }

        return errors;
    }
}
