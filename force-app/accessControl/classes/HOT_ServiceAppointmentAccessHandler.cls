public with sharing class HOT_ServiceAppointmentAccessHandler extends MyTriggers {

	public virtual void onAfterUpdate( Map<Id, ServiceAppointment> triggerOldMap ) {
		System.debug( 'Frode: start' );
		List<String> completedStatuses = new List<String> {'Fullført', 'Kan ikke fullføre', 'Avbrutt'};
		Set<Id> serviceAppointmentIds = new Set<Id> ();
		for ( ServiceAppointment sa:(List<ServiceAppointment>) records ) {
			serviceAppointmentIds.add( sa.Id );
		}
		HOT_ServiceAppointmentsSharingService.removeManualAccess( serviceAppointmentIds );
	}
}