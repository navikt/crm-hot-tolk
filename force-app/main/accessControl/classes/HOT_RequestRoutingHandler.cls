public class HOT_RequestRoutingHandler extends MyTriggers {

	public override void onBeforeInsert() {

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