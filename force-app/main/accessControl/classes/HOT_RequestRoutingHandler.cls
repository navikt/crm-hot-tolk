public class HOT_RequestRoutingHandler extends MyTriggers {

	public override void onBeforeInsert() {
		
		// Setter feltene Account__c og Person__c når den blir opprettet av en Community-bruker
		User currentUser = [SELECT Id, AccountId, Account.CRM_Person__c FROM User WHERE Id = :UserInfo.getUserId()];
		List<Account> accounts = [SELECT Id, Name, INT_PersonIdent__c, CRM_Person__c, INT_OrganizationNumber__c FROM Account];
		Map<String, Account> identToAccount = new Map<String, Account>();
		Map<String, Account> orgNumberToAccount = new Map<String, Account>();
		for(Account account:accounts){
			if(account.INT_PersonIdent__c != null){
				identToAccount.put(account.INT_PersonIdent__c, account);
			}
			else if(account.INT_OrganizationNumber__c != null){
				orgNumberToAccount.put(account.INT_OrganizationNumber__c, account);
			}
		}
		for ( HOT_Request__c request:(List<HOT_Request__c>)records ) {
			if(request.Account__c == null && currentUser.AccountId != null){

				//Sets account and Person fields if UserPersonNumber__c is filled out in form
				if(request.UserPersonNumber__c != null && identToAccount.get(request.UserPersonNumber__c) != null){
					request.Account__c = identToAccount.get(request.UserPersonNumber__c).Id;
					request.Person__c = identToAccount.get(request.UserPersonNumber__c).CRM_Person__c;
				}
				else{
					//Sets account and Person Fields if it should be connected to THIS.User
					request.Account__c = currentUser.AccountId;
					request.Person__c = currentUser.Account.CRM_Person__c;
				}
				//Sets Company-lookup if orgNumber is filled in
				if(request.OrganizationNumber__c != null && orgNumberToAccount.get(request.OrganizationNumber__c) != null){
					request.Company__c = orgNumberToAccount.get(request.OrganizationNumber__c).Id;
				}
				
				
				
			}
		}
		
		// Tildeler til kø basert på region
		Map<Integer, ApexSharingRuleWrapper> ruleByByRequestId = RecordOwnerService.getQueuesAndNavUnits( getSobjectWrappers(), 'HOT_Request__c' );
		Integer i = 0;
		for ( HOT_Request__c request:(List<HOT_Request__c>)records ) {
			ApexSharingRuleWrapper rule = ruleByByRequestId.get( i );
			if ( rule == null ) continue;
			request.OwnerId = rule.queueId;
			i++;
		}
	}

	private List<SobjectWrapper> getSobjectWrappers() {
		Map<Id, SobjectWrapper> personInfoMap = getPersonsInfo();
		List<SobjectWrapper> wrappers = new List<SobjectWrapper>();
		Integer recordIndex = 0;
		for ( HOT_Request__c request:(List<HOT_Request__c>)records ) {
			SobjectWrapper personInfo = personInfoMap.get( request.Account__c );
			String region = null;

			if ( personInfo != null ) {
				region = personInfo.Region;
			}
			wrappers.add( new SobjectWrapper( recordIndex, null, region ) );
			recordIndex++;
		}

		return wrappers;
	}

	private Map<Id, SobjectWrapper> getPersonsInfo() {
		Set<Id> accountIds = new Set<Id>();
		for ( HOT_Request__c request : (List<HOT_Request__c>) records ) {
			accountIds.add( request.Account__c );
		}
		Map<Id, SobjectWrapper> wrapperByAccountId = new Map<Id, SobjectWrapper>();
		for ( Person__c per : [SELECT INT_RegionNumber__c, CRM_Account__c FROM Person__c WHERE CRM_Account__c in:accountIds] ) {
			SobjectWrapper wrapper = new SobjectWrapper();
			wrapper.Region = per.INT_RegionNumber__c;
			wrapperByAccountId.put( per.CRM_Account__c, wrapper );
		}

		return wrapperByAccountId;
	}
}