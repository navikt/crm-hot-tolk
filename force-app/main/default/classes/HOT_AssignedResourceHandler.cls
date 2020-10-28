public without sharing class HOT_AssignedResourceHandler extends MyTriggers{
	
	public override void onBeforeInsert(){
		updateServiceTerritoryOnServiceAppointment((List<AssignedResource>) records);
	}
	public override void onBeforeUpdate(Map<Id, sObject> triggerOldMap){
		updateServiceTerritoryOnServiceAppointment((List<AssignedResource>) records);
	}


	public override void onAfterInsert(){
		List<ServiceAppointment> serviceAppointments = setServiceResourceFieldsOnServiceAppointment((List<AssignedResource>) records);
		update serviceAppointments;
		List<HOT_InterestedResource__c> interestedResource = createInterestedResources((List<AssignedResource>) records);
		insert interestedResource;
	}

	public override void onAfterUpdate(Map<Id, sObject> triggerOldMap){
		List<ServiceAppointment> serviceAppointments = setServiceResourceFieldsOnServiceAppointment((List<AssignedResource>) records);
		update serviceAppointments;
		List<HOT_InterestedResource__c> interestedResource = createInterestedResources((List<AssignedResource>) records);
		insert interestedResource;
	}
	
	public List<ServiceAppointment> setServiceResourceFieldsOnServiceAppointment(List<AssignedResource> records){

		//Creates Map and List for SOQL and reference later
		Map<Id, AssignedResource> assignedResourceByServiceAppointmentId= new Map<Id, AssignedResource>();
		List<Id> serviceResourceIds= new List<Id>();
		for ( AssignedResource ar:(List<AssignedResource>) records ) {
			assignedResourceByServiceAppointmentId.put(ar.ServiceAppointmentId, ar);
			serviceResourceIds.add(ar.ServiceResourceId);
		}

		//Fetches ServiceAppointments to be updated and userId of the ServiceResources
		List<ServiceAppointment> serviceAppointments = [SELECT Id, HOT_AssignedResourceId__c, HOT_ServiceResource__c FROM ServiceAppointment WHERE Id IN :assignedResourceByServiceAppointmentId.keySet()];
		Map<Id, ServiceResource> serviceResourceById = new Map<Id, ServiceResource>([SELECT Id, RelatedRecordId, Name FROM ServiceResource WHERE Id IN :serviceResourceIds]);


		//Setting fields on ServiceAppointment
		for(ServiceAppointment sa:serviceAppointments){
			Id serviceResourceId = assignedResourceByServiceAppointmentId.get(sa.Id).ServiceResourceId;
			sa.HOT_ServiceResource__c = serviceResourceId;
			sa.HOT_AssignedResourceId__c = serviceResourceById.get(serviceResourceId).RelatedRecordId;
		}
		return serviceAppointments;
	}

	public override void onAfterDelete(){
		List<Id> serviceAppointmentIds= new List<Id>();
		for ( AssignedResource ar:(List<AssignedResource>) records ) {
			serviceAppointmentIds.add(ar.ServiceAppointmentId);
		}
		List<ServiceAppointment> serviceAppointments = [SELECT Id, HOT_AssignedResourceId__c, HOT_ServiceResource__c, EarliestStartTime, DueDate, SchedStartTime, SchedEndTime FROM ServiceAppointment WHERE Id IN :serviceAppointmentIds];
		
		for(ServiceAppointment sa:serviceAppointments){
			sa.HOT_ServiceResource__c = null;
			sa.HOT_AssignedResourceId__c = null;
			sa.SchedStartTime = sa.EarliestStartTime;
			sa.SchedEndTime = sa.DueDate;
		}
		update serviceAppointments;
	}

	List<HOT_InterestedResource__c> createInterestedResources(List<AssignedResource> records){
		List<HOT_InterestedResource__c> interestedResources = new List<HOT_InterestedResource__c>();

		//Creates map to be used in query of InterestedResources
		Map<Id, Id> serviceResourceIdByServiceAppointmentId = new Map<Id, Id>();
		for(AssignedResource assignedResource : records){
			serviceResourceIdByServiceAppointmentId.put(assignedResource.ServiceAppointmentId, assignedResource.ServiceResourceId);
		}
		//Fetches possible matches with Interested Resources
		List<HOT_InterestedResource__c> existingInterestedResources = [SELECT Id, ServiceAppointment__c, ServiceResource__c FROM HOT_InterestedResource__c 
																	   WHERE ServiceAppointment__c IN :serviceResourceIdByServiceAppointmentId.keySet()
																	   AND ServiceResource__c IN :serviceResourceIdByServiceAppointmentId.values()];
		//Fetches Freelance interpreters included in the assigned resource records, and gets their Ids
		List<ServiceResource> serviceResources = [SELECT Id FROM ServiceResource WHERE Id IN :serviceResourceIdByServiceAppointmentId.values() AND HOT_IsFreelanceInterpreter__c = true];
		List<Id> freelanceResourceIds = new List<Id>();
		for(ServiceResource serviceResource:serviceResources){
			freelanceResourceIds.add(serviceResource.Id);
		}

		//Runs through all AR records, and if the ServiceResource is a freelance interpreter, runs through the Interested Resources and checks for matches on SA and SR
		//If there is no match, an IR should be created.
		for(AssignedResource assignedResource : records){
			if(freelanceResourceIds.contains(assignedResource.ServiceResourceId)){
				Boolean shouldCreateInterestedResource = true;
				for(HOT_InterestedResource__c interestedResource:existingInterestedResources){
					if(assignedResource.ServiceAppointmentId == interestedResource.ServiceAppointment__c && assignedResource.ServiceResourceId == interestedResource.ServiceResource__c){
						shouldCreateInterestedResource = false;
						break;
					}
				}
				if(shouldCreateInterestedResource){
					HOT_InterestedResource__c interestedResource = new HOT_InterestedResource__c();
					interestedResource.ServiceAppointment__c = assignedResource.ServiceAppointmentId;
					interestedResource.ServiceResource__c = assignedResource.ServiceResourceId;
					interestedResources.add(interestedResource);
				}
			}
		}
		return interestedResources;
	}

	public static void updateServiceTerritoryOnServiceAppointment(List<AssignedResource> assignedResources){
		List<Id> serviceAppointmentIds = new List<Id>();
		List<Id> serviceResourceIds = new List<Id>();
		for(AssignedResource assignedResource:assignedResources){
			serviceAppointmentIds.add(assignedResource.ServiceAppointmentId);
			serviceResourceIds.add(assignedResource.ServiceResourceId);
		}
		Map<Id, ServiceAppointment> serviceAppointments = new Map<Id, ServiceAppointment>([SELECT Id, ServiceTerritoryId FROM ServiceAppointment WHERE Id IN :serviceAppointmentIds]);
		Map<Id, ServiceResource> serviceResources = new Map<Id, ServiceResource>([SELECT Id, HOT_ServiceTerritory__r.Id FROM ServiceResource WHERE Id IN :serviceResourceIds]);

		List<ServiceAppointment> serviceAppointmentsToUpdate = new List<ServiceAppointment>();
		for(AssignedResource assignedResource:assignedResources){
			if(serviceAppointments.get(assignedResource.ServiceAppointmentId).ServiceTerritoryId != serviceResources.get(assignedResource.ServiceResourceId).HOT_ServiceTerritory__r.Id){
				serviceAppointments.get(assignedResource.ServiceAppointmentId).ServiceTerritoryId = serviceResources.get(assignedResource.ServiceResourceId).HOT_ServiceTerritory__c;
				serviceAppointmentsToUpdate.add(serviceAppointments.get(assignedResource.ServiceAppointmentId));
			}
		}
		update serviceAppointmentsToUpdate;
	}
	


}
