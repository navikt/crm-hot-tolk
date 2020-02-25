public class UserInfoDetails {

	@AuraEnabled(cacheable = true)
	public static Account getPersonDetails( ) {
		Id userId = UserInfo.getUserId();
		User user = [SELECT Id, AccountId FROM User WHERE Id = : userId];
		Account account = [SELECT Id, Person__c FROM Account WHERE Id = : user.AccountId];

		return account;
	}
}