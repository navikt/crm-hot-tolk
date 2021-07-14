@isTest
public with sharing class HOT_DateTimeHandlerTest {
    @isTest
    static void checkOverlappingDatesFalse() {
        Datetime aStart = Datetime.now().addDays(8);
        Datetime aEnd = Datetime.now().addDays(5);
        Datetime bStart = Datetime.now().addDays(2);
        Datetime bEnd = Datetime.now().addDays(7);

        Test.startTest();
        Boolean isOverlap = HOT_DateTimeHandler.checkOverlappingDateTimes(aStart, aEnd, bStart, bEnd);
        System.assertEquals(false, isOverlap, 'checkOverlappingDateTimes should have returned false.');
        Test.stopTest();
    }

    @isTest
    static void checkOverlappingDatesTrue() {
        Datetime aStart = Datetime.now();
        Datetime aEnd = Datetime.now().addDays(5);
        Datetime bStart = Datetime.now().addDays(2);
        Datetime bEnd = Datetime.now().addDays(7);

        Test.startTest();
        Boolean isOverlap = HOT_DateTimeHandler.checkOverlappingDateTimes(aStart, aEnd, bStart, bEnd);
        System.assertEquals(true, isOverlap, 'checkOverlappingDateTimes should have returned true.');
        Test.stopTest();
    }

    @isTest
    static void checkOverlappingDatesException() {
        Datetime aStart = null;
        Datetime aEnd = Datetime.now().addDays(5);
        Datetime bStart = Datetime.now().addDays(2);
        Datetime bEnd = Datetime.now().addDays(7);

        Test.startTest();
        try {
            HOT_DateTimeHandler.checkOverlappingDateTimes(aStart, aEnd, bStart, bEnd);
        } catch (Exception e) {
            Boolean expectedExceptionThrown = e.getMessage()
                .contains('A Datetime argument was null. All Datetime arguments must have a value');
            System.assertEquals(
                expectedExceptionThrown,
                true,
                'checkOverlappingDateTimes should have returned exception.'
            );
        }
        Test.stopTest();
    }
}
