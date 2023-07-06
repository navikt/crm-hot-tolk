public without sharing class HOT_ServiceAppointmentAccessHandler extends MyTriggers {
    public override void onAfterUpdate(Map<Id, sObject> triggerOldMap) {
        List<Id> serviceAppointmentsWithUpdatedStatusDispatched = new List<Id>();

        for (ServiceAppointment sa : (List<ServiceAppointment>) records) {
            ServiceAppointment oldRecord = (ServiceAppointment) triggerOldMap.get(sa.Id);
            if (sa.Status != oldRecord.Status && sa.Status == 'Dispatched') {
                serviceAppointmentsWithUpdatedStatusDispatched.add(sa.Id);
            }
        }

        Map<Id, Id> apppointmentByAssignment = new Map<Id, Id>();
        Map<Id, Id> resourceToAddByAssignment = new Map<Id, Id>();

        for (AssignedResource ar : [
            SELECT Id, ServiceAppointmentId, ServiceResourceId
            FROM AssignedResource
            WHERE ServiceAppointmentId IN :serviceAppointmentsWithUpdatedStatusDispatched
        ]) {
            apppointmentByAssignment.put(ar.Id, ar.ServiceAppointmentId);
            resourceToAddByAssignment.put(ar.Id, ar.ServiceResourceId);
        }

        if (serviceAppointmentsWithUpdatedStatusDispatched.size() > 0) {
            update HOT_AssignedResourceAccessHandler.setRecalculateManualSharingFlagOnServiceAppointment(
                serviceAppointmentsWithUpdatedStatusDispatched
            );
            HOT_ServiceAppointmentsSharingService.grantAccess(apppointmentByAssignment, resourceToAddByAssignment);
        }
    }
}
