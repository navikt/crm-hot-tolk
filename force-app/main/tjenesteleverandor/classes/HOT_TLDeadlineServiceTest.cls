@IsTest
private class HOT_TLDeadlineServiceTest {
    private static void setDefaultConfig() {
        HOT_TjenesteleverandorDeadlineService.setTestConfig(
            8,
            16,
            240,
            'Europe/Oslo',
            new Set<Integer>{ 1, 2, 3, 4, 5 }
        );
    }

    @IsTest
    static void transferInsideOpeningHoursReturnsFourOpenHoursLater() {
        setDefaultConfig();
        Datetime deadline = HOT_TjenesteleverandorDeadlineService.calculateDeadline(
            Datetime.newInstanceGmt(2026, 1, 5, 9, 0, 0)
        );

        System.assertEquals('2026-01-05 14:00', deadline.format('yyyy-MM-dd HH:mm', 'Europe/Oslo'));
    }

    @IsTest
    static void transferAfterClosingStartsNextWeekdayMorning() {
        setDefaultConfig();
        Datetime deadline = HOT_TjenesteleverandorDeadlineService.calculateDeadline(
            Datetime.newInstanceGmt(2026, 1, 5, 16, 0, 0)
        );

        System.assertEquals('2026-01-06 12:00', deadline.format('yyyy-MM-dd HH:mm', 'Europe/Oslo'));
    }

    @IsTest
    static void transferBeforeOpeningStartsAtOpeningHour() {
        setDefaultConfig();
        Datetime deadline = HOT_TjenesteleverandorDeadlineService.calculateDeadline(
            Datetime.newInstanceGmt(2026, 1, 5, 6, 0, 0)
        );

        System.assertEquals('2026-01-05 12:00', deadline.format('yyyy-MM-dd HH:mm', 'Europe/Oslo'));
    }

    @IsTest
    static void weekendSkipsToNextWeekday() {
        setDefaultConfig();
        Datetime deadline = HOT_TjenesteleverandorDeadlineService.calculateDeadline(
            Datetime.newInstanceGmt(2026, 1, 3, 10, 0, 0)
        );

        System.assertEquals('2026-01-05 12:00', deadline.format('yyyy-MM-dd HH:mm', 'Europe/Oslo'));
    }

    @IsTest
    static void invocableHandlesNullsAndUsesMetadataDefault() {
        HOT_TjenesteleverandorDeadlineService.clearTestConfig();

        System.assertEquals(0, HOT_TjenesteleverandorDeadlineService.calculate(null).size());

        HOT_TjenesteleverandorDeadlineService.Request emptyRequest = new HOT_TjenesteleverandorDeadlineService.Request();
        List<HOT_TjenesteleverandorDeadlineService.Result> emptyResults =
            HOT_TjenesteleverandorDeadlineService.calculate(
                new List<HOT_TjenesteleverandorDeadlineService.Request>{ emptyRequest }
            );
        System.assertEquals(null, emptyResults[0].deadline);

        HOT_TjenesteleverandorDeadlineService.Request request = new HOT_TjenesteleverandorDeadlineService.Request();
        request.transferDate = Datetime.newInstanceGmt(2026, 1, 5, 9, 0, 0);
        List<HOT_TjenesteleverandorDeadlineService.Result> results = HOT_TjenesteleverandorDeadlineService.calculate(
            new List<HOT_TjenesteleverandorDeadlineService.Request>{ request }
        );

        System.assertEquals('2026-01-05 14:00', results[0].deadline.format('yyyy-MM-dd HH:mm', 'Europe/Oslo'));
    }
}
