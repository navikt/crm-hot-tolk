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
                    HOT_Request__r.Thread__c,
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
                    HOT_Request__r.IsAccountEqualOrderer__c,
                    HOT_Request__r.IsOtherEconomicProvicer__c,
                    HOT_Request__r.IsOrdererWantStatusUpdateOnSMS__c,
                    HOT_Request__r.InvoiceReference__c,
                    HOT_Request__r.Description__c,
                    HOT_Request__r.Status__c,
                    HOT_Request__r.ExternalRequestStatus__c,
                    HOT_Request__r.Account__c,
                    HOT_Request__r.IsNotNotifyAccount__c,
                    HOT_Request__r.TempAccountId__c,
                    HOT_Request__r.OrganizationNumber__c,
                    HOT_Request__r.Source__c,
                    HOT_Request__r.Type__c,
                    HOT_Request__r.Orderer__r.Name,
                    HOT_Request__r.Orderer__c,
                    HOT_Request__r.OrdererPhone__c,
                    HOT_Request__r.OrdererEmail__c,
                    HOT_Request__r.OrdererName__c,
                    toLabel(HOT_Request__r.AssignmentType__c),
                    HOT_AssignmentType__c,
                    HOT_Request__r.Account__r.Name,
                    HOT_Request__r.UserName__c,
                    HOT_Request__r.UserPersonNumber__c,
                    HOT_Request__r.UserPhone__c,
                    HOT_Request__r.UserPreferredInterpreter__c,
                    toLabel(HOT_Request__r.UserInterpretationMethod__c),
                    HOT_Request__r.CompanyName__c,
                    HOT_Request__r.OwnerName__c,
                    HOT_Request__r.InterpretationMethodName__c,
                    HOT_DelPol_IsHideInterpreterFromUser__c,
                    (SELECT Id, Subject, EarliestStartTime, DueDate FROM ServiceAppointments)
                FROM WorkOrder
                WHERE
                    (HOT_Request__r.Account__c = :user.AccountId
                    OR HOT_Request__r.Orderer__c = :user.AccountId)
                    AND Status != 'Annul'
                ORDER BY StartDate
            ]
        );
        DateTime oneWeekAgo = DateTime.now().addDays(-7);
        DateTime sixMonthsAgo = DateTime.now().addMonths(-6);

        Map<Id, WorkOrder> workOrdersAccount = new Map<Id, WorkOrder>();
        Map<Id, WorkOrder> workOrdersOrderer = new Map<Id, WorkOrder>();
        for (WorkOrder wo : workOrders.values()) {
            if (wo.HOT_Request__r.Orderer__c == user.AccountId) {
                wo.HOT_Request__r.Orderer__r.Name = null;
            }
            if (wo.EndDate < oneWeekAgo) {
                wo.HOT_Request__r.UserName__c = null;
            }
            if (wo.HOT_DelPol_IsHideInterpreterFromUser__c) {
                wo.HOT_Interpreters__c = '';
            }
            if (wo.HOT_Request__r.Account__c == user.AccountId && !wo.HOT_Request__r.IsNotNotifyAccount__c) {
                workOrdersAccount.put(wo.Id, wo);
            } else if (wo.EndDate > sixMonthsAgo && wo.HOT_Request__r.Orderer__c == user.AccountId) {
                workOrdersOrderer.put(wo.Id, wo);
            }
        }
        workOrders = isAccount ? workOrdersAccount : workOrdersOrderer;
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
        workOrders = getRowActions(workOrders);
        return workOrders.values();
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
    @AuraEnabled
    public static String getThreadInterpreterId(String workOrderId) {
        List<Thread__c> thread = [
            SELECT Id, CRM_Thread_Type__c
            FROM Thread__c
            WHERE CRM_Related_Object__c = :workOrderId AND CRM_Thread_Type__c = 'HOT_BRUKER-TOLK'
            LIMIT 1
        ];
        String Id = '';
        if (thread.size() > 0) {
            Id = thread[0].Id;
        }
        return Id;
    }
    @AuraEnabled(cacheable=true)
    public static List<ServiceAppointment> getServiceAppointmentsIds(String workOrderId) {
        List<ServiceAppointment> saIds = [
            SELECT Id
            FROM ServiceAppointment
            WHERE HOT_WorkOrderLineItem__r.WorkOrderId = :workOrderId
        ];
        return saIds;
    }
}
