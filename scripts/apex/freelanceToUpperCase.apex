List<ServiceResource> sr = [SELECT Id, Name FROM ServiceResource WHERE HOT_IsFreelanceInterpreter__c = true];

for(ServiceResource serviceResource:sr){
	serviceResource.Name = serviceResource.Name.toUpperCase();
}
update sr;