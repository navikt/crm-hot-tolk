public without sharing class HOT_UserHandler extends MyTriggers {
	
	//Om en bruker som er Ansatt Tolk opprettes, skal en Tjenesteressurs opprettes, og kobles til denne brukeren.
	public override void onAfterInsert(){
		String profileName = Test.isRunningTest() ? 'Standard User' : 'HOT Tolk Ansatt';
		List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = :profileName];
		if(profiles.size()>0){
			List<Id> userIds = new List<Id>();
			for(User user:(List<User>) records){
				if(user.ProfileId == profiles[0].Id){
					userIds.add(user.Id);
				}
			}
			HOT_ServiceResourceHandler.createServiceResourceFuture(userIds);
		}
	}
}
