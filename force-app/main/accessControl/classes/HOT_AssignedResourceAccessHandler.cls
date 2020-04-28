public with sharing class HOT_AssignedResourceAccessHandler extends MyTriggers {

	public override void onAfterInsert() {
		Map<Id, Id > apppointmentByAssignment = new Map<Id, Id>();
		Map<Id, Id> resourceByAssignment = new Map<Id, Id>();

		for ( AssignedResource ar:(List<AssignedResource>) records ) {
			apppointmentByAssignment.put( ar.Id, ar.ServiceAppointmentId );
			resourceByAssignment.put( ar.Id, ar.ServiceResourceId );
		}

		HOT_ServiceAppointmentsSharingService.grantAccess( apppointmentByAssignment, resourceByAssignment );
	}

	public override void onBeforeDelete() {
		Map<Id, Id > apppointmentByAssignment = new Map<Id, Id>();
		Map<Id, Id> resourceByAssignment = new Map<Id, Id>();

		for ( AssignedResource ar:(List<AssignedResource>) records ) {
			apppointmentByAssignment.put( ar.Id, ar.ServiceAppointmentId );
			resourceByAssignment.put( ar.Id, ar.ServiceResourceId );
		}

		HOT_ServiceAppointmentsSharingService.removeAccessForSpecificUsers( apppointmentByAssignment, resourceByAssignment );
	}
}
