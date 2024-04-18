@IsTest
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
}
