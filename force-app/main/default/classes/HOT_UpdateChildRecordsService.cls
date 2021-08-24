public without sharing class HOT_UpdateChildRecordsService {
    @InvocableVariable
    public String requestId;
    @InvocableVariable
    public String interpretationStreet;
    @InvocableVariable
    public String interpretationPostalCode;
    @InvocableVariable
    public String interpretationPostalCity;
    @InvocableVariable
    public String meetingStreet;
    @InvocableVariable
    public String meetingPostalCode;
    @InvocableVariable
    public String meetingPostalCity;
    @InvocableVariable
    public String subject;
    @InvocableVariable
    public String description;
    @InvocableVariable
    public Boolean isScreenInterpreter;
    @InvocableVariable
    public String assignmentType;
    @InvocableVariable
    public String preferredResource1;
    @InvocableVariable
    public String preferredResource2;
    @InvocableVariable
    public String preferredResource3;
    @InvocableVariable
    public String interpretationMethod;
    @InvocableVariable
    public String interpretationMethodSecondary;
    @InvocableVariable
    public String ownerId;

    @InvocableMethod
    public static List<String> updateChildRecordsFromRequest(List<HOT_UpdateChildRecordsService> inputVariables) {
        List<String> woStatuses = new List<String>{ 'New' };
        List<String> woliStatuses = new List<String>{ 'New' };
        List<String> saStatuses = new List<String>{ 'None' };
        HOT_UpdateChildRecordsService input = inputVariables[0];
        List<String> errors = new List<String>();

        HOT_Request__c request = [
            SELECT
                Id,
                InterpretationStreet__c,
                InterpretationPostalCode__c,
                InterpretationPostalCity__c,
                MeetingStreet__c,
                MeetingPostalCode__c,
                MeetingPostalCity__c,
                Subject__c,
                Description__c,
                IsScreenInterpreter__c,
                AssignmentType__c,
                PreferredResource1__c,
                PreferredResource2__c,
                PreferredResource3__c,
                InterpretationMethod__c,
                InterpretationMethodSecondary__c
            FROM HOT_Request__c
            WHERE Id = :input.requestId
        ];
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
                WHERE HOT_Request__c = :input.requestId AND Status IN :woStatuses
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
                WHERE WorkOrderId IN :workOrders.keySet() AND Status IN :woliStatuses
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
                WHERE HOT_Request__c = :input.requestId AND Status IN :saStatuses
            ]
        );

        //Update Request
        if (input.interpretationStreet != null) {
            request.interpretationStreet__c = input.interpretationStreet;
        }
        if (input.interpretationPostalCode != null) {
            request.interpretationPostalCode__c = input.interpretationPostalCode;
        }
        if (input.interpretationPostalCity != null) {
            request.interpretationPostalCity__c = input.interpretationPostalCity;
        }
        if (input.meetingStreet != null) {
            request.MeetingStreet__c = input.meetingStreet;
        }
        if (input.meetingPostalCode != null) {
            request.MeetingPostalCode__c = input.meetingPostalCode;
        }
        if (input.meetingPostalCity != null) {
            request.MeetingPostalCity__c = input.meetingPostalCity;
        }
        if (input.subject != null) {
            request.Subject__c = input.subject;
        }
        if (input.description != null) {
            request.Description__c = input.description;
        }
        if (input.isScreenInterpreter != null) {
            request.IsScreenInterpreter__c = input.isScreenInterpreter;
        }
        if (input.assignmentType != null) {
            request.AssignmentType__c = input.assignmentType;
        }
        if (input.preferredResource1 != null) {
            request.PreferredResource1__c = input.preferredResource1;
        }
        if (input.preferredResource2 != null) {
            request.PreferredResource2__c = input.preferredResource2;
        }
        if (input.preferredResource3 != null) {
            request.PreferredResource3__c = input.preferredResource3;
        }
        if (input.interpretationMethod != null) {
            request.InterpretationMethod__c = input.interpretationMethod;
        }
        if (input.interpretationMethodSecondary != null) {
            request.InterpretationMethodSecondary__c = input.interpretationMethodSecondary;
        }
        try {
            update request;
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
            logger.publishSynch();
            errors.add('Could not update request');
        }

        //Updates WorkOrders
        for (WorkOrder workOrder : workOrders.values()) {
            if (workOrder.Status == 'New') {
                if (input.interpretationStreet != null) {
                    workOrder.HOT_InterpretationStreet__c = input.interpretationStreet;
                }
                if (input.interpretationPostalCode != null) {
                    workOrder.HOT_InterpretationPostalCode__c = input.interpretationPostalCode;
                }
                if (input.interpretationPostalCity != null) {
                    workOrder.HOT_InterpretationPostalCity__c = input.interpretationPostalCity;
                }
                if (input.meetingStreet != null) {
                    workOrder.Street = input.meetingStreet;
                }
                if (input.meetingPostalCode != null) {
                    workOrder.PostalCode = input.meetingPostalCode;
                }
                if (input.meetingPostalCity != null) {
                    workOrder.City = input.meetingPostalCity;
                }
                if (input.subject != null) {
                    workOrder.Subject = input.subject;
                }
                if (input.description != null) {
                    workOrder.Description = input.description;
                }
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
            if (workOrderLineItem.Status == 'New') {
                if (input.interpretationStreet != null) {
                    workOrderLineItem.HOT_InterpretationPostalStreet__c = input.interpretationStreet;
                }
                if (input.interpretationPostalCode != null) {
                    workOrderLineItem.HOT_InterpretationPostalCode__c = input.interpretationPostalCode;
                }
                if (input.interpretationPostalCity != null) {
                    workOrderLineItem.HOT_InterpretationPostalCity__c = input.interpretationPostalCity;
                }
                if (input.meetingStreet != null) {
                    workOrderLineItem.Street = input.meetingStreet;
                }
                if (input.meetingPostalCode != null) {
                    workOrderLineItem.PostalCode = input.meetingPostalCode;
                }
                if (input.meetingPostalCity != null) {
                    workOrderLineItem.City = input.meetingPostalCity;
                }
                if (input.subject != null) {
                    workOrderLineItem.Subject = input.subject;
                }
                if (input.description != null) {
                    workOrderLineItem.Description = input.description;
                }
                //Set WorkType
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
            if (serviceAppointment.Status == 'None') {
                if (input.interpretationStreet != null) {
                    serviceAppointment.HOT_InterpretationStreet__c = input.interpretationStreet;
                }
                if (input.interpretationPostalCode != null) {
                    serviceAppointment.HOT_InterpretationPostalCode__c = input.interpretationPostalCode;
                }
                if (input.interpretationPostalCity != null) {
                    serviceAppointment.HOT_InterpretationPostalCity__c = input.interpretationPostalCity;
                }
                if (input.meetingStreet != null) {
                    serviceAppointment.Street = input.meetingStreet;
                }
                if (input.meetingPostalCode != null) {
                    serviceAppointment.PostalCode = input.meetingPostalCode;
                }
                if (input.meetingPostalCity != null) {
                    serviceAppointment.City = input.meetingPostalCity;
                }
                if (input.subject != null) {
                    serviceAppointment.Subject = input.subject;
                }
                if (input.description != null) {
                    serviceAppointment.Description = input.description;
                }
                if (input.isScreenInterpreter != null) {
                    serviceAppointment.HOT_IsScreenInterpreterNew__c = input.isScreenInterpreter;
                }
                //Set Preferred Resource
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
        //What do we do with Time??
        return errors;
    }
}
