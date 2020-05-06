
public without sharing class HOT_AllServiceAppointmentListController {
	
	@AuraEnabled(cacheable = true)
	public static List<ServiceAppointment> getAllServiceAppointments() {
		
		Id userId = UserInfo.getUserId();
		List<ServiceResource> serviceResource = [SELECT Id FROM ServiceResource WHERE RelatedRecordId=:userId];
		List<ServiceResourceSkill> serviceResourceSkills = [SELECT SkillId FROM ServiceResourceSkill WHERE ServiceResourceId IN: serviceResource];
		List<Id> mySkillIds = new List<Id>();
		for(ServiceResourceSkill SRSkill:serviceResourceSkills){
			mySkillIds.add(SRSkill.SkillId);
		}
		List<Skill> mySkills = [SELECT Id, MasterLabel FROM Skill WHERE Id IN: mySkillIds];

		List<ServiceAppointment> serviceAppointments = [SELECT AppointmentNumber, ServiceTerritoryId,
		EarliestStartTime, DueDate, 
		Address, HOT_InterpretationStreet__c, HOT_InterpretationPostalCode__c,
		HOT_WorkTypeName__c, HOT_NumberOfInterestedResources__c, WorkType.Id
		FROM ServiceAppointment 
		//WHERE Frilase_Tolk__c =:true AND Status =: 'Open'
		ORDER BY EarliestStartTime ASC];

		List<ServiceAppointment> serviceAppointmentsFiltered = new List<ServiceAppointment>();
		for(ServiceAppointment sa:serviceAppointments){
			List<SkillRequirement> neededSkillRequirements = [SELECT SkillId FROM SkillRequirement WHERE RelatedRecordId =: sa.WorkType.Id];
			List<Id> neededSkillIds = new List<Id>();
			for(SkillRequirement req:neededSkillRequirements){
				neededSkillIds.add(req.SkillId);
			}
			List<Skill> neededSkills = [SELECT Id, MasterLabel FROM Skill WHERE Id IN: neededSkillIds];
			Integer n = 0;
			for(Skill ns:neededSkills){
				if(mySkills.contains(ns)){
					n++;
				}
			}
			if(n==neededSkills.size()){
				serviceAppointmentsFiltered.add(sa);
			}
		}
		

		return serviceAppointmentsFiltered;
	}

}

