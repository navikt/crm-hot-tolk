public class HOT_RequestRoutingHandler extends MyTriggers {

	public override void onBeforeInsert() {
		
		// Setter feltene Account__c og Person__c (og Company__c om det eksisterer) når den blir opprettet av en Community-bruker
		//Feltet Orderer__c settes automatisk i skjemaet.
		List<String> idents = new List<String>();
		for(HOT_Request__c request:(List<HOT_Request__c>)records){
			if(!String.isBlank(request.UserPersonNumber__c)){
				idents.add(request.UserPersonNumber__c);
			}
			if(!String.isBlank(request.OrganizationNumber__c)){
				idents.add(request.OrganizationNumber__c);
			}
		}

		User currentUser = [SELECT Id, AccountId, Account.CRM_Person__c FROM User WHERE Id = :UserInfo.getUserId()];
		List<Account> accounts = [SELECT Id, Name, INT_PersonIdent__c, CRM_Person__c, INT_OrganizationNumber__c FROM Account
								  WHERE INT_PersonIdent__c IN :idents OR INT_OrganizationNumber__c IN :idents];
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
				//Checks if user is putting in request for interpreter for itself
				else if(request.Type__c == 'Me'){
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
		Group adminGroup = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'HOT_Tolk_Admin' LIMIT 1];
		for ( HOT_Request__c request:(List<HOT_Request__c>)records ) {
			ApexSharingRuleWrapper rule = ruleByByRequestId.get( i );
			if ( rule == null ) {
				request.OwnerId = adminGroup.Id;
			}
			else{
				request.OwnerId = rule.queueId;
				i++;
			}
		}

	}

	private List<SobjectWrapper> getSobjectWrappers() {
		Map<Id, SobjectWrapper> userInfoMap = getUserInfo();
		Map<Id, SobjectWrapper> companyInfoMap = getCompanyInfo();
		Map<Id, SobjectWrapper> ordererInfoMap = getOrdererInfo();
		List<SobjectWrapper> wrappers = new List<SobjectWrapper>();
		Integer recordIndex = 0;
		for ( HOT_Request__c request:(List<HOT_Request__c>)records ) {

			//If the request is connected to a user (Account__c)
			if(request.Account__c != null && userInfoMap.containsKey(request.Account__c)){
				SobjectWrapper userInfo = userInfoMap.get( request.Account__c );
				String region = null;
				if ( userInfo != null ) {
					region = userInfo.Region;
				}
				wrappers.add( new SobjectWrapper( recordIndex, null, region ) );
				recordIndex++;
			}

			//If the request is connected to a company (Company__c)
			else if(request.Company__c != null && companyInfoMap.containsKey(request.Company__c)){
				SobjectWrapper companyInfo = companyInfoMap.get( request.Company__c );
				String region = null;
				if ( companyInfo != null ) {
					region = companyInfo.Region;
				}
				wrappers.add( new SobjectWrapper( recordIndex, null, region ) );
				recordIndex++;
			}

			//If there was an error connecting the request to a user or company, the request should be sent to the orderers region.
			else {
				SobjectWrapper ordererInfo = ordererInfoMap.get( request.Orderer__c );
				String region = null;
				if ( ordererInfo != null ) {
					region = ordererInfo.Region;
				}
				wrappers.add( new SobjectWrapper( recordIndex, null, region ) );
				recordIndex++;
			}

			//Else, go to hot tolk admin
		}
		return wrappers;
	}

	private Map<Id, SobjectWrapper> getUserInfo() {
		Set<Id> accountIds = new Set<Id>();
		for ( HOT_Request__c request : (List<HOT_Request__c>) records ) {
			if(request.Account__c != null) {
				accountIds.add( request.Account__c );
			}
		}
		Map<Id, SobjectWrapper> wrapperByAccountId = new Map<Id, SobjectWrapper>();
		for ( Person__c per : [SELECT INT_RegionNumber__c, CRM_Account__c FROM Person__c WHERE CRM_Account__c IN :accountIds] ) {
			SobjectWrapper wrapper = new SobjectWrapper();
			wrapper.Region = per.INT_RegionNumber__c;
			wrapperByAccountId.put( per.CRM_Account__c, wrapper );
		}

		return wrapperByAccountId;
	}
	
	private Map<Id, SobjectWrapper> getOrdererInfo() {
		Set<Id> accountIds = new Set<Id>();
		for ( HOT_Request__c request : (List<HOT_Request__c>) records ) {
			if(request.Orderer__c != null) {
				accountIds.add( request.Orderer__c );
			}
		}
		Map<Id, SobjectWrapper> wrapperByAccountId = new Map<Id, SobjectWrapper>();
		for ( Person__c per : [SELECT INT_RegionNumber__c, CRM_Account__c FROM Person__c WHERE CRM_Account__c IN :accountIds] ) {
			SobjectWrapper wrapper = new SobjectWrapper();
			wrapper.Region = per.INT_RegionNumber__c;
			wrapperByAccountId.put( per.CRM_Account__c, wrapper );
		}

		return wrapperByAccountId;
	}
	
	private Map<Id, SobjectWrapper> getCompanyInfo() {
		Set<Id> accountIds = new Set<Id>();
		for ( HOT_Request__c request : (List<HOT_Request__c>) records ) {
			if(request.Company__c != null) {
				accountIds.add( request.Company__c );
			}
		}
		Map<Id, SobjectWrapper> wrapperByAccountId = new Map<Id, SobjectWrapper>();
		for ( Account company : [SELECT Id, INT_RegionNumber__c FROM Account WHERE Id IN :accountIds] ) {
			SobjectWrapper wrapper = new SobjectWrapper();
			wrapper.Region = company.INT_RegionNumber__c;
			wrapperByAccountId.put( company.Id, wrapper );
		}

		return wrapperByAccountId;
	}
}