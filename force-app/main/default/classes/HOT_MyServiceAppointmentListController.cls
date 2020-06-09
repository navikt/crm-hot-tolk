public without sharing class HOT_MyServiceAppointmentListController {

	@AuraEnabled(cacheable = true)
	public static List<WorkOrderLineItem> getParentWorkOrderLineItems(){
		List<ServiceAppointment> serviceAppointments = [SELECT ParentRecordId FROM ServiceAppointment
		WHERE HOT_AssignedResourceId__c = :userinfo.getUserId()];
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
		List<ServiceAppointment> serviceAppointments = [SELECT AppointmentNumber, Subject, Status, ParentRecordId,
		HOT_AddressFormated__c, HOT_DateTimeFormated__c, HOT_AssignedResourceId__c, HOT_WorkTypeName__c,
		SchedStartTime, SchedEndTime, ActualEndTime, ActualStartTime,
		HOT_DegreeOfHearingAndVisualImpairment__c, HOT_HapticCommunication__c
		FROM ServiceAppointment 
		WHERE HOT_AssignedResourceId__c = :userinfo.getUserId()
		ORDER BY SchedStartTime ASC];
		return serviceAppointments;
	}

	
	@AuraEnabled(cacheable = true)
	public static Map<String, List<ServiceAppointmentHistory>> getMyServiceAppointmentFieldHistories() {
		List<String> Statuses = new List<String>{'Avbrutt', 'Fullført', 'Kan ikke fullføre'};
		List<ServiceAppointmentHistory> statusHistories = 
		[SELECT Id, ServiceAppointmentId, Field, CreatedById,
		CreatedDate, NewValue
		FROM ServiceAppointmentHistory 
		WHERE Field = 'Status'
		ORDER BY CreatedDate ASC];
		List<ServiceAppointmentHistory> termsOfAgreementHistories = 
		[SELECT Id, ServiceAppointmentId, Field, CreatedById,
		CreatedDate, NewValue
		FROM ServiceAppointmentHistory 
		WHERE Field = 'HOT_TermsOfAgreement__c'
		ORDER BY CreatedDate ASC];
		for(ServiceAppointmentHistory sah:statusHistories){
			if(!Statuses.contains((String)sah.NewValue)){
				statusHistories.remove(statusHistories.indexOf(sah));
			}
		}
		Map<String, List<ServiceAppointmentHistory>> history = new Map<String, List<ServiceAppointmentHistory>>();
		history.put('Status', statusHistories);
		history.put('HOT_TermsOfAgreement__c', termsOfAgreementHistories);
		return history;
	}
    
}
