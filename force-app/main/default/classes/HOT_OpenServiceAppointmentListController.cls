
public without sharing class HOT_OpenServiceAppointmentListController {
	
	@AuraEnabled(cacheable = true)
	public static List<ServiceAppointment> getOpenServiceAppointments() {
		
		//Getting the skills of the user --> ServiceResource
		Id userId = UserInfo.getUserId();
		List<ServiceResource> serviceResource = [SELECT Id, Name FROM ServiceResource WHERE RelatedRecordId=:userId];
		System.debug('serviceResource: ' + serviceResource);

		List<ServiceResourceSkill> serviceResourceSkills = [SELECT SkillId FROM ServiceResourceSkill WHERE ServiceResourceId IN: serviceResource];
		System.debug('serviceResourceSkills: ' + serviceResourceSkills);

		List<Id> mySkillIds = new List<Id>();
		for(ServiceResourceSkill SRSkill:serviceResourceSkills){
			mySkillIds.add(SRSkill.SkillId);
		}
		System.debug('mySkillIds: ' + mySkillIds);

		//List<Skill> mySkills = [SELECT Id, MasterLabel FROM Skill WHERE Id IN: mySkillIds];

		//Getting ServiceAppointments of interest
		List<HOT_InterestedResource__c> interestedResources = [SELECT ServiceAppointment__c
		FROM HOT_InterestedResource__c WHERE ServiceResource__c IN :serviceResource];
		List<Id> interestedServiceAppointmentIds = new List<Id>();
		for(HOT_InterestedResource__c ir:interestedResources){
			interestedServiceAppointmentIds.add(ir.ServiceAppointment__c);
		}
		System.debug('interestedServiceAppointmentIds: ' + interestedServiceAppointmentIds);

		//Getting ServiceAppointments, filtered by isRealeased, Status, 
		//and if the ServiceResource has already reported interest in the ServiceAppointment
		List<ServiceAppointment> serviceAppointments = [SELECT 
														Id, AppointmentNumber, ServiceTerritoryId, EarliestStartTime, DueDate, HOT_DeadlineDate__c, HOT_FreelanceSubject__c, HOT_AddressFormated__c,
														Address, HOT_InterpretationStreet__c, HOT_InterpretationPostalCode__c, HOT_WorkTypeName__c, HOT_NumberOfInterestedResources__c, WorkType.Id,
														ServiceTerritory.Name, ServiceTerritory.HOT_DeveloperName__c, HOT_ReleaseDate__c, City, Street, PostalCode
														FROM ServiceAppointment WHERE HOT_IsReleasedToFreelance__c = true AND Status = 'Released To Freelance' 
														AND HOT_DeadlineDate__c >= :DATE.TODAY() AND Id NOT IN: interestedServiceAppointmentIds
														ORDER BY HOT_ReleaseDate__c DESC];
		System.debug('serviceAppointments: ' + serviceAppointments);

		//Getting the required Skills for each workType 
		Set<Id> workTypeIds = new Set<Id>();
		for(ServiceAppointment sa:serviceAppointments){
			workTypeIds.add(sa.WorkType.Id);
		}
		System.debug('workTypeIds: ' + workTypeIds);

		List<SkillRequirement> neededSkillRequirements = [SELECT SkillId, RelatedRecordId FROM SkillRequirement WHERE RelatedRecordId IN: workTypeIds];
		System.debug('neededSkillRequirements: ' + neededSkillRequirements);

		List<Id> neededSkillIds = new List<Id>();
		for(SkillRequirement req:neededSkillRequirements){
			neededSkillIds.add(req.SkillId);
		}
		System.debug('neededSkillIds: ' + neededSkillIds);

		List<Skill> neededSkills = [SELECT Id FROM Skill WHERE Id IN: neededSkillIds];
		System.debug('neededSkills: ' + neededSkills);

		//Removing the ServiceAppointments with needed skills the ServiceResource does not have
		List<ServiceAppointment> serviceAppointmentsFiltered = new List<ServiceAppointment>();
		for(ServiceAppointment sa:serviceAppointments){
			List<Id> subNeededSkillIds = new List<Id>();
			Integer n = 0;
			for(SkillRequirement sreq:neededSkillRequirements){
				if(sreq.RelatedRecordId == sa.WorkType.Id){
					subNeededSkillIds.add(sreq.SkillId);
					if(!mySkillIds.contains(sreq.SkillId)){
					n++;
					}
				}
			}
			if(n == 0){
				serviceAppointmentsFiltered.add(sa);
			}
		}
		System.debug('serviceAppointmentsFiltered: ' + serviceAppointmentsFiltered);
		return serviceAppointmentsFiltered;
	}

	
	@AuraEnabled
	//public static void createInterestedResources(List<String> serviceAppointmentIds) {
	public static void createInterestedResources(List<String> serviceAppointmentIds, List<String> comments) {
			
		Id userId = UserInfo.getUserId();
		ServiceResource serviceResource = [SELECT Id FROM ServiceResource WHERE RelatedRecordId=:userId];
		List<HOT_InterestedResource__c> interestedResources = new List<Hot_InterestedResource__c>();
		for(Integer i = 0; i < serviceAppointmentIds.size(); i++){
			HOT_InterestedResource__c IR = new HOT_InterestedResource__c(ServiceAppointment__c = serviceAppointmentIds[i],
				ServiceResource__c = serviceResource.Id, Status__c = 'Interested');
			interestedResources.add(IR);
		}
		insert interestedResources;
		
		for(Integer i = 0; i < serviceAppointmentIds.size(); i++){
			HOT_InterestedResourcesListController.addComment(interestedResources[i].Id, comments[i]);
		}
	}

}

