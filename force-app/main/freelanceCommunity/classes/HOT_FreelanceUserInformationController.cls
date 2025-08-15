public without sharing class HOT_FreelanceUserInformationController {
    @AuraEnabled(cacheable=true)
    public static ServiceResource getServiceResource() {
        Id userId = UserInfo.getUserId();
        ServiceResource freelanceServiceResource = [
            SELECT
                HOT_IsFreelanceInterpreter__c,
                AccountId,
                HOT_IsAvailableForAcuteAssignments__c,
                RelatedRecordId,
                HOT_Skilled__c,
                Name,
                HOT_Email__c,
                HOT_EmailOverride__c,
                HOT_MobilePhone__c,
                HOT_Address__c,
                HOT_MobilePhoneOverride__c,
                HOT_MobileDevice__c,
                HOT_NotificationChannel__c,
                HOT_PreferredRegions__c, 
                HOT_MoreInformation__c
            FROM ServiceResource
            WHERE RelatedRecordId = :userId
        ];
        return freelanceServiceResource;
    }

    @AuraEnabled
    public static ServiceResource updateServiceResourceName(
        String newName, 
        String newEmail, 
        String newMobilePhone, 
        String newAddress, 
        String newAddressFormula,
        String newMobileDevice,
        String newNotificationChannel,
        Boolean newIsSkilled, 
        Boolean newIsAvailableForAcuteAssignments, 
        String newPreferredRegions,
        String newPreferences
        ) {
        Id userId = UserInfo.getUserId();
        ServiceResource sr = [
            SELECT
                HOT_IsFreelanceInterpreter__c,
                AccountId,
                HOT_IsAvailableForAcuteAssignments__c,
                RelatedRecordId,
                HOT_Skilled__c,
                Name,
                HOT_Email__c,
                HOT_EmailOverride__c,
                HOT_MobilePhone__c,
                HOT_Address__c,
                HOT_AddressOverride__c,
                HOT_MobilePhoneOverride__c,
                HOT_MobileDevice__c,
                HOT_NotificationChannel__c,
                HOT_PreferredRegions__c, 
                HOT_MoreInformation__c
            FROM ServiceResource
            WHERE RelatedRecordId = :userId
        ];

        if(newName != null) {
            sr.Name = newName;
        }
        if(newEmail != null) {
            sr.HOT_EmailOverride__c = newEmail;
        }
        if(newMobilePhone != null) {
            sr.HOT_MobilePhoneOverride__c = newMobilePhone;
        }
        if(newAddress != null) {
            sr.HOT_AddressOverride__c = newAddress;
        }
        if(newMobileDevice != null) {
            sr.HOT_MobileDevice__c = newMobileDevice;
        }
        if(newNotificationChannel  != null) {
            sr.HOT_NotificationChannel__c = newNotificationChannel;
        }
        if(newIsSkilled != null) {
            sr.HOT_Skilled__c = newIsSkilled;
        }
        if(newIsAvailableForAcuteAssignments != null) {
            sr.HOT_IsAvailableForAcuteAssignments__c = newIsAvailableForAcuteAssignments;
        }
        if(newPreferredRegions != null) {
            sr.HOT_PreferredRegions__c = newPreferredRegions;
        }
        if(newPreferences != null) {
            sr.HOT_MoreInformation__c = newPreferences;
        }

        update sr;

        return sr;
    }

}
