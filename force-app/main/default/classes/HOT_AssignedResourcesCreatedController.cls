public without sharing class HOT_AssignedResourcesCreatedController {

	@InvocableMethod
    static public void updateInterestedResourceStatus(List<AssignedResource> assignedResource) {
		if(assignedResource.size() > 0){
			ServiceAppointment serviceAppointment = [SELECT Id FROM ServiceAppointment WHERE Id = :assignedResource[0].ServiceAppointmentId];
			List<HOT_InterestedResource__c> interestedResources = [SELECT Id, Status__c, ServiceResource__c 
																FROM HOT_InterestedResource__c
																WHERE ServiceAppointment__c = :serviceAppointment.Id];
			for(HOT_InterestedResource__c ir:interestedResources){
				if(ir.ServiceResource__c == assignedResource[0].ServiceResourceId){
					ir.Status__c = 'Assigned';
				}
				/*
				else if(ir.Status__c == 'Service Appointment Retracted'){
					//Do nothing
				}
				*/
				else{
					ir.Status__c = 'Not Assigned';
				}
			}
			update interestedResources;	
		}
    }
}
