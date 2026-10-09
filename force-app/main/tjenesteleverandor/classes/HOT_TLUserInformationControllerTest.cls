@IsTest(IsParallel=true)
private class HOT_TLUserInformationControllerTest {
    @TestSetup
    static void setup() {
        ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(UserInfo.getUserId());
        serviceResource.CRM_Domain__c = 'HOT';
        serviceResource.CRM_Subdomain__c = 'Tolketjenesten';
        serviceResource.HOT_IsTjenesteleverandorDispatcher__c = true;
        serviceResource.HOT_PreferredRegions__c = 'Oslo';
        insert serviceResource;
    }

    @IsTest
    static void getCurrentUserServiceResourceReturnsOwnResource() {
        Test.startTest();
        ServiceResource serviceResource = HOT_TLUserInformationController.getCurrentUserServiceResource();
        Test.stopTest();

        System.assertNotEquals(null, serviceResource);
        System.assertEquals('Oslo', serviceResource.HOT_PreferredRegions__c);
    }

    @IsTest
    static void getCurrentUserServiceResourceRejectsNonDispatcher() {
        ServiceResource serviceResource = [
            SELECT Id, HOT_IsTjenesteleverandorDispatcher__c
            FROM ServiceResource
            WHERE RelatedRecordId = :UserInfo.getUserId()
            LIMIT 1
        ];
        serviceResource.HOT_IsTjenesteleverandorDispatcher__c = false;
        update serviceResource;

        Boolean didThrow = false;
        try {
            HOT_TLUserInformationController.getCurrentUserServiceResource();
        } catch (AuraHandledException error) {
            didThrow = true;
        }

        System.assert(didThrow, 'Expected non-dispatcher resource to be rejected.');
    }

    @IsTest
    static void updatePreferredRegionsChangesOnlyRegions() {
        ServiceResource originalResource = HOT_TLUserInformationController.getCurrentUserServiceResource();

        Test.startTest();
        HOT_TLUserInformationController.updatePreferredRegions(new List<String>{ 'Agder', 'Vestland' });
        Test.stopTest();

        ServiceResource updatedResource = [
            SELECT Name, HOT_PreferredRegions__c
            FROM ServiceResource
            WHERE Id = :originalResource.Id
        ];
        System.assertEquals(
            new Set<String>{ 'Agder', 'Vestland' },
            new Set<String>(updatedResource.HOT_PreferredRegions__c.split(';'))
        );
        System.assertEquals('Service Resource Name', updatedResource.Name);
    }

    @IsTest
    static void updatePreferredRegionsRejectsInvalidValues() {
        try {
            HOT_TLUserInformationController.updatePreferredRegions(new List<String>{ 'Not A Region' });
            System.assert(false, 'Expected invalid region to be rejected.');
        } catch (AuraHandledException error) {
            System.assertEquals('Script-thrown exception', error.getMessage());
        }
    }
}
