public with sharing class HOT_ServiceAppointmentsSharingService {

	public static void grantAccess( Map<Id, Id > serviceApppointmentByAssignment, Map<Id, Id> userByAssignment ) {

		List<ServiceAppointmentShare> shares = new List<ServiceAppointmentShare>();
		for ( Id assignmentId:serviceApppointmentByAssignment.keySet() ) {
			shares.add( new ServiceAppointmentShare(
							ParentId = serviceApppointmentByAssignment.get( assignmentId ),
							AccessLevel = 'Edit',
							RowCause = 'Manual',
							UserOrGroupId = userByAssignment.get( assignmentId )
							) );
		}
		insert shares;
	}

	public static void removeAccessForSpecificUsers( Map<Id, Id > serviceApppointmentByAssignment, Map<Id, Id> userByAssignment ) {
		String soqlQuery = 'SELECT Id FROM ServiceAppointmentShare WHERE RowCause =\'Manual\' AND (';
		for ( Id assignmentId:serviceApppointmentByAssignment.keySet() ) {
			Id userId = userByAssignment.get( assignmentId );
			Id serviceAppointmentId = serviceApppointmentByAssignment.get( assignmentId );
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
}
