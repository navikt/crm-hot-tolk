public without sharing class HOT_ServiceResourceHandler {
    //Opprette Tjenesteressurser for frilanstolker MED skills og territorier
    public static void createServiceResource(
        List<String> personIdents,
        Boolean addAllSkills,
        String serviceTerritoryDeveloperName
    ) {
        List<User> users = [
            SELECT Id, Name, FirstName, MiddleName, LastName, ProfileId, Department
            FROM User
            WHERE Account.INT_PersonIdent__c IN :personIdents
        ];
        createServiceResource(users, addAllSkills, serviceTerritoryDeveloperName);
    }

    //Oppdatere Tjenesteressurser for frilanstolker MED skills og territorier
    public static void updateServiceResource(
        List<String> personIdents,
        Boolean addAllSkills,
        String serviceTerritoryDeveloperName
    ) {
        List<User> users = [
            SELECT Id, Name, FirstName, MiddleName, LastName, ProfileId, Department
            FROM User
            WHERE Account.INT_PersonIdent__c IN :personIdents
        ];
        updateServiceResource(users, addAllSkills, serviceTerritoryDeveloperName);
    }

    //Opprette Tjenesteressurser for frilanstolker UTEN skills og territorier
    public static void createServiceResource(List<String> personIdents) {
        createServiceResource(personIdents, false, null);
    }

    //Oppdatere Tjenesteressurser for frilanstolker UTEN skills og territorier
    public static void updateServiceResource(List<String> personIdents) {
        updateServiceResource(personIdents, false, null);
    }

    //Oppretter Tjenesteressurser for Ansatt Tolker uten skills og territorier. Unngår DML-operation conflicts.
    //Kjøres fra User trigger onInsert
    @Future
    public static void createServiceResourceFuture(List<Id> userIds) {
        List<User> users = [
            SELECT Id, Name, FirstName, MiddleName, LastName, ProfileId, Department
            FROM User
            WHERE Id IN :userIds
        ];
        createServiceResource(users, true, 'AUTO');
    }

    //Oppdaterer Tjenesteressurser for Ansatt Tolker som har blitt satt tilbake til profilen. Unngår DML-operation conflicts.
    //Kjøres fra User trigger onAfterUpdate
    @Future
    public static void updateServiceResourceFuture(List<Id> userIds) {
        List<User> users = [
            SELECT Id, Name, FirstName, MiddleName, LastName, ProfileId, Department
            FROM User
            WHERE Id IN :userIds
        ];
        updateServiceResource(users, true, 'AUTO');
    }

    public class ServiceResourceRequest {
        @InvocableVariable(
            label='User Id'
            description='The user Id for the user we are creating the serivce resource for.'
        )
        public Id UserId;

        @InvocableVariable(
            label='Service Territory (Developer Name)'
            description='The name of the territory the user will operate in.'
        )
        public String ServiceTerritory;
    }

    public class ServiceResourceResponse {
        @InvocableVariable(
            label='Success'
            description='Will return boolean "True" if successful and boolean "False" if not successful.'
        )
        public Boolean Success = false;
        @InvocableVariable(label='Error Message' description='Will contain the error message if request failed.')
        public String ErrorMessage;
    }

    @InvocableMethod(
        label='Create Service Resource Invocable'
        description='Creates a service resource for freelance interpreters'
        category='HOT Tolketjeneste'
        iconName='slds:standard:service_resource'
    )
    public static List<ServiceResourceResponse> createServiceResourceInvocable(
        List<ServiceResourceRequest> serviceResourceRequest
    ) {
        ServiceResourceResponse serviceResourceResponse = new ServiceResourceResponse();
        List<ServiceResourceResponse> serviceResourceResponses = new List<ServiceResourceResponse>();
        Id userId = ServiceResourceRequest[0].UserId;
        String serviceTerritoryDeveloperName = serviceResourceRequest[0].ServiceTerritory;
        List<User> users = [
            SELECT Id, Name, FirstName, MiddleName, LastName, ProfileId, Department
            FROM User
            WHERE Id = :userId
        ];

        try {
            createServiceResource(users, true, serviceTerritoryDeveloperName);
            serviceResourceResponse.Success = true;
        } catch (Exception ex) {
            serviceResourceResponse.ErrorMessage =
                serviceResourceRequest[0].UserId +
                ' - ' +
                serviceResourceRequest[0].ServiceTerritory +
                ' - ' +
                ex.getMessage();
            serviceResourceResponses.add(serviceResourceResponse);
        }

        return serviceResourceResponses;
    }

    //Hovedmetode som oppretter Tjenesteressurser
    public static void createServiceResource(
        List<User> users,
        Boolean addAllSkills,
        String serviceTerritoryDeveloperName
    ) {
        users = removeUsersWithServiceResource(users);

        DefaultCommunityProfile__c defaultCommunityProfiles = DefaultCommunityProfile__c.getOrgDefaults();
        String profileName = defaultCommunityProfiles.DefaultCommunityPlusProfile__c;
        Id freelanceProfileId = [SELECT Id FROM Profile WHERE Name = :profileName].Id;

        Map<Id, String> departmentByUser = new Map<Id, String>();
        List<ServiceResource> serviceResources = new List<ServiceResource>();
        for (User user : users) {
            Boolean isFreelance = user.ProfileId == freelanceProfileId;
            ServiceResource serviceResource = new ServiceResource();
            serviceResource.RelatedRecordId = Test.isRunningTest() ? UserInfo.getUserId() : user.Id;
            serviceResource.Name = user.MiddleName != null
                ? (user.Firstname + ' ' + user.MiddleName + ' ' + user.LastName)
                : (user.Firstname + ' ' + user.LastName);
            serviceResource.ResourceType = 'T';
            serviceResource.IsActive = true;
            serviceResource.HOT_IsEmployedInterpreter__c = !isFreelance;
            serviceResource.HOT_IsFreelanceInterpreter__c = isFreelance;
            serviceResource.CRM_Domain__c = 'HOT';
            ServiceResource.CRM_Subdomain__c = 'Tolketjenesten';
            if (!Test.isRunningTest()) {
                serviceResource.put('FSL__GanttLabel__c', isFreelance ? 'Frilanstolk' : '');
            }

            serviceResources.add(serviceResource);
            departmentByUser.put(serviceResource.RelatedRecordId, Test.isRunningTest() ? '4718' : user.Department);
        }
        insert serviceResources;

        Datetime startDate = Datetime.valueOf('2018-01-01 00:00:00');
        if (addAllSkills) {
            List<Skill> skills = HOT_Utility.getSkills();
            List<ServiceResourceSkill> serviceResourceSkills = new List<ServiceResourceSkill>();
            for (ServiceResource serviceResource : serviceResources) {
                for (Skill skill : skills) {
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

        List<HOT_Resource__c> rList = new List<HOT_Resource__c>();
        for (ServiceResource sr : serviceResources) {
            HOT_Resource__c resource = new HOT_Resource__c();
            resource.Name = sr.Name;
            resource.Service_Resource__c = sr.Id;
            rList.add(resource);
        }
        insert rList;

        List<HOT_ResourceMember__c> rmList = new List<HOT_ResourceMember__c>();
        for (HOT_Resource__c resource : rList) {
            HOT_ResourceMember__c resourceMember = new HOT_ResourceMember__c();
            resourceMember.Resource__c = resource.Id;
            resourceMember.Service_Resource__c = resource.Service_Resource__c;
            rmList.add(resourceMember);
        }
        insert rmList;

        //Oppretter ServiceTerritoryMember basert på serviceResource.User.Department
        if (serviceTerritoryDeveloperName == 'AUTO') {
            //Kobling mellom ServiceTerritory Developer name og Id
            Map<String, Id> serviceTerritoryIdByDeveloperName = new Map<String, Id>();
            List<ServiceTerritory> serviceTerritories = [SELECT Id, HOT_DeveloperName__c FROM ServiceTerritory];
            for (ServiceTerritory st : serviceTerritories) {
                serviceTerritoryIdByDeveloperName.put(st.HOT_DeveloperName__c, st.Id);
            }

            //Kobling mellom ServiceTerritory.DeveloperName og Avdeling
            List<HOT_ServiceTerritoryByQueue__mdt> serviceTerritoryByQueueList = [
                SELECT Queue__c, ServiceTerritory__c
                FROM HOT_ServiceTerritoryByQueue__mdt
            ];
            Map<String, Id> serviceTerritoryByDepartment = new Map<String, Id>();
            for (HOT_ServiceTerritoryByQueue__mdt stq : serviceTerritoryByQueueList) {
                String department = stq.Queue__c.removeStart('queue_');
                if (serviceTerritoryIdByDeveloperName.get(stq.ServiceTerritory__c) != null) {
                    serviceTerritoryByDepartment.put(
                        department,
                        serviceTerritoryIdByDeveloperName.get(stq.ServiceTerritory__c)
                    );
                }
            }

            //Oppretter ServiceTerritoryMember
            List<ServiceTerritoryMember> serviceTerritoryMembers = new List<ServiceTerritoryMember>();
            System.debug(departmentByUser);
            for (ServiceResource serviceResource : serviceResources) {
                System.debug(serviceResource.RelatedRecordId);
                System.debug(departmentByUser.get(serviceResource.RelatedRecordId));
                System.debug(serviceTerritoryByDepartment.get(departmentByUser.get(serviceResource.RelatedRecordId)));
                if (serviceTerritoryByDepartment.get(departmentByUser.get(serviceResource.RelatedRecordId)) != null) {
                    ServiceTerritoryMember serviceTerritoryMember = new ServiceTerritoryMember();
                    serviceTerritoryMember.ServiceResourceId = serviceResource.Id;
                    serviceTerritoryMember.ServiceTerritoryId = serviceTerritoryByDepartment.get(
                        departmentByUser.get(serviceResource.RelatedRecordId)
                    );
                    serviceTerritoryMember.EffectiveStartDate = startDate;
                    serviceTerritoryMembers.add(serviceTerritoryMember);
                }
            }
            insert serviceTerritoryMembers;
        } else if (serviceTerritoryDeveloperName != null) {
            Id serviceTerritoryId = [
                SELECT Id
                FROM ServiceTerritory
                WHERE HOT_DeveloperName__c = :serviceTerritoryDeveloperName
            ]
            .Id;
            List<ServiceTerritoryMember> serviceTerritoryMembers = new List<ServiceTerritoryMember>();
            for (ServiceResource serviceResource : serviceResources) {
                ServiceTerritoryMember serviceTerritoryMember = new ServiceTerritoryMember();
                serviceTerritoryMember.ServiceResourceId = serviceResource.Id;
                serviceTerritoryMember.ServiceTerritoryId = serviceTerritoryId;
                serviceTerritoryMember.EffectiveStartDate = startDate;
                serviceTerritoryMembers.add(serviceTerritoryMember);
            }
            insert serviceTerritoryMembers;
        }
    }

    //Hovedmetode som oppdaterer Tjenesteressurser
    public static void updateServiceResource(
        List<User> users,
        Boolean addAllSkills,
        String serviceTerritoryDeveloperName
    ) {
        Map<string,serviceResource> userServiceMap = new Map<string,serviceResource>();
        List<ServiceResource> insertServiceList = new List<ServiceResource>();
        List<ServiceResource> updateServiceList = new List<ServiceResource>();
        userServiceMap = checkUsersWithServiceResource(users);

        DefaultCommunityProfile__c defaultCommunityProfiles = DefaultCommunityProfile__c.getOrgDefaults();
        String profileName = defaultCommunityProfiles.DefaultCommunityPlusProfile__c;
        Id freelanceProfileId = [SELECT Id FROM Profile WHERE Name = :profileName].Id;

        Map<Id, String> departmentByUser = new Map<Id, String>();
        for (User user : users) {
            ServiceResource serviceResource = new ServiceResource();
            //Check if the user has a status in the map ( blank = new, True = exist and active, False = exist and inactive)  
            if (userServiceMap.containsKey(user.id)){
                ServiceResource oldServiceResource = userServiceMap.get(user.Id);
                if (oldServiceResource.IsActive == True ){
                    //Do nothing
                    return;
                } else if (oldServiceResource.IsActive == False ){
                    serviceResource.id = oldServiceResource.id;
                    serviceResource.IsActive = true;
                    updateServiceList.add(serviceResource);
                }
            } else {
                Boolean isFreelance = user.ProfileId == freelanceProfileId;
                serviceResource.RelatedRecordId = Test.isRunningTest() ? UserInfo.getUserId() : user.Id;
                serviceResource.Name = user.MiddleName != null
                    ? (user.Firstname + ' ' + user.MiddleName + ' ' + user.LastName)
                    : (user.Firstname + ' ' + user.LastName);
                serviceResource.ResourceType = 'T';
                serviceResource.IsActive = true;
                serviceResource.HOT_IsEmployedInterpreter__c = !isFreelance;
                serviceResource.HOT_IsFreelanceInterpreter__c = isFreelance;
                serviceResource.CRM_Domain__c = 'HOT';
                ServiceResource.CRM_Subdomain__c = 'Tolketjenesten';
                if (!Test.isRunningTest()) {
                    serviceResource.put('FSL__GanttLabel__c', isFreelance ? 'Frilanstolk' : '');
                }

                insertServiceList.add(serviceResource);
                departmentByUser.put(serviceResource.RelatedRecordId, Test.isRunningTest() ? '4718' : user.Department);
            } 
        }

        if (insertServiceList.size() > 0){
            insert insertServiceList;

            Datetime startDate = Datetime.valueOf('2018-01-01 00:00:00');
            if (addAllSkills) {
                List<Skill> skills = HOT_Utility.getSkills();
                List<ServiceResourceSkill> serviceResourceSkills = new List<ServiceResourceSkill>();
                for (ServiceResource serviceResource : insertServiceList) {
                    for (Skill skill : skills) {
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

            List<HOT_Resource__c> rList = new List<HOT_Resource__c>();
            for (ServiceResource sr : insertServiceList) {
                HOT_Resource__c resource = new HOT_Resource__c();
                resource.Name = sr.Name;
                resource.Service_Resource__c = sr.Id;
                rList.add(resource);
            }
            insert rList;

            List<HOT_ResourceMember__c> rmList = new List<HOT_ResourceMember__c>();
            for (HOT_Resource__c resource : rList) {
                HOT_ResourceMember__c resourceMember = new HOT_ResourceMember__c();
                resourceMember.Resource__c = resource.Id;
                resourceMember.Service_Resource__c = resource.Service_Resource__c;
                rmList.add(resourceMember);
            }
            insert rmList;

            //Oppretter ServiceTerritoryMember basert på serviceResource.User.Department
            if (serviceTerritoryDeveloperName == 'AUTO') {
                //Kobling mellom ServiceTerritory Developer name og Id
                Map<String, Id> serviceTerritoryIdByDeveloperName = new Map<String, Id>();
                List<ServiceTerritory> serviceTerritories = [SELECT Id, HOT_DeveloperName__c FROM ServiceTerritory];
                for (ServiceTerritory st : serviceTerritories) {
                    serviceTerritoryIdByDeveloperName.put(st.HOT_DeveloperName__c, st.Id);
                }

                //Kobling mellom ServiceTerritory.DeveloperName og Avdeling
                List<HOT_ServiceTerritoryByQueue__mdt> serviceTerritoryByQueueList = [
                    SELECT Queue__c, ServiceTerritory__c
                    FROM HOT_ServiceTerritoryByQueue__mdt
                ];
                Map<String, Id> serviceTerritoryByDepartment = new Map<String, Id>();
                for (HOT_ServiceTerritoryByQueue__mdt stq : serviceTerritoryByQueueList) {
                    String department = stq.Queue__c.removeStart('queue_');
                    if (serviceTerritoryIdByDeveloperName.get(stq.ServiceTerritory__c) != null) {
                        serviceTerritoryByDepartment.put(
                            department,
                            serviceTerritoryIdByDeveloperName.get(stq.ServiceTerritory__c)
                        );
                    }
                }

                //Oppretter ServiceTerritoryMember
                List<ServiceTerritoryMember> serviceTerritoryMembers = new List<ServiceTerritoryMember>();
                System.debug(departmentByUser);
                for (ServiceResource serviceResource : insertServiceList) {
                    System.debug(serviceResource.RelatedRecordId);
                    System.debug(departmentByUser.get(serviceResource.RelatedRecordId));
                    System.debug(serviceTerritoryByDepartment.get(departmentByUser.get(serviceResource.RelatedRecordId)));
                    if (serviceTerritoryByDepartment.get(departmentByUser.get(serviceResource.RelatedRecordId)) != null) {
                        ServiceTerritoryMember serviceTerritoryMember = new ServiceTerritoryMember();
                        serviceTerritoryMember.ServiceResourceId = serviceResource.Id;
                        serviceTerritoryMember.ServiceTerritoryId = serviceTerritoryByDepartment.get(
                            departmentByUser.get(serviceResource.RelatedRecordId)
                        );
                        serviceTerritoryMember.EffectiveStartDate = startDate;
                        serviceTerritoryMembers.add(serviceTerritoryMember);
                    }
                }
                insert serviceTerritoryMembers;
            } else if (serviceTerritoryDeveloperName != null) {
                Id serviceTerritoryId = [
                    SELECT Id
                    FROM ServiceTerritory
                    WHERE HOT_DeveloperName__c = :serviceTerritoryDeveloperName
                ]
                .Id;
                List<ServiceTerritoryMember> serviceTerritoryMembers = new List<ServiceTerritoryMember>();
                for (ServiceResource serviceResource : insertServiceList) {
                    ServiceTerritoryMember serviceTerritoryMember = new ServiceTerritoryMember();
                    serviceTerritoryMember.ServiceResourceId = serviceResource.Id;
                    serviceTerritoryMember.ServiceTerritoryId = serviceTerritoryId;
                    serviceTerritoryMember.EffectiveStartDate = startDate;
                    serviceTerritoryMembers.add(serviceTerritoryMember);
                }
                insert serviceTerritoryMembers;
            }
        }

        if (updateServiceList.size() > 0){
            update updateServiceList;
        }   
    }

    //Filtrerer ut brukere som allerede har en Tjenesteressurs koblet til dem
    static List<User> removeUsersWithServiceResource(List<User> users) {
        List<User> filteredUsers = new List<User>();
        List<Id> userIds = new List<Id>();
        for (User user : users) {
            userIds.add(user.Id);
        }

        List<Id> userIdsWithExistingServiceResources = new List<Id>();
        for (ServiceResource serviceResource : [
            SELECT RelatedRecordId
            FROM ServiceResource
            WHERE RelatedRecordId IN :userIds
        ]) {
            userIdsWithExistingServiceResources.add(serviceResource.RelatedRecordId);
        }

        for (User user : users) {
            if (!userIdsWithExistingServiceResources.contains(user.Id)) {
                filteredUsers.add(user);
            }
        }
        return filteredUsers;
    }

    //Sjekker om brukere allerede har en Tjenesteressurs koblet til dem
    static Map<string,serviceResource> checkUsersWithServiceResource(List<User> users) {
        Map<string,serviceResource> filteredUsers = new Map<string,serviceResource>();
        List<Id> userIds = new List<Id>();
        for (User user : users) {
            userIds.add(user.Id);
        }

        for (ServiceResource serviceResource : [
            SELECT RelatedRecordId, id, IsActive
            FROM ServiceResource
            WHERE RelatedRecordId IN :userIds
        ]) {
            filteredUsers.put(serviceResource.RelatedRecordId,serviceResource);
        }
        return filteredUsers;
    }
}
