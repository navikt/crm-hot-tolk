@IsTest(IsParallel=true)
private class HOT_FreelanceUserInfoControllerTest {
    @TestSetup
    static void setup() {
        ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(UserInfo.getUserId());
        insert serviceResource;
    }

    @IsTest
    static void checkUserIdTest() {
        ServiceResource serviceResource = HOT_FreelanceUserInformationController.getServiceResource();
        System.assertEquals(UserInfo.getUserId(), serviceResource.RelatedRecordId);
    }
    @IsTest
    static void checkServiceResourceTest() {
        ServiceResource serviceResource = HOT_FreelanceUserInformationController.getServiceResource();
        System.assertNotEquals(null, serviceResource);
    }

    @IsTest
    static void updateServiceResourceValuesTest() {
        String newName = 'Test Updated Name';
        String newEmail = 'testupdate@example.com';
        String newMobilePhone = '1234567890';
        String newAddress = '123 Oslo';
        String newAddressFormula = null;
        String newMobileDevice = 'iPhone 99';
        String newNotificationChannel = 'Push-varsel i appen';
        Boolean newIsSkilled = true;
        Boolean newIsAvailableForAcuteAssignments = true;
        String newPreferredRegions = 'Vest_Viken;Oslo';
        String newPreferences = 'Updated text';

        Test.startTest();
        ServiceResource updatedSR = HOT_FreelanceUserInformationController.updateServiceResourceName(
            newName,
            newEmail,
            newMobilePhone,
            newAddress,
            newAddressFormula,
            newMobileDevice,
            newNotificationChannel,
            newIsSkilled,
            newIsAvailableForAcuteAssignments,
            newPreferredRegions,
            newPreferences
        );
        Test.stopTest();

        ServiceResource sr = [
            SELECT
                Name,
                HOT_EmailOverride__c,
                HOT_MobilePhoneOverride__c,
                HOT_AddressOverride__c,
                HOT_MobileDevice__c,
                HOT_NotificationChannel__c,
                HOT_Skilled__c,
                HOT_IsAvailableForAcuteAssignments__c,
                HOT_PreferredRegions__c,
                HOT_MoreInformation__c
            FROM ServiceResource
            WHERE Id = :updatedSR.Id
        ];

        System.assertEquals(newName, sr.Name);
        System.assertEquals(newEmail, sr.HOT_EmailOverride__c);
        System.assertEquals(newMobilePhone, sr.HOT_MobilePhoneOverride__c);
        System.assertEquals(newAddress, sr.HOT_AddressOverride__c);
        System.assertEquals(newMobileDevice, sr.HOT_MobileDevice__c);
        System.assertEquals(newNotificationChannel, sr.HOT_NotificationChannel__c);
        System.assertEquals(newIsSkilled, sr.HOT_Skilled__c);
        System.assertEquals(newIsAvailableForAcuteAssignments, sr.HOT_IsAvailableForAcuteAssignments__c);
        System.assertEquals(newPreferredRegions, sr.HOT_PreferredRegions__c);
        System.assertEquals(newPreferences, sr.HOT_MoreInformation__c);
    }
}
