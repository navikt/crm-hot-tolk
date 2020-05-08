public without sharing class HOT_CreateInterestedResources {

	@AuraEnabled
    public static void createInterestedResources(List<String> appointmentNumbers) {

		System.debug('createInterestedResources');
		Id userId = UserInfo.getUserId();
		ServiceResource serviceResource = [SELECT Id FROM ServiceResource WHERE RelatedRecordId=:userId];
		
		List<ServiceAppointment> serviceAppointments = [SELECT Id,
		(SELECT Id, ServiceResource__c FROM ServiceAppointment.InterestedResources__r)
		FROM ServiceAppointment WHERE AppointmentNumber IN: appointmentNumbers];
		System.debug(serviceAppointments);
		List<HOT_InterestedResource__c> interestedResources = new List<HOT_InterestedResource__c>();
		for(ServiceAppointment sa: serviceAppointments){
			List<HOT_InterestedResource__c> existingInterestedResources =
			[SELECT Id FROM HOT_InterestedResource__c WHERE ServiceResource__c =: serviceResource.Id AND ServiceAppointment__c=:sa.Id];	
			if(existingInterestedResources.size()==0){
				interestedResources.add(new HOT_InterestedResource__c(ServiceAppointment__c=sa.Id, ServiceResource__c=serviceResource.Id));
			}
		}

	if(interestedResources.size()>0){
		insert interestedResources;
	}		
    }
}
