
public without sharing class HOT_OpenServiceAppointmentListController {
	
	@AuraEnabled(cacheable = true)
	public static List<ServiceAppointment> getOpenServiceAppointments() {
		
		Id userId = UserInfo.getUserId();
		List<ServiceResource> serviceResource = [SELECT Id FROM ServiceResource WHERE RelatedRecordId=:userId];
		List<ServiceResourceSkill> serviceResourceSkills = [SELECT SkillId FROM ServiceResourceSkill WHERE ServiceResourceId IN: serviceResource];
		List<Id> mySkillIds = new List<Id>();
		for(ServiceResourceSkill SRSkill:serviceResourceSkills){
			mySkillIds.add(SRSkill.SkillId);
		}
		List<Skill> mySkills = [SELECT Id, MasterLabel FROM Skill WHERE Id IN: mySkillIds];

		List<ServiceAppointment> serviceAppointments = [SELECT Id, AppointmentNumber, ServiceTerritoryId,
		EarliestStartTime, DueDate, HOT_DeadlineDate__c,
		Address, HOT_InterpretationStreet__c, HOT_InterpretationPostalCode__c,
		HOT_WorkTypeName__c, HOT_NumberOfInterestedResources__c, WorkType.Id
		FROM ServiceAppointment 
		WHERE HOT_IsReleasedToFreelance__c =:true AND Status =: 'Ingen' AND HOT_DeadlineDate__c>=:DATE.TODAY()
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



	@AuraEnabled
    public static List<String> createInterestedResources(List<String> serviceAppointmentIds) {

		System.debug('createInterestedResources');
		Id userId = UserInfo.getUserId();
		ServiceResource serviceResource = [SELECT Id FROM ServiceResource WHERE RelatedRecordId=:userId];
		
		List<ServiceAppointment> serviceAppointments = [SELECT Id, AppointmentNumber,
		(SELECT Id, ServiceResource__c FROM ServiceAppointment.InterestedResources__r)
		FROM ServiceAppointment WHERE Id IN: serviceAppointmentIds];
		System.debug(serviceAppointments);

		List<HOT_InterestedResource__c> existingInterestedResources = [SELECT Id, ServiceAppointment__c FROM HOT_InterestedResource__c 
		WHERE ServiceResource__c =: serviceResource.Id];
		
		List<HOT_InterestedResource__c> interestedResources = new List<HOT_InterestedResource__c>();
		List<String> updatedServiceAppointmentNumbers = new List<String>();

		for(ServiceAppointment sa: serviceAppointments){
			Boolean isInterested=false;
			for(HOT_InterestedResource__c eir: existingInterestedResources){
				if(eir.ServiceAppointment__c == sa.Id){
					isInterested=true;	
				}
			}
			if(!isInterested){
				interestedResources.add(new HOT_InterestedResource__c(ServiceAppointment__c=sa.Id, ServiceResource__c=serviceResource.Id, Status__c='Interested'));
				updatedServiceAppointmentNumbers.add(sa.AppointmentNumber);
			}
		}

		if(interestedResources.size()>0){
			insert interestedResources;
		}	
		System.debug(updatedServiceAppointmentNumbers);
		return updatedServiceAppointmentNumbers;

    }
}

