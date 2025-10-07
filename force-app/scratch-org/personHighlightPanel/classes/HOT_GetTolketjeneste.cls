public with sharing class HOT_GetTolketjeneste {
    @AuraEnabled(cacheable=true)
    public static String getTolketjeneste(String recordId, String objectApiName) {
        List<SobjectWrapper> wrappers = new List<SobjectWrapper>();
        SobjectWrapper wrapper = new SobjectWrapper();
        Person__c personDetails = new Person__c();
        String queueName;

        if (objectApiName == 'Account') {
            // Collect Person info
            personDetails = [
                SELECT Id, INT_MunicipalityNumber__c, INT_RegionNumber__c, INT_Confidential__c
                FROM person__c
                WHERE CRM_Account__c = :recordId
            ];
        } else if (objectApiName == 'Person__c') {
            // Collect Person info
            personDetails = [
                SELECT Id, INT_MunicipalityNumber__c, INT_RegionNumber__c, INT_Confidential__c
                FROM person__c
                WHERE id = :recordId
            ];
        }

        //Build wrapper to send
        if (personDetails != null) {
            wrapper.recordIndex = 0;
            wrapper.municipality = personDetails.INT_MunicipalityNumber__c;
            wrapper.region = personDetails.INT_RegionNumber__c;
            wrapper.confidential = personDetails.INT_Confidential__c;
            wrappers.add(wrapper);

            //Collect Map with sharingrulewrapper, collect navUnitId
            map<Integer, ApexSharingRuleWrapper> queueMap = RecordOwnerService.getQueuesAndNavUnits(
                wrappers,
                'Person__c'
            );

            //Use QueueId to collect the Tolketjenesten queue name and return as output to be used on personHighlightPanel
            if (queueMap.size() > 0) {
                queueName = [SELECT Name FROM Group WHERE Id = :queueMap.get(0).queueId].name;
            }
        }
        //For test i scratch
        //queueName = 'NAV Tolketjeneste Troms og Finnmark';
        if (queueName == null) {
            return null;
        } else {
            return queueName;
        }
    }
}
