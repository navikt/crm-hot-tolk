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
        WorkOrder singleWO;
        List<WorkOrderLineItem> workOrderLineItemsWO = new List<WorkOrderLineItem>();
        List<ServiceAppointment> serviceAppointmentsWO = new List<ServiceAppointment>();
        if (input.workOrder == null) {
            singleWO = null;
        } else {
            singleWO = input.workOrder;
        }

        List<WorkOrder> workOrders = new List<WorkOrder>(
            [
                SELECT
                    Id,
                    Status,
                    AccountId,
                    ContactId,
                    HOT_InterpretationAddress__c,
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
                    HOT_InterpretationAddress__c,
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
                    HOT_InterpretationAddress__c,
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
        if (singleWO != null) {
            workOrderLineItemsWO = [
                SELECT
                    Id,
                    Status,
                    HOT_InterpretationAddress__c,
                    WorkTypeId,
                    Street,
                    PostalCode,
                    City,
                    Subject,
                    Description
                FROM WorkOrderLineItem
                WHERE WorkOrderId = :singleWO.Id AND Status IN :woliStatuses
            ];
            serviceAppointmentsWO = [
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
                WHERE HOT_WorkOrderLineItem__r.WorkOrderId = :singleWO.Id AND Status IN :saStatuses
            ];
        }

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
                workOrderLineItemsWO,
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
                serviceAppointmentsWO,
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
            requestToUpdate.InterpretationAddress__Street__s = request.InterpretationAddress__Street__s;
            requestToUpdate.InterpretationAddress__PostalCode__s = request.InterpretationAddress__PostalCode__s;
            requestToUpdate.InterpretationAddress__City__s = request.InterpretationAddress__City__s;

            requestToUpdate.MeetingAddress__Street__s = request.MeetingAddress__Street__s;
            requestToUpdate.MeetingAddress__PostalCode__s = request.MeetingAddress__PostalCode__s;
            requestToUpdate.MeetingAddress__City__s = request.MeetingAddress__City__s;
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
                workOrder.HOT_InterpretationAddress__Street__s = request.InterpretationAddress__Street__s;
                workOrder.HOT_InterpretationAddress__PostalCode__s = request.InterpretationAddress__PostalCode__s;
                workOrder.HOT_InterpretationAddress__City__s = request.InterpretationAddress__City__s;
                workOrder.Street = request.MeetingAddress__Street__s;
                workOrder.PostalCode = request.MeetingAddress__PostalCode__s;
                workOrder.City = request.MeetingAddress__City__s;
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
                workOrderLineItem.HOT_InterpretationAddress__Street__s = request.InterpretationAddress__Street__s;
                workOrderLineItem.HOT_InterpretationAddress__PostalCode__s = request.InterpretationAddress__PostalCode__s;
                workOrderLineItem.HOT_InterpretationAddress__City__s = request.InterpretationAddress__City__s;
                workOrderLineItem.HOT_InterpretationAddress__CountryCode__s = request.InterpretationAddress__CountryCode__s;
                workOrderLineItem.Street = request.MeetingAddress__Street__s;
                workOrderLineItem.PostalCode = request.MeetingAddress__PostalCode__s;
                workOrderLineItem.City = request.MeetingAddress__City__s;
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
                serviceAppointment.HOT_InterpretationAddress__Street__s = request.InterpretationAddress__Street__s;
                serviceAppointment.HOT_InterpretationAddress__PostalCode__s = request.InterpretationAddress__PostalCode__s;
                serviceAppointment.HOT_InterpretationAddress__City__s = request.InterpretationAddress__City__s;

                serviceAppointment.Street = request.MeetingAddress__Street__s;
                serviceAppointment.PostalCode = request.MeetingAddress__PostalCode__s;
                serviceAppointment.City = request.MeetingAddress__City__s;
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
