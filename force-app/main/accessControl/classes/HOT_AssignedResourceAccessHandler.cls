public without sharing class HOT_AssignedResourceAccessHandler extends MyTriggers {
    public override void onAfterInsert() {
        Map<Id, Id> apppointmentByAssignment = new Map<Id, Id>();
        Map<Id, Id> resourceByAssignment = new Map<Id, Id>();

        for (AssignedResource ar : [
            SELECT Id, ServiceAppointment.Status, ServiceResourceId
            FROM AssignedResource
            WHERE Id IN :records
        ]) {
            if (ar.ServiceAppointment.Status == 'Dispatched') {
                apppointmentByAssignment.put(ar.Id, ar.ServiceAppointmentId);
                resourceByAssignment.put(ar.Id, ar.ServiceResourceId);
            }
        }

        HOT_ServiceAppointmentsSharingService.grantAccess(apppointmentByAssignment, resourceByAssignment);
    }

    public override void onAfterUpdate(Map<Id, sObject> triggerOldMap) {
        Map<Id, Id> apppointmentByAssignment = new Map<Id, Id>();
        Map<Id, Id> resourceToAddByAssignment = new Map<Id, Id>();
        Boolean runSharingService = false;

        for (AssignedResource ar : [
            SELECT Id, ServiceAppointment.Status, ServiceResourceId
            FROM AssignedResource
            WHERE Id IN :records
        ]) {
            AssignedResource oldRecord = (AssignedResource) triggerOldMap.get(ar.Id);
            if (ar.ServiceResourceId != oldRecord.ServiceResourceId && ar.ServiceAppointment.Status == 'Dispatched') {
                apppointmentByAssignment.put(ar.Id, ar.ServiceAppointmentId);
                resourceToAddByAssignment.put(ar.Id, ar.ServiceResourceId);
                runSharingService = true;
            }
        }
        if (runSharingService) {
            update setRecalculateManualSharingFlagOnServiceAppointment(apppointmentByAssignment.values());
            HOT_ServiceAppointmentsSharingService.grantAccess(apppointmentByAssignment, resourceToAddByAssignment);
        }
    }

    public override void onBeforeDelete() {
        Map<Id, Id> apppointmentByAssignment = new Map<Id, Id>();

        for (AssignedResource ar : (List<AssignedResource>) records) {
            apppointmentByAssignment.put(ar.Id, ar.ServiceAppointmentId);
        }

        update setRecalculateManualSharingFlagOnServiceAppointment(apppointmentByAssignment.values());
    }

    public static List<ServiceAppointment> setRecalculateManualSharingFlagOnServiceAppointment(
        List<Id> serviceAppointmentIds
    ) {
        List<ServiceAppointment> serviceAppointments = new List<ServiceAppointment>();
        for (Id id : serviceAppointmentIds) {
            serviceAppointments.add(new ServiceAppointment(Id = id, HOT_IsRecalculateManualSharing__c = true));
        }
        return serviceAppointments;
    }
}
