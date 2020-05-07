public with sharing class HOT_getServiceResource {

	@AuraEnabled(cacheable = true)
    public static ServiceResource getServiceResource() {
		ServiceResource serviceResource = [SELECT Id, Name, ResourceType, IsActive, 
		(SELECT Id, ServiceTerritoryId FROM ServiceResource.ServiceTerritories)
		FROM ServiceResource WHERE RelatedRecordId =: UserInfo.getUserId()];
		return serviceResource;
    }
}
