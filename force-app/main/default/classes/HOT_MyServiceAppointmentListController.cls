public without sharing class HOT_MyServiceAppointmentListController {

	@AuraEnabled(cacheable = true)
	public static List<WorkOrderLineItem> getParentWorkOrderLineItems(){
		List<ServiceAppointment> serviceAppointments = [SELECT ParentRecordId FROM ServiceAppointment
		WHERE HOT_AssignedResourceId__c = :UserInfo.getUserId()];
		List<Id> parentRecordIds = new List<Id>();
		for(ServiceAppointment sa: serviceAppointments){
			parentRecordIds.add(sa.ParentRecordId);
		}
		List<WorkOrderLineItem> workOrderLineItems = [SELECT Id, WorkOrder.HOT_Request__r.AssignmentType__c 
		FROM WorkOrderLineItem WHERE Id IN :parentRecordIds];
		return workOrderLineItems;
	}

	
	@AuraEnabled(cacheable = true)
	public static List<ServiceAppointment> getMyServiceAppointments() {
		ServiceResource serviceResource = [SELECT Id, Name FROM ServiceResource WHERE RelatedRecordId=:UserInfo.getUserId()];
		List<AssignedResource> assignedResources = [SELECT ServiceAppointmentId, ServiceResourceId 
													FROM AssignedResource
													WHERE ServiceResourceId = :serviceResource.Id];
		List<Id> serviceAppointmentIds = new List<Id>();
		for(AssignedResource ar:assignedResources){
			serviceAppointmentIds.add(ar.ServiceAppointmentId);
		}
		List<ServiceAppointment> serviceAppointments = [
			SELECT AppointmentNumber, Subject, toLabel(Status), ParentRecordId,
				   HOT_AddressFormated__c, HOT_DateTimeFormated__c, HOT_AssignedResourceId__c, HOT_WorkTypeName__c,
				   SchedStartTime, SchedEndTime, ActualEndTime, ActualStartTime,
				   HOT_DegreeOfHearingAndVisualImpairment__c, HOT_HapticCommunication__c
			FROM ServiceAppointment 
			WHERE Id IN :serviceAppointmentIds
			ORDER BY SchedStartTime ASC];
		return serviceAppointments;
	}

	
	@AuraEnabled(cacheable = true)
	public static Map<String, List<ServiceAppointmentHistory>> getMyServiceAppointmentFieldHistories(Id serviceAppointmentId) {
		// TODO: fikse oversettelse hvis dette skal taes i bruk
		List<String> statusList = new List<String>{'Avbrutt', 'Fullført', 'Kan ikke fullføre'};
		List<ServiceAppointmentHistory> statusHistories = new List<ServiceAppointmentHistory>();
		List<ServiceAppointmentHistory> allStatusHistories = 
		[SELECT Id, ServiceAppointmentId, Field, CreatedById, CreatedDate, NewValue
		FROM ServiceAppointmentHistory WHERE ServiceAppointmentId = :serviceAppointmentId AND Field = 'Status' ORDER BY CreatedDate ASC];

		List<ServiceAppointmentHistory> termsOfAgreementHistories = [SELECT Id, ServiceAppointmentId, Field, CreatedById, CreatedDate, NewValue
																	 FROM ServiceAppointmentHistory 
																	 WHERE Field = 'HOT_TermsOfAgreement__c' 
																	 ORDER BY CreatedDate ASC];

		for(ServiceAppointmentHistory sah:allStatusHistories){
			if(!statusList.contains((String)sah.NewValue)){
				statusHistories.add(sah);
			}
		}
		Map<String, List<ServiceAppointmentHistory>> history = new Map<String, List<ServiceAppointmentHistory>>();
		history.put('Status', statusHistories);
		history.put('HOT_TermsOfAgreement__c', termsOfAgreementHistories);
		return history;
	}
    
}
