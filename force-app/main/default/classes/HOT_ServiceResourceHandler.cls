public without sharing class HOT_ServiceResourceHandler {

	public static void createServiceResource(List<String> personIdents, Boolean addAllSkills, String serviceTerritoryDeveloperName){
		List<User> users = [SELECT Id, Name, ProfileId FROM User WHERE Account.INT_PersonIdent__c IN :personIdents];
		createServiceResource(users, addAllSkills, serviceTerritoryDeveloperName);
	}
	public static void createServiceResource(List<String> personIdents){
		createServiceResource(personIdents, false, null);
	}
	@Future
	public static void createServiceResourceFuture(List<Id> userIds) {
		List<User> users = [SELECT Id, Name, ProfileId FROM User WHERE Id IN :userIds];
		createServiceResource(users, false, null);	
    }

	public static void createServiceResource(List<User> users, Boolean addAllSkills, String serviceTerritoryDeveloperName) {
		users = removeUsersWithServiceResource(users);
		DefaultCommunityProfile__c defaultCommunityProfiles = DefaultCommunityProfile__c.getOrgDefaults();
		String profileName =  defaultCommunityProfiles.DefaultCommunityPlusProfile__c;
		Id freelanceProfileId = [SELECT Id FROM Profile WHERE Name = :profileName].Id;
        List<ServiceResource> serviceResources = new List<ServiceResource>();
        for(User user:users){
			Boolean isFreelance = user.ProfileId == freelanceProfileId;
            ServiceResource serviceResource = new ServiceResource();
            serviceResource.RelatedRecordId = Test.isRunningTest() ? UserInfo.getUserId() : user.Id;
            serviceResource.Name = user.Name;
            serviceResource.ResourceType = 'T';
			serviceResource.IsActive = true;
            serviceResource.HOT_IsEmployedInterpreter__c = !isFreelance;
            serviceResource.HOT_IsFreelanceInterpreter__c = isFreelance;
			if(Test.isRunningTest()){ serviceResource.put('FSL__GanttLabel__c', isFreelance ? 'Frilanstolk' : ''); }

            serviceResources.add(serviceResource);
		}
        insert serviceResources;

		Datetime startDate = Datetime.valueOf('2018-01-01 00:00:00');
		if(addAllSkills){
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
		if(serviceTerritoryDeveloperName != null){
			Id serviceTerritoryId = [SELECT Id FROM ServiceTerritory WHERE HOT_DeveloperName__c = :serviceTerritoryDeveloperName].Id;
			List<ServiceTerritoryMember> serviceTerritoryMembers = new List<ServiceTerritoryMember>();
			for(ServiceResource serviceResource:serviceResources){
				ServiceTerritoryMember serviceTerritoryMember = new ServiceTerritoryMember();
				serviceTerritoryMember.ServiceResourceId = serviceResource.Id;
				serviceTerritoryMember.ServiceTerritoryId = serviceTerritoryId;
				serviceTerritoryMember.EffectiveStartDate = startDate;
				serviceTerritoryMembers.add(serviceTerritoryMember);
			}
			insert serviceTerritoryMembers;
		}
        
	}

	static List<User> removeUsersWithServiceResource(List<User> users){
		List<User> filteredUsers = new List<User>();
		List<Id> userIds = new List<Id>();
		for(User user:users){
			userIds.add(user.Id);
		}
		
		List<Id> userIdsWithExistingServiceResources = new List<Id>();
		for(ServiceResource serviceResource:[SELECT RelatedRecordId FROM ServiceResource WHERE RelatedRecordId IN :userIds]){
			userIdsWithExistingServiceResources.add(serviceResource.RelatedRecordId);
		}

		for(User user : users){
			if(!userIdsWithExistingServiceResources.contains(user.Id)){
				filteredUsers.add(user);
			}
		}
		return filteredUsers;
	}
}
