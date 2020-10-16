public without sharing class HOT_ServiceResourceAccessHandler extends MyTriggers {
	
	public override void onAfterInsert() {
        grantAccess((List<ServiceResource>) records);
	}
	
	private void grantAccess(List<ServiceResource> serviceResources) {
        Map<Integer,Id> recordIdByIndex=getRecordIdByIndex(serviceResources);
        List<SobjectWrapper> sobjects = new List<SobjectWrapper>();
		Integer i=0;
		List<ServiceTerritoryMember> serviceTerritoryMembers = [SELECT Id, ServiceResourceId, ServiceTerritory.HOT_DeveloperName__c FROM ServiceTerritoryMember WHERE TerritoryType = 'P' AND ServiceResourceId IN :serviceResources];
		Map<Id, String> serviceTerritoryNameByServiceResourceIdMap = new Map<Id, String>();
		for(ServiceTerritoryMember serviceTerritoryMember : serviceTerritoryMembers) {
			serviceTerritoryNameByServiceResourceIdMap.put(serviceTerritoryMember.ServiceResourceId, serviceTerritoryMember.ServiceTerritory.HOT_DeveloperName__c);
		}
		List<ServiceResourceShare> shareRecords = new List<ServiceResourceShare>();
        for(ServiceResource serviceResource : serviceResources) {
            SobjectWrapper wrapper			= new SobjectWrapper();
            wrapper.recordIndex				= i;
			wrapper.serviceTerritoryName	= serviceTerritoryNameByServiceResourceIdMap.get(serviceResource.Id);
            sobjects.add(wrapper);
			i++;
			
			if(serviceResource.IsActive && serviceResource.RelatedRecordId != null && serviceResource.RelatedRecordId != serviceResource.OwnerId) {
				ServiceResourceShare serviceResourceShare = new ServiceResourceShare();
			
				serviceResourceShare.ParentId				= serviceResource.Id;
				serviceResourceShare.UserOrGroupId			= serviceResource.RelatedRecordId;
				serviceResourceShare.AccessLevel			= 'Edit';
				serviceResourceShare.RowCause 				= 'Manual';
				
				shareRecords.add(serviceResourceShare);
			}
        }
		
        List<ShareWrapper> shareWrappers = RecordShareService.grantAccess(sobjects, 'ServiceResource');
        for(ShareWrapper share : shareWrappers) {
			ServiceResourceShare serviceResourceShare = new ServiceResourceShare();
			
            serviceResourceShare.ParentId				= recordIdByIndex.get(share.recordIndex);
            serviceResourceShare.UserOrGroupId			= share.publicGroupId;
            serviceResourceShare.AccessLevel			= 'Read';
			serviceResourceShare.RowCause 				= 'Manual';
			
			shareRecords.add(serviceResourceShare);
        }
        insert shareRecords;
    }

    public override  void onAfterUpdate(Map<Id,sObject> triggerOldMap){
        List<String> fieldNamesToCheck = new String[]{'IsActive', 'HOT_ServiceTerritoryLastUpdated__c', 'OwnerId', 'RelatedRecordId'};
        List<Id> parentIdToDelete = new List<Id>();
        List<ServiceResource> serviceResourcesWithNewSharing = new List<ServiceResource>();

        for(ServiceResource serviceResource : (List<ServiceResource>) records) {
            ServiceResource oldServiceResource = (ServiceResource) triggerOldMap.get(serviceResource.Id);
            if(MyTriggers.hasChangedFields(fieldNamesToCheck,serviceResource,oldServiceResource)) {
                parentIdToDelete.add(serviceResource.Id);
            	serviceResourcesWithNewSharing.add(serviceResource);
            }
        }

        if(parentIdToDelete.size()>0){
            List<ServiceResourceShare> serviceResourceSharesToDelete = [SELECT Id FROM ServiceResourceShare WHERE RowCause='Manual' AND ParentId in:parentIdToDelete];
            delete serviceResourceSharesToDelete;
            grantAccess(serviceResourcesWithNewSharing);
        }
    }

    private Map<Integer,Id> getRecordIdByIndex(List<ServiceResource> serviceResources) {
        Map<Integer,Id> recordIdByIndex = new Map<Integer,Id>();
        Integer i=0;
        for(ServiceResource serviceResource : serviceResources){    
            recordIdByIndex.put(i, serviceResource.Id);
            i++;
        }
        return recordIdByIndex;
    }
}