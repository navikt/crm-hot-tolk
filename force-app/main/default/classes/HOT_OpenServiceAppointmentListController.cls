
public without sharing class HOT_OpenServiceAppointmentListController {
	
	@AuraEnabled(cacheable = true)
	public static List<ServiceAppointment> getOpenServiceAppointments() {
		
		//Getting the skills of the user --> ServiceResource
		Id userId = UserInfo.getUserId();
		List<ServiceResource> serviceResource = [SELECT Id, Name FROM ServiceResource WHERE RelatedRecordId=:userId];
		List<ServiceResourceSkill> serviceResourceSkills = [SELECT SkillId FROM ServiceResourceSkill WHERE ServiceResourceId IN: serviceResource];
		List<Id> mySkillIds = new List<Id>();
		for(ServiceResourceSkill SRSkill:serviceResourceSkills){
			mySkillIds.add(SRSkill.SkillId);
		}
		//List<Skill> mySkills = [SELECT Id, MasterLabel FROM Skill WHERE Id IN: mySkillIds];

		//Getting ServiceAppointments of interest
		List<HOT_InterestedResource__c> interestedResources = [SELECT ServiceAppointment__c
		FROM HOT_InterestedResource__c WHERE ServiceResource__c IN: serviceResource];
		List<Id> interestedServiceAppointmentIds = new List<Id>();
		for(HOT_InterestedResource__c ir:interestedResources){
			interestedServiceAppointmentIds.add(ir.ServiceAppointment__c);
		}

		//Getting ServiceAppointments, filtered by isRealeased, Status, 
		//and if the ServiceResource has already reported interest in the ServiceAppointment
		List<ServiceAppointment> serviceAppointments = [SELECT 
														Id, AppointmentNumber, ServiceTerritoryId,
		EarliestStartTime, DueDate, HOT_DeadlineDate__c,
														Address, HOT_InterpretationStreet__c, HOT_InterpretationPostalCode__c,
		HOT_WorkTypeName__c, HOT_NumberOfInterestedResources__c, WorkType.Id
														FROM ServiceAppointment 
		WHERE HOT_IsReleasedToFreelance__c =:true AND Status =: 'Ingen' AND HOT_DeadlineDate__c>=:DATE.TODAY()
														AND Id NOT IN: interestedServiceAppointmentIds
		ORDER BY EarliestStartTime ASC];

		//Getting the required Skills for each workType 
		Set<Id> workTypeIds = new Set<Id>();
		for(ServiceAppointment sa:serviceAppointments){
			workTypeIds.add(sa.WorkType.Id);
		}
		List<SkillRequirement> neededSkillRequirements = [SELECT SkillId, RelatedRecordId FROM SkillRequirement WHERE RelatedRecordId IN: workTypeIds];
		
		List<Id> neededSkillIds = new List<Id>();
		for(SkillRequirement req:neededSkillRequirements){
			neededSkillIds.add(req.SkillId);
		}
		List<Skill> neededSkills = [SELECT Id FROM Skill WHERE Id IN: neededSkillIds];
		
		//Removing the ServiceAppointments with needed skills the ServiceResource does not have
		List<ServiceAppointment> serviceAppointmentsFiltered = new List<ServiceAppointment>();
		for(ServiceAppointment sa:serviceAppointments){
			List<Id> subNeededSkillIds = new List<Id>();
			Integer n = 0;
			for(SkillRequirement sreq:neededSkillRequirements){
				if(sreq.RelatedRecordId == sa.WorkType.Id){
					subNeededSkillIds.add(sreq.SkillId);
					if(mySkillIds.contains(sreq.SkillId)){
					n++;
					}
				}
			}
			if(n ==subNeededSkillIds.size()){
				serviceAppointmentsFiltered.add(sa);
			}
		}
		return serviceAppointmentsFiltered;
	}

}

