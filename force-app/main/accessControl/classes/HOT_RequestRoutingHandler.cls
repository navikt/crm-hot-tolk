public class HOT_RequestRoutingHandler extends MyTriggers {

	public override void onBeforeInsert() {
		
		// Setter feltene Account__c og Person__c når den blir opprettet av en Community-bruker
		User currentUser = [SELECT Id, AccountId, Account.CRM_Person__c from User WHERE Id = :UserInfo.getUserId()];
		for ( HOT_Request__c request:(List<HOT_Request__c>)records ) {
			if(request.Account__c == null && currentUser.AccountId != null){
				request.Account__c = currentUser.AccountId;
				request.Person__c = currentUser.Account.CRM_Person__c;
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