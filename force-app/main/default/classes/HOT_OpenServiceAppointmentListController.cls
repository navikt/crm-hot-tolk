
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

		List<ServiceAppointment> serviceAppointments = [SELECT AppointmentNumber, ServiceTerritoryId,
		EarliestStartTime, DueDate, 
		Address, HOT_InterpretationStreet__c, HOT_InterpretationPostalCode__c,
		HOT_WorkTypeName__c, HOT_NumberOfInterestedResources__c, WorkType.Id
		FROM ServiceAppointment 
		//WHERE Frilans_Tolk__c =:true AND Status =: 'Open'
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

