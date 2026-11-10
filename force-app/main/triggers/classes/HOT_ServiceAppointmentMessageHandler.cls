public without sharing class HOT_ServiceAppointmentMessageHandler extends MyTriggers {
    public override void onAfterInsert() {
        List<HOT_ServiceAppointmentMessage__c> messagesToNotify = new List<HOT_ServiceAppointmentMessage__c>();
        for (HOT_ServiceAppointmentMessage__c message : (List<HOT_ServiceAppointmentMessage__c>) records) {
            if (message.Request__c != null || message.WorkOrder__c != null) {
                messagesToNotify.add(message);
            }
        }

        if (!messagesToNotify.isEmpty()) {
            notifyAssignedInterpreters(messagesToNotify);
        }
    }

    @TestVisible
    private static void notifyAssignedInterpreters(List<HOT_ServiceAppointmentMessage__c> messages) {
        List<AssignedResource> assignedResources = getAssignedResources(messages);
        if (assignedResources.isEmpty()) {
            return;
        }

        HOT_ServiceAppointmentNotification.newServiceAppointmentMessageNotification(messages, assignedResources);
    }

    @TestVisible
    private static List<AssignedResource> getAssignedResources(List<HOT_ServiceAppointmentMessage__c> messages) {
        Set<Id> requestIds = new Set<Id>();
        Set<Id> workOrderIds = new Set<Id>();
        for (HOT_ServiceAppointmentMessage__c message : messages) {
            if (message.Request__c != null) {
                requestIds.add(message.Request__c);
            }
            if (message.WorkOrder__c != null) {
                workOrderIds.add(message.WorkOrder__c);
            }
        }
        if (requestIds.isEmpty() && workOrderIds.isEmpty()) {
            return new List<AssignedResource>();
        }

        return [
            SELECT
                ServiceAppointmentId,
                ServiceAppointment.HOT_Request__c,
                ServiceAppointment.HOT_WorkOrderID__c,
                ServiceResourceId,
                ServiceResource.RelatedRecordId,
                ServiceResource.HOT_IsFreelanceInterpreter__c,
                ServiceResource.HOT_IsEmployedInterpreter__c,
                ServiceResource.HOT_NotificationChannel__c
            FROM AssignedResource
            WHERE
                ServiceAppointment.HOT_Request__c IN :requestIds
                OR ServiceAppointment.HOT_WorkOrderID__c IN :workOrderIds
        ];
    }
}
