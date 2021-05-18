public without sharing class HOT_ServiceAppointmentsSharingService {
    public static void grantAccess(Map<Id, Id> apppointmentIdByAssignment, Map<Id, Id> resourceByAssignment) {
        Map<Id, Id> userIdyResourceId = getUserIdyResourceId(resourceByAssignment.values());
        Map<Id, Id> woBySa = getWorkOrderIds(apppointmentIdByAssignment.values());
        Map<Id, User> userByUserId = getUserById(userIdyResourceId.values());
        Map<Id, Id> accountIdByServiceAppointmentId = getAccountIdByServiceAppointmentId(
            apppointmentIdByAssignment.values()
        );
        List<ServiceAppointmentShare> serviceAppointmentShares = new List<ServiceAppointmentShare>();
        List<WorkOrderShare> workOrderShares = new List<WorkOrderShare>();
        List<AccountShare> accountShares = new List<AccountShare>();
        for (Id assignmentId : apppointmentIdByAssignment.keySet()) {
            Id resourceId = resourceByAssignment.get(assignmentId);
            Id userId = userIdyResourceId.get(resourceId);
            Id serviceAppointmentId = apppointmentIdByAssignment.get(assignmentId);
            String workOrderAccessLevel = 'Edit';
            if (userByUserId.get(userId).IsPortalEnabled == true) {
                workOrderAccessLevel = 'Read';
            }
            serviceAppointmentShares.add(
                new ServiceAppointmentShare(
                    ParentId = serviceAppointmentId,
                    AccessLevel = 'Edit',
                    RowCause = 'Manual',
                    UserOrGroupId = userId
                )
            );
            workOrderShares.add(
                new WorkOrderShare(
                    ParentId = woBySa.get(serviceAppointmentId),
                    AccessLevel = workOrderAccessLevel,
                    RowCause = 'Manual',
                    UserOrGroupId = userId
                )
            );
            accountShares.add(
                new AccountShare(
                    AccountId = accountIdByServiceAppointmentId.get(serviceAppointmentId),
                    AccountAccessLevel = 'Read',
                    CaseAccessLevel = 'None',
                    OpportunityAccessLevel = 'None',
                    RowCause = 'Manual',
                    UserOrGroupId = userId
                )
            );
        }
        Database.insert(serviceAppointmentShares, false);
        Database.insert(workOrderShares, false);
        Database.insert(accountShares, false);
    }

    @future
    public static void removeAccessForSpecificUsers(
        Map<Id, Id> apppointmentByAssignment,
        Map<Id, Id> resourceByAssignment
    ) {
        Map<Id, Id> userIdyResourceId = getUserIdyResourceId(resourceByAssignment.values());
        String soqlQuery = 'SELECT Id FROM ServiceAppointmentShare WHERE RowCause =\'Manual\' AND (';
        for (Id assignmentId : apppointmentByAssignment.keySet()) {
            Id resourceId = resourceByAssignment.get(assignmentId);
            Id userId = userIdyResourceId.get(resourceId);
            Id serviceAppointmentId = apppointmentByAssignment.get(assignmentId);
            soqlQuery += ' (UserOrGroupId=\'' + userId + '\' AND ParentId=\'' + serviceAppointmentId + '\') OR';
        }
        soqlQuery = soqlQuery.removeEnd('OR');
        soqlQuery += ')';
        List<ServiceAppointmentShare> serviceAppointmentShares = Database.query((soqlQuery));
        try {
            delete serviceAppointmentShares;
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
            logger.publishSynch();
        }
    }

    public static void removeManualAccess(Set<Id> serviceAppointIds) {
        List<ServiceAppointmentShare> serviceAppointmentShares = [
            SELECT Id
            FROM ServiceAppointmentShare
            WHERE RowCause = 'Manual' AND ParentId IN :serviceAppointIds
        ];
        try {
            delete serviceAppointmentShares;
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
            logger.publishSynch();
        }
    }

    private static Map<Id, Id> getUserIdyResourceId(List<Id> resourceIds) {
        Map<Id, Id> userIdyResourceId = new Map<Id, Id>();
        for (ServiceResource sr : [SELECT Id, RelatedRecordId FROM ServiceResource WHERE Id IN :resourceIds]) {
            userIdyResourceId.put(sr.Id, sr.RelatedRecordId);
        }

        return userIdyResourceId;
    }

    private static Map<Id, User> getUserById(List<Id> userIds) {
        Map<Id, User> userByUserId = new Map<Id, User>();
        for (User user : [SELECT Id, IsPortalEnabled FROM User WHERE Id IN :userIds]) {
            userByUserId.put(user.Id, user);
        }

        return userByUserId;
    }

    private static Map<Id, Id> getWorkOrderIds(List<Id> serviceApponntmentIds) {
        Map<Id, Id> workOrderLineByServiceAppointment = new Map<Id, Id>();
        for (ServiceAppointment sa : [
            SELECT Id, ParentRecordId
            FROM ServiceAppointment
            WHERE Id IN :serviceApponntmentIds
        ]) {
            workOrderLineByServiceAppointment.put(sa.Id, sa.ParentRecordId);
        }
        Map<Id, Id> workOrderByLine = new Map<Id, Id>();
        for (WorkOrderLineItem woli : [
            SELECT Id, WorkOrderId
            FROM WorkOrderLineItem
            WHERE Id IN :workOrderLineByServiceAppointment.values()
        ]) {
            workOrderByLine.put(woli.Id, woli.WorkOrderId);
        }
        Map<Id, Id> workOrderByServiceAppointment = new Map<Id, Id>();
        for (Id saId : serviceApponntmentIds) {
            Id woliId = workOrderLineByServiceAppointment.get(saId);
            workOrderByServiceAppointment.put(saId, workOrderByLine.get(woliId));
        }

        return workOrderByServiceAppointment;
    }

    private static Map<Id, Id> getAccountIdByServiceAppointmentId(List<Id> serviceApponntmentIds) {
        Map<Id, Id> accountIdByServiceAppointmentId = new Map<Id, Id>();
        for (ServiceAppointment sa : [
            SELECT Id, AccountId
            FROM ServiceAppointment
            WHERE Id IN :serviceApponntmentIds
        ]) {
            accountIdByServiceAppointmentId.put(sa.Id, sa.AccountId);
        }
        return AccountIdByServiceAppointmentId;
    }
}
