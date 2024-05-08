@isTest
private class HOT_UpdateShiftsControllerTest {
    // Utility method to create a test Service Resource and Shift
    private static Shift createTestShift() {
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' OR Name = 'Standardbruker' LIMIT 1];
        User user1 = HOT_TestDataFactory.createUser('user1', profile);
        insert user1;
        ServiceResource serviceResource = HOT_TestDataFactory.createServiceResource(user1.Id);
        insert serviceResource;

        Shift shift = HOT_TestDataFactory.createShift(serviceResource.Id);
        insert shift;

        return shift;
    }

    // Test the getShifts method with a valid ID
    @isTest
    static void testGetShifts() {
        Shift testShift = createTestShift();

        Test.startTest();
        List<Shift> shifts = HOT_UpdateShiftsController.getShifts(testShift.Id);
        Test.stopTest();

        System.assertEquals(1, shifts.size(), 'Should retrieve exactly one shift');
        System.assertEquals(testShift.Id, shifts[0].Id, 'Retrieved shift should have the correct ID');
    }

    // Test the updateRecords method to ensure shifts are updated correctly
    @isTest
    static void testUpdateRecords() {
        Shift testShift = createTestShift();
        Map<String, String> fieldValues = new Map<String, String>{ 'EndTime' => '23:59' };

        Test.startTest();
        HOT_UpdateShiftsController.updateRecords(new List<Shift>{ testShift }, fieldValues);
        Test.stopTest();

        Shift updatedShift = [SELECT EndTime FROM Shift WHERE Id = :testShift.Id];
        System.assertEquals(23, updatedShift.EndTime.hour(), 'End time hour should be updated to 23');
        System.assertEquals(59, updatedShift.EndTime.minute(), 'End time minute should be updated to 59');
    }

    // Test the deleteRecords method to ensure shifts are deleted correctly
    @isTest
    static void testDeleteRecords() {
        Shift testShift = createTestShift();

        Test.startTest();
        HOT_UpdateShiftsController.deleteRecords(new List<Shift>{ testShift });
        Test.stopTest();

        List<Shift> shifts = [SELECT Id FROM Shift WHERE Id = :testShift.Id];
        System.assertEquals(0, shifts.size(), 'Shift should be deleted');
    }
}
