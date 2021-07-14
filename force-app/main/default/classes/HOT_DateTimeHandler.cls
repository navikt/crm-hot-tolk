public without sharing class HOT_DateTimeHandler {
    // Returns true if datetime fields are overlapping
    public static Boolean checkOverlappingDateTimes(DateTime aStart, DateTime aEnd, DateTime bStart, DateTime bEnd) {
        return aStart <= bEnd && aEnd >= bStart;
    }
}
