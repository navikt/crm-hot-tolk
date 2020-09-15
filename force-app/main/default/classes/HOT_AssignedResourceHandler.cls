public without sharing class HOT_AssignedResourceHandler extends MyTriggers{
	
	public override void onAfterInsert(){
		List<ServiceAppointment> serviceAppointments = setServiceResourceFieldsOnServiceAppointment((List<AssignedResource>) records);
		update serviceAppointments;
	}

	public override void onAfterUpdate(Map<Id, sObject> triggerOldMap){
		List<ServiceAppointment> serviceAppointments = setServiceResourceFieldsOnServiceAppointment((List<AssignedResource>) records);
		update serviceAppointments;
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
		List<ServiceAppointment> serviceAppointments = [SELECT Id, HOT_AssignedResourceId__c, HOT_ServiceResource__c FROM ServiceAppointment WHERE Id IN :serviceAppointmentIds];
		
		for(ServiceAppointment sa:serviceAppointments){
			sa.HOT_ServiceResource__c = null;
			sa.HOT_AssignedResourceId__c = null;
		}
		update serviceAppointments;
	}
}
