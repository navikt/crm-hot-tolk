public without sharing class HOT_CreateServiceConnection {

	@AuraEnabled(cacheable = true)
    public static void createServiceConnection(String appointmentNumber) {
		Id userId = UserInfo.getUserId();
		ServiceResource serviceResource = [SELECT Id FROM ServiceResource WHERE RelatedRecordId=:userId];
		ServiceAppointment serviceAppointment = [SELECT Id FROM ServiceAppointment WHERE AppointmentNumber=:appointmentNumber];
		
		//If condition: 0 = length: [SELECT Id FROM HOT_InterestedResource__c WHERE ServiceAppointmentId=:serviceAppointment.Id AND ServiceResourceId=:serviceResource.Id]

		//HOT_InterestedResource__c interestedResource = new HOT_InterestedResource__c(ServiceAppointmentId=serviceAppointment.Id, ServiceResourceId=serviceResource.Id);
		//insert interestedResource;
    }
}
