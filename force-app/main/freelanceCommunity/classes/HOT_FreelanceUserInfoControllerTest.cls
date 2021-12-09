@isTest
private class HOT_FreelanceUserInfoControllerTest {
    @TestSetup
    static void setup() {
        ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(UserInfo.getUserId());
        insert serviceResource;
    }

    @isTest
    static void checkUserIdTest() {
        ServiceResource serviceResource = HOT_FreelanceUserInformationController.getServiceResource();
        System.assertEquals(UserInfo.getUserId(), serviceResource.RelatedRecordId);
    }
    @isTest
    static void checkServiceResourceTest() {
        ServiceResource serviceResource = HOT_FreelanceUserInformationController.getServiceResource();
        System.assertNotEquals(null, serviceResource);
    }
}
