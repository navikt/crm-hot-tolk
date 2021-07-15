@isTest
public with sharing class HOT_DateTimeHandlerTest {
    @isTest
    static void checkOverlappingDatesFalse() {
        Datetime aStart = Datetime.now().addDays(8);
        Datetime aEnd = Datetime.now().addDays(9);
        Datetime bStart = Datetime.now().addDays(2);
        Datetime bEnd = Datetime.now().addDays(7);

        Test.startTest();
        Boolean isOverlap = HOT_DateTimeHandler.checkOverlappingDateTimes(aStart, aEnd, bStart, bEnd);
        System.assertEquals(false, isOverlap, 'checkOverlappingDateTimes should have returned false.');
        Test.stopTest();
    }

    @isTest
    static void checkOverlappingDatesFalse2() {
        Datetime aStart = Datetime.now().addDays(2);
        Datetime aEnd = Datetime.now().addDays(3);
        Datetime bStart = Datetime.now().addDays(4);
        Datetime bEnd = Datetime.now().addDays(7);

        Test.startTest();
        Boolean isOverlap = HOT_DateTimeHandler.checkOverlappingDateTimes(aStart, aEnd, bStart, bEnd);
        System.assertEquals(false, isOverlap, 'checkOverlappingDateTimes should have returned false.');
        Test.stopTest();
    }

    @isTest
    static void checkOverlappingDatesTrue1() {
        Datetime aStart = Datetime.now().addDays(2);
        Datetime aEnd = Datetime.now().addDays(7);
        Datetime bStart = Datetime.now().addDays(4);
        Datetime bEnd = Datetime.now().addDays(10);

        Test.startTest();
        Boolean isOverlap = HOT_DateTimeHandler.checkOverlappingDateTimes(aStart, aEnd, bStart, bEnd);
        System.assertEquals(true, isOverlap, 'checkOverlappingDateTimes should have returned true.');
        Test.stopTest();
    }

    @isTest
    static void checkOverlappingDatesTrue2() {
        Datetime aStart = Datetime.now().addDays(5);
        Datetime aEnd = Datetime.now().addDays(12);
        Datetime bStart = Datetime.now().addDays(2);
        Datetime bEnd = Datetime.now().addDays(9);

        Test.startTest();
        Boolean isOverlap = HOT_DateTimeHandler.checkOverlappingDateTimes(aStart, aEnd, bStart, bEnd);
        System.assertEquals(true, isOverlap, 'checkOverlappingDateTimes should have returned true.');
        Test.stopTest();
    }

    @isTest
    static void checkOverlappingDatesTrue3() {
        Datetime aStart = Datetime.now().addDays(5);
        Datetime aEnd = Datetime.now().addDays(8);
        Datetime bStart = Datetime.now().addDays(2);
        Datetime bEnd = Datetime.now().addDays(10);

        Test.startTest();
        Boolean isOverlap = HOT_DateTimeHandler.checkOverlappingDateTimes(aStart, aEnd, bStart, bEnd);
        System.assertEquals(true, isOverlap, 'checkOverlappingDateTimes should have returned true.');
        Test.stopTest();
    }

    @isTest
    static void checkOverlappingDatesTrue4() {
        Datetime aStart = Datetime.now().addDays(1);
        Datetime aEnd = Datetime.now().addDays(12);
        Datetime bStart = Datetime.now().addDays(5);
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
