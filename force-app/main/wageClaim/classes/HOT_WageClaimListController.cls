public without sharing class HOT_WageClaimListController {
    @AuraEnabled(cacheable=true)
    public static List<HOT_WageClaim__c> getMyWageClaims() {
        List<HOT_WageClaim__c> wageClaims = [
            SELECT
                Id,
                StartTime__c,
                EndTime__c,
                AssignmentType__c,
                WorkTypeName__c,
                toLabel(Status__c),
                ServiceTerritoryName__c,
                ServiceAppointmentName__c,
                ParentWageClaim__c,
                DegreeOfHearingAndVisualImpairment__c
            FROM HOT_WageClaim__c
            WHERE
                Type__c = 'Available on Wage'
                AND Status__c != 'Annul'
                AND ServiceResource__r.RelatedRecordId = :UserInfo.getUserId()
            ORDER BY StartTime__c ASC
        ];
        return wageClaims;
    }

    @AuraEnabled
    public static void retractAvailability(Id recordId) {
        HOT_WageClaim__c wageClaim = new HOT_WageClaim__c(Id = recordId);
        wageClaim.Status__c = 'Retracted Availability';
        try {
            update wageClaim;
        } catch (Exception e) {
            throw e;
        }
    }
}
