public without sharing class HOT_UpdateChildRecordsService {
    @InvocableVariable
    public HOT_Request__c request;
    @InvocableVariable
    public WorkOrder workOrder;
    @InvocableVariable
    public Boolean isAccountChoice;
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
    @InvocableVariable
    public Boolean isInterpreterMethodChoice;

    @InvocableMethod
    public static List<String> updateChildRecords(List<HOT_UpdateChildRecordsService> inputVariables) {
        List<String> woStatuses = new List<String>{ 'New', 'Scheduled', 'Dispatched' };
        List<String> woliStatuses = new List<String>{ 'New', 'Scheduled', 'Dispatched' };
        List<String> saStatuses = new List<String>{ 'None', 'Released to Freelance', 'Scheduled', 'Dispatched' };
        HOT_UpdateChildRecordsService input = inputVariables[0];
        HOT_Request__c request = input.request;
        List<String> errors = new List<String>();
        String error;
        String errorOutput;
        List<WorkOrder> workOrders = new List<WorkOrder>(
            [
                SELECT
                    Id,
                    Status,
                    AccountId,
                    ContactId,
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
        List<WorkOrderLineItem> workOrderLineItems = new List<WorkOrderLineItem>(
            [
                SELECT
                    Id,
                    Status,
                    HOT_InterpretationPostalStreet__c,
                    HOT_InterpretationPostalCode__c,
                    HOT_InterpretationPostalCity__c,
                    WorkTypeId,
                    Street,
                    PostalCode,
                    City,
                    Subject,
                    Description
                FROM WorkOrderLineItem
                WHERE WorkOrder.HOT_Request__c = :request.Id AND Status IN :woliStatuses
            ]
        );
        List<ServiceAppointment> serviceAppointments = new List<ServiceAppointment>(
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
                    ContactId,
                    Subject,
                    Description,
                    HOT_Account__c,
                    HOT_IsScreenInterpreterNew__c,
                    HOT_DispatcherNew__c,
                    WorkTypeId
                FROM ServiceAppointment
                WHERE HOT_Request__c = :request.Id AND Status IN :saStatuses
            ]
        );

        if (input.request != null && input.workOrder == null) {
            error = updateRequest(
                request,
                input.isAccountChoice,
                input.isAddressChoice,
                input.isSubjectChoice,
                input.isDescriptionChoice,
                input.isScreenInterpreterChoice,
                input.isDispatcherChoice,
                input.isInterpreterMethodChoice
            );
            if (error != null) {
                errorOutput = error;
            }
            error = updateWorkOrder(
                workOrders,
                request,
                input.isAccountChoice,
                input.isAddressChoice,
                input.isSubjectChoice,
                input.isDescriptionChoice,
                input.isInterpreterMethodChoice
            );
            if (error != null) {
                if (errorOutput == null || errorOutput == '') {
                    errorOutput = error;
                } else {
                    errorOutput = errorOutput + '+' + error;
                }
            }
            error = updateWorkOrderLineItem(
                workOrderLineItems,
                request,
                input.isAddressChoice,
                input.isSubjectChoice,
                input.isDescriptionChoice,
                input.isInterpreterMethodChoice
            );
            if (error != null) {
                if (errorOutput == null || errorOutput == '') {
                    errorOutput = error;
                } else {
                    errorOutput = errorOutput + '+' + error;
                }
            }
            error = updateServiceAppointments(
                serviceAppointments,
                request,
                input.isAccountChoice,
                input.isAddressChoice,
                input.isSubjectChoice,
                input.isDescriptionChoice,
                input.isScreenInterpreterChoice,
                input.isDispatcherChoice,
                input.isInterpreterMethodChoice
            );
            if (error != null) {
                if (errorOutput == null || errorOutput == '') {
                    errorOutput = error;
                } else {
                    errorOutput = errorOutput + '+' + error;
                }
            }
        } else if (input.request != null && input.workOrder != null) {
            list<WorkOrder> singleWorkOrder = new List<WorkOrder>{ input.workOrder };
            error = updateWorkOrder(
                singleWorkOrder,
                request,
                input.isAccountChoice,
                input.isAddressChoice,
                input.isSubjectChoice,
                input.isDescriptionChoice,
                input.isInterpreterMethodChoice
            );
            if (error != null) {
                errorOutput = error;
            }
            error = updateWorkOrderLineItem(
                workOrderLineItems,
                request,
                input.isAddressChoice,
                input.isSubjectChoice,
                input.isDescriptionChoice,
                input.isInterpreterMethodChoice
            );
            if (error != null) {
                if (errorOutput == null || errorOutput == '') {
                    errorOutput = error;
                } else {
                    errorOutput = errorOutput + '+' + error;
                }
            }
            error = updateServiceAppointments(
                serviceAppointments,
                request,
                input.isAccountChoice,
                input.isAddressChoice,
                input.isSubjectChoice,
                input.isDescriptionChoice,
                input.isScreenInterpreterChoice,
                input.isDispatcherChoice,
                input.isInterpreterMethodChoice
            );
            if (error != null) {
                if (errorOutput == null || errorOutput == '') {
                    errorOutput = error;
                } else {
                    errorOutput = errorOutput + '+' + error;
                }
            }
        }
        // Only return error message if there is 0 messages, or 1 message. Invocable methods can only have the same input and output size, due to bulkification
        // and because we use a single input (HOT_Request), we will only be able to a single string. Single string is not supported in Invocable, and therefor a LIST is used.
        if (errorOutput != null) {
            errors.add(errorOutput);
        }
        return errors;
    }

    public static String updateRequest(
        HOT_Request__c request,
        Boolean isAccountChoice,
        Boolean isAddressChoice,
        Boolean isSubjectChoice,
        Boolean isDescriptionChoice,
        Boolean isScreenInterpreterChoice,
        Boolean isDispatcherChoice,
        Boolean isInterpreterMethodChoice
    ) {
        HOT_Request__c requestToUpdate = new HOT_Request__c(Id = request.Id);
        String error;
        if (isAccountChoice) {
            requestToUpdate.Account__c = request.Account__c;
            requestToUpdate.UserPersonNumber__c = request.UserPersonNumber__c;
            requestToUpdate.UserName__c = request.UserName__c;
        }
        if (isAddressChoice) {
            requestToUpdate.InterpretationStreet__c = request.InterpretationStreet__c;
            requestToUpdate.InterpretationPostalCode__c = request.InterpretationPostalCode__c;
            requestToUpdate.InterpretationPostalCity__c = request.InterpretationPostalCity__c;
            requestToUpdate.MeetingStreet__c = request.MeetingStreet__c;
            requestToUpdate.MeetingPostalCode__c = request.MeetingPostalCode__c;
            requestToUpdate.MeetingPostalCity__c = request.MeetingPostalCity__c;
        }
        if (isSubjectChoice) {
            requestToUpdate.Subject__c = request.Subject__c;
        }
        if (isDescriptionChoice) {
            requestToUpdate.Description__c = request.Description__c;
        }
        if (isScreenInterpreterChoice) {
            requestToUpdate.IsScreenInterpreter__c = request.IsScreenInterpreter__c;
        }
        if (isDispatcherChoice) {
            requestToUpdate.Dispatcher__c = request.Dispatcher__c;
        }
        if (isInterpreterMethodChoice) {
            requestToUpdate.InterpretationMethod__c = request.InterpretationMethod__c;
        }

        try {
            update requestToUpdate;
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
            logger.publishSynch();
            error = 'Feilet på oppdatering av Forespørsel';
        }
        return error;
    }

    public static String updateWorkOrder(
        List<WorkOrder> workOrders,
        HOT_Request__c request,
        Boolean isAccountChoice,
        Boolean isAddressChoice,
        Boolean isSubjectChoice,
        Boolean isDescriptionChoice,
        Boolean isInterpreterMethodChoice
    ) {
        String error;
        for (WorkOrder workOrder : workOrders) {
            if (isAccountChoice) {
                workOrder.AccountId = request.Account__c;
                workOrder.ContactId = request.HOT_PersonContactId__c;
            }
            if (isAddressChoice) {
                workOrder.HOT_InterpretationStreet__c = request.InterpretationStreet__c;
                workOrder.HOT_InterpretationPostalCode__c = request.InterpretationPostalCode__c;
                workOrder.HOT_InterpretationPostalCity__c = request.InterpretationPostalCity__c;
                workOrder.Street = request.MeetingStreet__c;
                workOrder.PostalCode = request.MeetingPostalCode__c;
                workOrder.City = request.MeetingPostalCity__c;
            }
            if (isSubjectChoice) {
                workOrder.Subject = request.Subject__c;
            }
            if (isDescriptionChoice) {
                workOrder.Description = request.Description__c;
            }
            if (isInterpreterMethodChoice) {
                workOrder.WorkTypeId = request.InterpretationMethod__c;
            }
        }
        try {
            update workOrders;
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
            logger.publishSynch();
            error = 'Feilet ved oppdatering av Arbeidsordre';
        }
        return error;
    }

    public static String updateWorkOrderLineItem(
        List<WorkOrderLineItem> workOrderLineItems,
        HOT_Request__c request,
        Boolean isAddressChoice,
        Boolean isSubjectChoice,
        Boolean isDescriptionChoice,
        Boolean isInterpreterMethodChoice
    ) {
        String error;
        for (WorkOrderLineItem workOrderLineItem : workOrderLineItems) {
            if (isAddressChoice) {
                workOrderLineItem.HOT_InterpretationPostalStreet__c = request.InterpretationStreet__c;
                workOrderLineItem.HOT_InterpretationPostalCode__c = request.InterpretationPostalCode__c;
                workOrderLineItem.HOT_InterpretationPostalCity__c = request.InterpretationPostalCity__c;
                workOrderLineItem.Street = request.MeetingStreet__c;
                workOrderLineItem.PostalCode = request.MeetingPostalCode__c;
                workOrderLineItem.City = request.MeetingPostalCity__c;
            }
            if (isSubjectChoice) {
                workOrderLineItem.Subject = request.Subject__c;
            }
            if (isDescriptionChoice) {
                workOrderLineItem.Description = request.Description__c;
            }
            if (isInterpreterMethodChoice) {
                workOrderLineItem.WorkTypeId = request.InterpretationMethod__c;
            }
        }

        try {
            update workOrderLineItems;
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
            logger.publishSynch();
            error = 'Feilet ved oppdatering av Arbeidsordrelinjer';
        }
        return error;
    }

    public static String updateServiceAppointments(
        List<ServiceAppointment> serviceAppointments,
        HOT_Request__c request,
        Boolean isAccountChoice,
        Boolean isAddressChoice,
        Boolean isSubjectChoice,
        Boolean isDescriptionChoice,
        Boolean isScreenInterpreterChoice,
        Boolean isDispatcherChoice,
        Boolean isInterpreterMethodChoice
    ) {
        String error;
        for (ServiceAppointment serviceAppointment : serviceAppointments) {
            if (isAccountChoice) {
                serviceAppointment.HOT_Account__c = request.Account__c;
                serviceAppointment.ContactId = request.HOT_PersonContactId__c;
            }
            if (isAddressChoice) {
                serviceAppointment.HOT_InterpretationStreet__c = request.InterpretationStreet__c;
                serviceAppointment.HOT_InterpretationPostalCode__c = request.InterpretationPostalCode__c;
                serviceAppointment.HOT_InterpretationPostalCity__c = request.InterpretationPostalCity__c;
                serviceAppointment.Street = request.MeetingStreet__c;
                serviceAppointment.PostalCode = request.MeetingPostalCode__c;
                serviceAppointment.City = request.MeetingPostalCity__c;
            }
            if (isSubjectChoice) {
                serviceAppointment.Subject = request.Subject__c;
            }
            if (isDescriptionChoice) {
                serviceAppointment.Description = request.Description__c;
            }
            if (isScreenInterpreterChoice) {
                serviceAppointment.HOT_IsScreenInterpreterNew__c = request.IsScreenInterpreter__c;
            }
            if (isDispatcherChoice) {
                serviceAppointment.HOT_DispatcherNew__c = request.Dispatcher__c;
            }
            if (isInterpreterMethodChoice) {
                serviceAppointment.WorkTypeId = request.InterpretationMethod__c;
            }
        }

        try {
            update serviceAppointments;
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
            logger.publishSynch();
            error = 'Feilet ved oppdatering av Service Appointment';
        }
        return error;
    }
}
