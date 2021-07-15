public without sharing class HOT_DateTimeHandler {
    // Returns true if datetime fields are overlapping
    public static Boolean checkOverlappingDateTimes(DateTime aStart, DateTime aEnd, DateTime bStart, DateTime bEnd) {
        if (aStart == null || aEnd == null || bStart == null || bEnd == null || aStart > aEnd || bStart > bEnd) {
            throw new DateTimeHandlerException(
                'A Datetime argument was null or invalid. All Datetime arguments must have a value and start values must be greater than end values.'
            );
        }
        return aStart < bEnd && aEnd > bStart;
    }

    public class DateTimeHandlerException extends Exception {
    }
}
