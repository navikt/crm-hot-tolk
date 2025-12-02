public without sharing class HOT_ServiceAppointmentAccessHandler extends MyTriggers {
    public override void onAfterUpdate(Map<Id, sObject> triggerOldMap) {
        List<Id> serviceAppointmentsWithUpdatedStatusDispatched = new List<Id>();
        Set<Id> serviceAppointmentsHiddenNow = new Set<Id>();

        for (ServiceAppointment sa : (List<ServiceAppointment>) records) {
            ServiceAppointment oldRecord = (ServiceAppointment) triggerOldMap.get(sa.Id);
            if (sa.Status != oldRecord.Status && sa.Status == 'Dispatched' && !system.isBatch()) {
                serviceAppointmentsWithUpdatedStatusDispatched.add(sa.Id);
            }
            // Boolean oldHidden = (oldRecord.HOT_DelPol_IsHideRecord__c == true);
            // if (!oldHidden && sa.HOT_DelPol_IsHideRecord__c == true) {
            //     serviceAppointmentsHiddenNow.add(sa.Id);
            // }
        }

        if (serviceAppointmentsWithUpdatedStatusDispatched.size() > 0) {
            recalculateManualSharingFlagOnServiceAppointment(serviceAppointmentsWithUpdatedStatusDispatched);
        }
        // if (!serviceAppointmentsHiddenNow.isEmpty()) {
        //     HOT_ServiceAppointmentsSharingService.removeAccessForHiddenServiceAppointments(
        //         serviceAppointmentsHiddenNow
        //     );
        // }
    }

    @Future
    private static void recalculateManualSharingFlagOnServiceAppointment(
        List<Id> serviceAppointmentsWithUpdatedStatusDispatched
    ) {
        Map<Id, Id> apppointmentByAssignment = new Map<Id, Id>();
        Map<Id, Id> resourceToAddByAssignment = new Map<Id, Id>();

        List<AssignedResource> arList = [
            SELECT Id, ServiceAppointmentId, ServiceResourceId
            FROM AssignedResource
            WHERE ServiceAppointmentId IN :serviceAppointmentsWithUpdatedStatusDispatched
        ];

        for (AssignedResource ar : arList) {
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
