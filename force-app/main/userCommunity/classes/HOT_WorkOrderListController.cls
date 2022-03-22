public without sharing class HOT_WorkOrderListController {
    @AuraEnabled(cacheable=true)
    public static List<WorkOrder> getMyWorkOrders() {
        Map<Id, WorkOrder> workOrders = new Map<Id, WorkOrder>();
        Id userId = UserInfo.getUserId();
        User user = [SELECT Id, AccountId, Name FROM User WHERE Id = :userId];
        if (user.AccountId != null) {
            workOrders = new Map<Id, WorkOrder>(
                [
                    SELECT
                        Id,
                        StartDate,
                        EndDate,
                        Subject,
                        Address,
                        Street,
                        City,
                        PostalCode,
                        Status,
                        HOT_ExternalWorkOrderStatus__c,
                        HOT_RequestName__c,
                        HOT_Interpreters__c,
                        HOT_Request__r.Orderer__c,
                        HOT_IsCancelable__c
                    FROM WorkOrder
                    WHERE HOT_Request__r.Account__c = :user.AccountId AND StartDate >= :DateTime.NOW()
                    ORDER BY StartDate
                ]
            );
        }
        workOrders = getAndSetInterpreters(workOrders);
        workOrders = getRowActions(workOrders);
        return workOrders.values();
    }

    @AuraEnabled(cacheable=true)
    public static List<WorkOrder> getMyWorkOrdersAndRelatedRequest(Boolean isAccount) {
        Map<Id, WorkOrder> workOrders = new Map<Id, WorkOrder>();
        Id userId = UserInfo.getUserId();
        User user = [SELECT Id, AccountId, Name FROM User WHERE Id = :userId];
        if (user.AccountId == null) {
            return new List<WorkOrder>();
        }
        workOrders = new Map<Id, WorkOrder>(
            [
                SELECT
                    Id,
                    HOT_RequestName__c,
                    StartDate,
                    EndDate,
                    Subject,
                    HOT_AddressFormated__c,
                    Status,
                    Owner.Name,
                    HOT_ExternalWorkOrderStatus__c,
                    HOT_Interpreters__c,
                    HOT_IsCancelable__c,
                    HOT_InterpretationStreet__c,
                    HOT_InterpretationPostalCity__c,
                    HOT_InterpretationPostalCode__c,
                    HOT_Request__c,
                    HOT_Request__r.Name,
                    HOT_Request__r.PaymentLiability__c,
                    HOT_Request__r.SeriesStartDate__c,
                    HOT_Request__r.Subject__c,
                    HOT_Request__r.StartTime__c,
                    HOT_Request__r.EndTime__c,
                    HOT_Request__r.SeriesEndDate__c,
                    HOT_Request__r.MeetingStreet__c,
                    HOT_Request__r.MeetingPostalCode__c,
                    HOT_Request__r.MeetingPostalCity__c,
                    HOT_Request__r.NumberOfWorkOrders__c,
                    HOT_Request__r.AdditionalInvoicetext__c,
                    HOT_Request__r.InterpretationStreet__c,
                    HOT_Request__r.InterpretationPostalCode__c,
                    HOT_Request__r.InterpretationPostalCity__c,
                    HOT_Request__r.IsSerieoppdrag__c,
                    HOT_Request__r.IsScreenInterpreter__c,
                    HOT_Request__r.IsOtherEconomicProvicer__c,
                    HOT_Request__r.IsOrdererWantStatusUpdateOnSMS__c,
                    HOT_Request__r.InvoiceReference__c,
                    HOT_Request__r.Description__c,
                    HOT_Request__r.Status__c,
                    HOT_Request__r.ExternalRequestStatus__c,
                    HOT_Request__r.Account__c,
                    HOT_Request__r.ActualUserName__c,
                    HOT_Request__r.TempAccountId__c,
                    HOT_Request__r.OrganizationNumber__c,
                    HOT_Request__r.Source__c,
                    HOT_Request__r.Type__c,
                    toLabel(HOT_Request__r.EventType__c),
                    HOT_Request__r.Orderer__r.Name,
                    HOT_Request__r.Orderer__c,
                    HOT_Request__r.OrdererPhone__c,
                    HOT_Request__r.OrdererEmail__c,
                    HOT_Request__r.OrdererName__c,
                    HOT_Request__r.Owner.Name,
                    toLabel(HOT_Request__r.AssignmentType__c),
                    HOT_AssignmentType__c,
                    HOT_Request__r.UserName__c,
                    HOT_Request__r.UserPersonNumber__c,
                    HOT_Request__r.UserPreferredInterpreter__c,
                    toLabel(HOT_Request__r.UserInterpretationMethod__c),
                    HOT_Request__r.Company__r.Name,
                    HOT_Request__r.InterpretationMethod__r.Name,
                    HOT_Request__r.InterpretationMethodSecondary__r.Name
                FROM WorkOrder
                WHERE
                    (HOT_Request__r.Account__c = :user.AccountId
                    OR HOT_Request__r.Orderer__c = :user.AccountId)
                    AND Status != 'Annul'
                ORDER BY StartDate
            ]
        );
        Map<Id, WorkOrder> workOrdersAccount = new Map<Id, WorkOrder>();
        Map<Id, WorkOrder> workOrdersOrderer = new Map<Id, WorkOrder>();
        for (WorkOrder wo : workOrders.values()) {
            if (wo.HOT_Request__r.Account__c == user.AccountId) {
                workOrdersAccount.put(wo.Id, wo);
            } else {
                workOrdersOrderer.put(wo.Id, wo);
            }
        }
        workOrders = isAccount ? workOrdersAccount : workOrdersOrderer;
        workOrders = getAndSetInterpreters(workOrders);
        return workOrders.values();
    }

    @AuraEnabled(cacheable=true)
    public static List<WorkOrder> getWorkOrdersFromRequest(String requestNumber) {
        Map<Id, WorkOrder> workOrders = new Map<Id, WorkOrder>();
        Id userId = UserInfo.getUserId();
        User user = [SELECT Id, AccountId, Name FROM User WHERE Id = :userId];
        if (user.AccountId != null && requestNumber != null) {
            workOrders = new Map<Id, WorkOrder>(
                [
                    SELECT
                        Id,
                        StartDate,
                        EndDate,
                        Subject,
                        Address,
                        Street,
                        City,
                        PostalCode,
                        Status,
                        HOT_ExternalWorkOrderStatus__c,
                        HOT_RequestName__c,
                        HOT_Interpreters__c,
                        HOT_Request__r.Orderer__c,
                        HOT_IsCancelable__c
                    FROM WorkOrder
                    WHERE
                        HOT_Request__r.Name = :requestNumber
                        AND (HOT_Request__r.Account__c = :user.AccountId
                        OR HOT_Request__r.Orderer__c = :user.AccountId)
                    ORDER BY StartDate
                ]
            );
        }
        workOrders = getAndSetInterpreters(workOrders);
        workOrders = getRowActions(workOrders);
        return workOrders.values();
    }

    public static Map<Id, WorkOrder> getAndSetInterpreters(Map<Id, WorkOrder> workOrders) {
        List<String> statuses = new List<String>{ 'Dispatched', 'In Progress', 'Completed', 'Partially Complete' };
        Map<Id, WorkOrderLineItem> workOrderLineItems = new Map<Id, WorkOrderLineItem>(
            [
                SELECT Id, WorkOrderId
                FROM WorkOrderLineItem
                WHERE WorkOrderId IN :workOrders.keySet() AND WorkOrder.Status IN :statuses
            ]
        );
        List<ServiceAppointment> serviceAppointments = [
            SELECT Id, ParentRecordId, HOT_ServiceResource__r.Name, HOT_IsScreenInterpreterNew__c
            FROM ServiceAppointment
            WHERE ParentRecordId IN :workOrderLineItems.keySet() AND Status IN :statuses
        ];
        for (ServiceAppointment serviceAppointment : serviceAppointments) {
            if (serviceAppointment.HOT_ServiceResource__r.Name != null) {
                String screenInterpreter = '';
                if (serviceAppointment.HOT_IsScreenInterpreterNew__c) {
                    screenInterpreter = ' (skjermtolk)';
                }

                if (
                    workOrders.get(workOrderLineItems.get(serviceAppointment.ParentRecordId).WorkOrderId)
                        .HOT_Interpreters__c == null
                ) {
                    workOrders.get(workOrderLineItems.get(serviceAppointment.ParentRecordId).WorkOrderId)
                            .HOT_Interpreters__c =
                        serviceAppointment.HOT_ServiceResource__r.Name +
                        screenInterpreter +
                        ', ';
                } else {
                    workOrders.get(workOrderLineItems.get(serviceAppointment.ParentRecordId).WorkOrderId)
                            .HOT_Interpreters__c +=
                        serviceAppointment.HOT_ServiceResource__r.Name +
                        screenInterpreter +
                        ', ';
                }
            }
        }
        for (Id id : workOrders.keySet()) {
            if (workOrders.get(id).HOT_Interpreters__c != null) {
                if (workOrders.get(id).HOT_Interpreters__c.right(2) == ', ') {
                    workOrders.get(id).HOT_Interpreters__c = workOrders.get(id).HOT_Interpreters__c.removeEnd(', ');
                }
            }
        }
        return workOrders;
    }

    public static Map<Id, WorkOrder> getRowActions(Map<Id, WorkOrder> workOrders) {
        User user = [SELECT AccountId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        if (user.AccountId != null) {
            Id accountId = user.AccountId;
            for (Id workOrderId : workOrders.keySet()) {
                if (
                    workOrders.get(workOrderId).Status != 'Canceled' &&
                    workOrders.get(workOrderId).Status != 'Partially Complete' &&
                    workOrders.get(workOrderId).Status != 'Completed' &&
                    workOrders.get(workOrderId).HOT_Request__r.Orderer__c == AccountId
                ) {
                    workOrders.get(workOrderId).HOT_IsCancelable__c = true;
                }
            }
        }
        return workOrders;
    }
}
