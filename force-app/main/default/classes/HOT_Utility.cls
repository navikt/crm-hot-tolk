public without sharing class HOT_Utility {
    @AuraEnabled(cacheable=true)
    public static ServiceResource getServiceResource() {
        ServiceResource serviceResource = [
            SELECT
                Id,
                Name,
                ResourceType,
                IsActive,
                RelatedRecordId,
                HOT_PreferredRegions__c,
                (SELECT Id, ServiceTerritoryId FROM ServiceResource.ServiceTerritories),
                HOT_ServiceTerritory__r.HOT_DeveloperName__c
            FROM ServiceResource
            WHERE RelatedRecordId = :UserInfo.getUserId()
        ];
        return serviceResource;
    }

    @AuraEnabled(cacheable=true)
    public static Boolean checkAssignedPermissionSet(String permissionSetName) {
        List<PermissionSetAssignment> permsets = [
            SELECT Id, Assignee.Name
            FROM PermissionSetAssignment
            WHERE AssigneeId = :Userinfo.getUserId() AND PermissionSet.Name = :permissionSetName
        ];
        //Or hotTolkFrilansGroup IN :PermissionSetGroup];
        return permsets.size() > 0;
    }

    @AuraEnabled(cacheable=true)
    public static Boolean checkAssignedPermissionSetGroup(String permissionSetGroupName) {
        List<PermissionSetAssignment> permsets = [
            SELECT Id, Assignee.Name
            FROM PermissionSetAssignment
            WHERE AssigneeId = :Userinfo.getUserId() AND PermissionSetGroup.DeveloperName = :permissionSetGroupName
        ];
        return permsets.size() > 0;
    }

    @AuraEnabled(cacheable=true)
    public static Map<Id, List<String>> getAssignedResources(List<Id> requestIds) {
        List<ServiceAppointment> serviceAppointments = [
            SELECT Id, HOT_ServiceResource__r.Name, HOT_Request__c
            FROM ServiceAppointment
            WHERE HOT_Request__r.Id IN :requestIds AND HOT_ServiceResource__c != NULL
        ];
        Map<Id, List<String>> requestIdToServiceResource = new Map<Id, List<String>>();
        for (Id id : requestIds) {
            List<String> serviceResources = new List<String>();
            for (ServiceAppointment sa : serviceAppointments) {
                if (sa.HOT_Request__c == id) {
                    serviceResources.add((String) sa.HOT_ServiceResource__r.Name);
                }
            }
            requestIdToServiceResource.put(id, serviceResources);
        }
        return requestIdToServiceResource;
    }

    @AuraEnabled(cacheable=true)
    public static User getPersonAccount() {
        User user = [
            SELECT AccountId, Account.CRM_Person__r.CRM_FullName__c, Account.CRM_Person__r.INT_KrrMobilePhone__c
            FROM User
            WHERE Id = :UserInfo.getUserId() AND Account.CRM_Person__r.INT_Confidential__C = 'UGRADERT'
        ];
        return user;
    }

    @AuraEnabled(cacheable=true)
    public static Boolean checkUserHasEntitlement() {
        User user = [SELECT Id, AccountId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        if (user.AccountId != null) {
            Person__c person = [
                SELECT Id, HOT_HasEntitlement__c
                FROM Person__c
                WHERE CRM_Account__c = :user.AccountId
                LIMIT 1
            ];
            return person.HOT_HasEntitlement__c;
        }
        return false;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, String> getOrdererDetails() {
        User user = [SELECT Id, AccountId FROM User WHERE Id = :UserInfo.getUserId()];

        //Metode 1
        List<HOT_Request__c> requests = [
            SELECT Id, OrdererEmail__c, OrdererPhone__c, CreatedDate
            FROM HOT_Request__c
            WHERE Orderer__c = :user.AccountId AND OrdererEmail__c != '' AND OrdererPhone__c != ''
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        Map<String, String> ordererDetails = new Map<String, String>();
        if (requests.size() > 0) {
            ordererDetails.put('OrdererEmail__c', String.valueOf(requests[0].OrdererEmail__c));
            ordererDetails.put('OrdererPhone__c', String.valueOf(requests[0].OrdererPhone__c));
        } else {
            ordererDetails.put('OrdererEmail__c', '');
            ordererDetails.put('OrdererPhone__c', '');
        }

        return ordererDetails;
    }

    public static Long getMinutesUntilNextSMSBatch() {
        Long minutes = 10;
        Datetime now = Datetime.now();
        Datetime datetime_1600 = Datetime.newInstance(Date.today(), Time.newInstance(16, 0, 0, 0));
        Boolean isWithinAnHour = datetime_1600.getTime() - Datetime.now().getTime() < 3600000;
        Boolean isWithinTenMin = datetime_1600.getTime() - Datetime.now().getTime() < 600000;
        Boolean isFriday = now.format('EEEE') == 'Friday';
        if (isWithinTenMin) {
            Datetime nextDay = Datetime.newInstance(now.addDays(1).date(), Time.newInstance(7, 0, 0, 0));
            minutes = (nextDay.getTime() - now.getTime()) / 60000;
            if (isFriday) {
                Datetime monday = Datetime.newInstance(now.addDays(3).date(), Time.newInstance(7, 0, 0, 0));
                minutes = (monday.getTime() - now.getTime()) / 60000;
            }
        } else if (isWithinAnHour) {
            minutes = (datetime_1600.getTime() - now.getTime()) / 60000;
        }
        return minutes;
    }

    public static Long getMinutesUntilNextReminderSMSBatch() {
        Long minutes = 60;
        Datetime now = Datetime.now();
        Datetime datetime_1600 = Datetime.newInstance(Date.today(), Time.newInstance(16, 0, 0, 0));
        Boolean isWithinAnHour = datetime_1600.getTime() - Datetime.now().getTime() < 3600000;
        Boolean isWithinTenMin = datetime_1600.getTime() - Datetime.now().getTime() < 600000;
        Boolean isFriday = now.format('EEEE') == 'Friday';
        if (isWithinTenMin) {
            Datetime nextDay = Datetime.newInstance(now.addDays(1).date(), Time.newInstance(7, 0, 0, 0));
            minutes = (nextDay.getTime() - now.getTime()) / 60000;
            if (isFriday) {
                Datetime monday = Datetime.newInstance(now.addDays(3).date(), Time.newInstance(7, 0, 0, 0));
                minutes = (monday.getTime() - now.getTime()) / 60000;
            }
        } else if (isWithinAnHour) {
            minutes = (datetime_1600.getTime() - now.getTime()) / 60000;
        }
        return minutes;
    }

    public static List<Skill> getSkills() {
        Map<String, String> skillMap = new Map<String, String>();
        skillMap.put('Haptisk_Kommunikasjon', 'Haptisk Kommunikasjon');
        skillMap.put('Skrivetolking', 'Skrivetolking');
        skillMap.put('Taktilt_Tegnsprak', 'Taktilt Tegnspråk');
        skillMap.put('Taletolking', 'Taletolking');
        skillMap.put('Tegn_Som_Stotte_Til_Munnavlesning', 'Tegn Som Støtte Til Munnavlesning');
        skillMap.put('Tegnsprak_I_Begrenset_Synsfelt', 'Tegnspråk I Begrenset Synsfelt');
        skillMap.put('Tegnspraktolk', 'Tegnspråktolk');
        return [SELECT Id, MasterLabel FROM Skill WHERE DeveloperName IN :skillMap.keySet()];
    }

    public static void setArchiveAsOwner(List<SObject> records) {
        Group archive = [SELECT Id FROM Group WHERE Type = 'Queue' AND Name = 'Hot Arkiv' LIMIT 1];
        for (SObject record : records) {
            record.put('OwnerId', archive.Id);
        }
    }
}
