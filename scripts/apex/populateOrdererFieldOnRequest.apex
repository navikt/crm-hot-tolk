List<HOT_Request__c> requests = [SELECT Id, Account__c, Orderer__c FROM HOT_Request__c WHERE Orderer__c = null and Account__c != null];
for(HOT_Request__c request:requests){
	if(request.Orderer__c == null){
		request.Orderer__c = request.Account__c;
	}
}
update requests;