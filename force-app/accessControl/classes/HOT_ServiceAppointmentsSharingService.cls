public with sharing class HOT_ServiceAppointmentsSharingService {

	public static void grantAccess( Map<Id, Set<Id> > usersByServiceAppointment ) {

		List<ServiceAppointmentShare> shares = new List<ServiceAppointmentShare>();
		for ( Id serviceAppointmentId:usersByServiceAppointment.keySet() ) {
			for ( Id userId:usersByServiceAppointment.get( serviceAppointmentId ) ) {
				shares.add( new ServiceAppointmentShare(
								ParentId = serviceAppointmentId,
								AccessLevel = 'Edit',
								RowCause = 'Manual',
								UserOrGroupId = userId
								) );
			}
		}
		insert shares;
	}

	public static void removeAccessForSpecificUsers( Map<Id, Set<Id> > usersByServiceAppointment ) {
		String soqlQuery = 'SELECT Id FROM ServiceAppointmentShare WHERE RowCause =\'Manual\' AND (';
		for ( Id serviceAppointmentId:usersByServiceAppointment.keySet() ) {


			for ( Id userId:usersByServiceAppointment.get( serviceAppointmentId ) ) {
				soqlQuery += ' (UserOrGroupId=:userId AND ParentId=:serviceAppointmentId) OR';
				System.assertEquals( 1, [SELECT count() FROM ServiceAppointmentShare WHERE RowCause = 'Manual' AND ParentId = : serviceAppointmentId AND UserOrGroupId = : userId] );
			}
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
