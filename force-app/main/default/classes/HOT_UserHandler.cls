public without sharing class HOT_UserHandler extends MyTriggers {
    
	public override void onAfterInsert(){
		List<User> usersToCreateServiceResourceFor = new List<User>();
		List<Id> userIds = new List<Id>();
		for(User user:(List<User>) records){
			userIds.add(user.Id);
		}
		
		List<Id> userIdsWithExistingServiceResources = new List<Id>();
		for(ServiceResource serviceResource:[SELECT RelatedRecordId FROM ServiceResource WHERE RelatedRecordId IN :userIds]){
			userIdsWithExistingServiceResources.add(serviceResource.RelatedRecordId);
		}

		for(User user : (List<User>) records){
			if(user.HOT_CreateServiceResource__c == true && !userIdsWithExistingServiceResources.contains(user.Id)){
				usersToCreateServiceResourceFor.add(user);
			}
		}
		createServiceResource(usersToCreateServiceResourceFor);
	}
	
	public override void onAfterUpdate(Map<Id, sObject> triggerOldMap){
		List<User> usersToCreateServiceResourceFor = new List<User>();
		List<Id> userIds = new List<Id>();
		for(User user:(List<User>) records){
			userIds.add(user.Id);
		}
		
		List<Id> userIdsWithExistingServiceResources = new List<Id>();
		for(ServiceResource serviceResource:[SELECT RelatedRecordId FROM ServiceResource WHERE RelatedRecordId IN :userIds]){
			userIdsWithExistingServiceResources.add(serviceResource.RelatedRecordId);
		}

		for(User user : (List<User>) records){
			if(user.HOT_CreateServiceResource__c == true && !userIdsWithExistingServiceResources.contains(user.Id) 
			&& triggerOldMap.get(user.Id).get('HOT_CreateServiceResource__c') != user.HOT_CreateServiceResource__c
			){
				usersToCreateServiceResourceFor.add(user);
			}
		}
		createServiceResource(usersToCreateServiceResourceFor);
	}

	public static void createServiceResource(List<User> users) {
		Id freelanceProfileId = [SELECT Id FROM Profile WHERE Name = 'NAV Samhandler' LIMIT 1].Id;
        List<ServiceResource> serviceResources = new List<ServiceResource>();
        for(User user:users){
			Boolean isFreelance = user.ProfileId == freelanceProfileId;
            ServiceResource serviceResource = new ServiceResource();
            serviceResource.RelatedRecordId = user.Id;
            serviceResource.Name = user.Name;
            serviceResource.ResourceType = 'T';
            serviceResource.IsActive = true;
            serviceResource.put('FSL__GanttLabel__c', isFreelance ? 'Frilanstolk' : '');
            serviceResource.HOT_IsEmployedInterpreter__c = !isFreelance;
            serviceResource.HOT_IsFreelanceInterpreter__c = isFreelance;

            serviceResources.add(serviceResource);
        }
        insert serviceResources;

        Datetime startDate = Datetime.valueOf('2018-01-01 00:00:00');
        List<Skill> skills = [SELECT Id FROM Skill];
        List<ServiceResourceSkill> serviceResourceSkills = new List<ServiceResourceSkill>();
        for(ServiceResource serviceResource:serviceResources){
            for(Skill skill:skills){
                ServiceResourceSkill serviceResourceSkill = new ServiceResourceSkill(
                    ServiceResourceId = serviceResource.Id,
                    SkillId = skill.Id,
                    EffectiveStartDate = startDate 
                );
                serviceResourceSkills.add(serviceResourceSkill);
            }
        }
        insert serviceResourceSkills;
    }
}
