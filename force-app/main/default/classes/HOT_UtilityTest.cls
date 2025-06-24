@IsTest
private class HOT_UtilityTest {
    @testSetup
    static void setup() {
        ServiceResource serviceresource = HOT_TestDataFactory.createServiceResource(UserInfo.getUserId());
        insert serviceresource;
    }

    @IsTest
    static void testGetServiceResource() {
        ServiceResource serviceResource = HOT_Utility.getServiceResource();
        System.assertEquals(UserInfo.getUserId(), serviceResource.RelatedRecordId);
    }

    @IsTest
    static void testCheckAssignedPermissionSet() {
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'HOT_Tolk_Ansatt'];
        PermissionSetAssignment permissionSetAssignment = new PermissionSetAssignment(
            AssigneeId = UserInfo.getUserId(),
            PermissionSetId = ps.Id
        );
        insert permissionSetAssignment;

        Boolean hasPermissionSet = HOT_Utility.checkAssignedPermissionSet('HOT_Tolk_Ansatt');
        System.assertEquals(true, hasPermissionSet);
    }
    @IsTest
    static void testCheckAssignedPermissionSetGroup() {
        PermissionSetGroup psg = [SELECT Id FROM PermissionSetGroup WHERE DeveloperName = 'Test'];
        PermissionSetAssignment permissionSetAssignment = new PermissionSetAssignment(
            AssigneeId = UserInfo.getUserId(),
            PermissionSetGroupId = psg.Id
        );
        insert permissionSetAssignment;

        Boolean hasPermissionSet = HOT_Utility.checkAssignedPermissionSetGroup('Test');
        System.assertEquals(true, hasPermissionSet);
    }

    @IsTest
    static void testGetAssignedResource() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('Bestilling', workType);
        insert request;
        request.Status__c = 'Godkjent';
        update request;
        List<Id> requestIds = new List<Id>{ request.Id };
        ServiceResource serviceResource = HOT_Utility.getServiceResource();

        ServiceAppointment serviceAppointment = [
            SELECT Id
            FROM ServiceAppointment
            WHERE HOT_Request__c = :request.Id
            LIMIT 1
        ];
        AssignedResource assignedResource = HOT_TestDataFactory.createAssignedResource(
            serviceAppointment.Id,
            serviceResource.Id
        );
        insert assignedResource;
        serviceAppointment.Status = 'Dispatched';
        update serviceAppointment;

        Test.startTest();
        Map<Id, List<String>> requestIdToServiceResources = HOT_Utility.getAssignedResources(requestIds);
        Test.stopTest();

        System.assertEquals(1, requestIdToServiceResources.get(request.Id).size(), 'Could not get assigned resources');
    }

    @IsTest
    static void testCheckUserHasEntitlement() {
        Person__c person = HOT_TestDataFactory.createPerson();
        insert person;

        Test.startTest();
        Boolean hasVedtak = HOT_Utility.checkUserHasEntitlement();
        Test.stopTest();

        System.assertEquals(false, hasVedtak);
    }

    //TODO: //TODO: Oppdatere asserts til å sjekke epost og mobil på orderer, men må da kunne kjøre testen som en Community-bruker, noe som vi ikke har fått til enda
    @IsTest
    static void testGetOrdererDetails() {
        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request = HOT_TestDataFactory.createRequest('Testing getOrderDetails', workType);
        insert request;

        Test.startTest();
        Map<String, String> ordererDetails = HOT_Utility.getOrdererDetails();
        Test.stopTest();

        System.assertEquals('', ordererDetails.get('OrdererEmail__c'));
        System.assertEquals('', ordererDetails.get('OrdererPhone__c'));
    }

    @IsTest
    static void getPersonAccountTest() {
        Test.startTest();
        User u;
        try {
            u = HOT_Utility.getPersonAccount();
        } catch (exception e) {
            //This will always fail due to no User with AccountId existing
        }
        Test.stopTest();
    }

    @IsTest
    static void getMinutesUntilNextSMSBatchTest() {
        Test.startTest();
        long re = HOT_Utility.getMinutesUntilNextSMSBatch();
        Test.stopTest();
    }

    @IsTest
    static void getMinutesUntilNextReminderSMSBatchTest() {
        Test.startTest();
        long re = HOT_Utility.getMinutesUntilNextReminderSMSBatch();
        Test.stopTest();
    }

    @IsTest
    static void getSkillsTest() {
        Test.startTest();
        List<Skill> skill = HOT_Utility.getSkills();
        Test.stopTest();
    }
}
