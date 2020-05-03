public without sharing class HOT_ServiceAppointmentsSharingService {

	public static void grantAccess( Map<Id, Id > apppointmentByAssignment, Map<Id, Id> resourceByAssignment ) {
		Map<Id, Id> userIdyResourceId = getUserIdyResourceId( resourceByAssignment.values() );
		List<ServiceAppointmentShare> shares = new List<ServiceAppointmentShare>();
		for ( Id assignmentId:apppointmentByAssignment.keySet() ) {
			Id resourceId = resourceByAssignment.get( assignmentId );
			shares.add( new ServiceAppointmentShare(
							ParentId = apppointmentByAssignment.get( assignmentId ),
							AccessLevel = 'Edit',
							RowCause = 'Manual',
							UserOrGroupId = userIdyResourceId.get( resourceId )
							) );
		}
		Database.insert( shares, false );
	}

	public static void removeAccessForSpecificUsers( Map<Id, Id > apppointmentByAssignment, Map<Id, Id> resourceByAssignment ) {
		Map<Id, Id> userIdyResourceId = getUserIdyResourceId( resourceByAssignment.values() );
		String soqlQuery = 'SELECT Id FROM ServiceAppointmentShare WHERE RowCause =\'Manual\' AND (';
		for ( Id assignmentId:apppointmentByAssignment.keySet() ) {
			Id resourceId = resourceByAssignment.get( assignmentId );
			Id userId = userIdyResourceId.get( resourceId );
			Id serviceAppointmentId = apppointmentByAssignment.get( assignmentId );
			soqlQuery += ' (UserOrGroupId=\'' + userId + '\' AND ParentId=\'' + serviceAppointmentId + '\') OR';
		}
		soqlQuery = soqlQuery.removeEnd( 'OR' );
		soqlQuery += ')';
		List<ServiceAppointmentShare> serviceAppointmentShares = Database.query( (soqlQuery) );
		delete serviceAppointmentShares;
	}

	public static void removeManualAccess( Set<Id> serviceAppointIds ) {
		List<ServiceAppointmentShare> serviceAppointmentShares = [SELECT Id FROM ServiceAppointmentShare WHERE RowCause = 'Manual' AND ParentId in:serviceAppointIds];
		delete serviceAppointmentShares;
	}

	private static Map<Id, Id> getUserIdyResourceId( List<Id> resourceIds ) {
		Map<Id, Id> userIdyResourceId = new Map<Id, Id>();
		for ( ServiceResource sr:[SELECT Id, RelatedRecordId FROM ServiceResource WHERE Id in:resourceIds] ) {
			userIdyResourceId.put( sr.Id, sr.RelatedRecordId );
		}

		return userIdyResourceId;
	}
}
