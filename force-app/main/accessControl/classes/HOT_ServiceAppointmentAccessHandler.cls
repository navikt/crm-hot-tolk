public with sharing class HOT_ServiceAppointmentAccessHandler extends MyTriggers {

	public override void onAfterUpdate( Map<Id, SObject> triggerOldMap ) {
		List<String> completedStatuses = new List<String> {'Fullført', 'Kan ikke fullføre', 'Avbrutt'};
		List<String> fieldNamesToCheck = new String[] {'Status'};
		Set<Id> serviceAppointmentIds = new Set<Id> ();
		for ( ServiceAppointment sa:(List<ServiceAppointment>) records ) {
			ServiceAppointment s2 = (ServiceAppointment)  triggerOldMap.get( sa.Id );
			if ( completedStatuses.contains( sa.Status ) && MyTriggers.hasChangedFields( fieldNamesToCheck, sa, triggerOldMap.get( sa.Id ) ) ) {
				serviceAppointmentIds.add( sa.Id );
			}
		}
		if ( serviceAppointmentIds.size() > 0 ) {
			HOT_ServiceAppointmentsSharingService.removeManualAccess( serviceAppointmentIds );
		}
	}
}