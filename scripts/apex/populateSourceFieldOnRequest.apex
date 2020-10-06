
List<HOT_Request__c> requests = [SELECT Id, Source__c, CreatedBy.ProfileId FROM HOT_Request__c WHERE Source__c == null AND Orderer__c != null];

Profile dispatcherProfile = [SELECT Id, Name FROM Profile WHERE Name = 'HOT Tolk Formidler'];
Profile interpreterProfile = [SELECT Id, Name FROM Profile WHERE Name = 'HOT Tolk Ansatt'];
Profile userProfile = [SELECT Id, Name FROM Profile WHERE Name = 'NAV Bruker'];
Profile freelanceProfile = [SELECT Id, Name FROM Profile WHERE Name = 'NAV Samhandler'];

for(HOT_Request__c request:requests){

	if(request.CreatedBy.ProfileId == dispatcherProfile.Id || request.CreatedBy.ProfileId == interpreterProfile.Id){
		request.Source__c = 'Dispatcher';
	}
	else if(request.CreatedBy.ProfileId == userProfile.Id || request.CreatedBy.ProfileId == freelanceProfile.Id){
		request.Source__c = 'Community';
	}
	else{
		request.Source__c = null;
	}
}
update requests;

