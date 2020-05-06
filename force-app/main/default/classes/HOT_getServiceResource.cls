public with sharing class HOT_getServiceResource {

	@AuraEnabled(cacheable = true)
    public static List<ServiceResource> getServiceResource() {
		List<ServiceResource> serviceResources = [SELECT Id, Name, ResourceType, IsActive, 
		(SELECT Id FROM ServiceResource.ServiceTerritories)
		FROM ServiceResource WHERE RelatedRecordId=:UserInfo.getUserId()];
		return serviceResources;
    }
}
