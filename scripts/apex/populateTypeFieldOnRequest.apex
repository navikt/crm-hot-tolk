List<HOT_Request__c> requests = [SELECT Id, Type__c, Account__c, Orderer__c, Company__c FROM HOT_Request__c WHERE Type__c = null AND Orderer__c != null];

for(HOT_Request__c request:requests){

	if(request.Account__c == request.Orderer__c){
		request.Type__c = 'Me';
	}
	else if(request.Company__c == null){
		request.Type__c = 'User';
	}
	else if(request.Account__c != null){
		request.Type__c = 'Company';
	}
	else if(request.Company__c != null && request.Account__c == null && request.Orderer__c != null) {
		request.Type__c = 'PublicEvent';
	}
}

update requests;

