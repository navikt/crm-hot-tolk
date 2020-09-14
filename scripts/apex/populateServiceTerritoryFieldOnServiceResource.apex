List<ServiceTerritoryMember> serviceTerritoryMembers = [SELECT Id, ServiceResourceId, ServiceTerritoryId FROM ServiceTerritoryMember WHERE TerritoryType = 'P'];
Map<Id, Id>  serviceTerritoryIdByServiceResourceId = new Map<Id, Id>();
for(ServiceTerritoryMember stm:serviceTerritoryMembers){
	serviceTerritoryIdByServiceResourceId.put(stm.ServiceResourceId, stm.ServiceTerritoryId);
}

List<ServiceResource> serviceResources = [SELECT Id, HOT_ServiceTerritory__c FROM ServiceResource WHERE Id IN :serviceTerritoryIdByServiceResourceId.keySet()];
for(ServiceResource sr:serviceResources){
	sr.HOT_ServiceTerritory__c = serviceTerritoryIdByServiceResourceId.get(sr.Id);
}
update serviceResources;