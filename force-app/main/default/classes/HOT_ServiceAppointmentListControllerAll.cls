
public without sharing class HOT_ServiceAppointmentListControllerAll {
	
	@AuraEnabled(cacheable = true)
	public static List<ServiceAppointment> getAllServiceAppointments() {
		
		Id userId = UserInfo.getUserId();
		List<ServiceResource> serviceResource = [SELECT Id FROM ServiceResource WHERE RelatedRecordId=:userId];
		List<ServiceResourceSkill> serviceResourceSkills = [SELECT SkillId FROM ServiceResourceSkill WHERE ServiceResourceId IN: serviceResource];
		List<Id> ids = new List<Id>();
		for(ServiceResourceSkill SRSkill:serviceResourceSkills){
			ids.add(srskill.SkillId);
		}
		/*
		List<Skill> skills = [SELECT Id FROM Skill WHERE Id IN: ids];
		*/
		List<ServiceAppointment> serviceAppointments = [SELECT AppointmentNumber, ServiceTerritoryId,
		EarliestStartTime, DueDate, 
		Address, HOT_InterpretationStreet__c, HOT_InterpretationPostalCode__c,
		HOT_WorkTypeName__c, HOT_NumberOfInterestedResources__c
		, WorkType.Name //(SELECT Name FROM ServiceAppointment.WorkType)
		FROM ServiceAppointment 
		//WHERE Frilase_Tolk__c =:true AND Status =: 'Open'
		//WHERE WorkTypeId IN: ids
		ORDER BY EarliestStartTime ASC];

		return serviceAppointments;
	}

}

