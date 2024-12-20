@IsTest
public class HOT_ShiftHandlerTest {
    @TestSetup
    static void makeData() {
        OperatingHours operatingHours = HOT_TestDataFactory.createOperatingHours();
        insert operatingHours;
        ServiceTerritory serviceTerritory = HOT_TestDataFactory.createServiceTerritory(operatingHours);
        insert serviceTerritory;

        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' OR Name = 'Standardbruker' LIMIT 1];
        User user = HOT_TestDataFactory.createUser('user', profile);
        insert user;
        ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(user.Id);
        serviceResource.CRM_Domain__c = 'HOT';
        serviceResource.CRM_Subdomain__c = 'Tolketjenesten';
        insert serviceResource;
    }
    @IsTest
    static void createHotShiftTest() {
        ServiceResource serviceResource = [SELECT Id FROM ServiceResource LIMIT 1];
        Shift shift = HOT_TestDataFactory.createShift(serviceResource.Id);

        Test.startTest();
        insert shift;
        Test.stopTest();

        Shift createdShift = [SELECT Id, CRM_ServiceResourceDomain__c, TimeSlotType FROM Shift WHERE Id = :shift.Id];
        System.assertEquals(
            'HOT',
            createdShift.CRM_ServiceResourceDomain__c,
            'CRM ServiceResourceDomain was not correct'
        );
        System.assertEquals('Extended', createdShift.TimeSlotType, 'TimeSlotType was not set to Extended');
    }
}
