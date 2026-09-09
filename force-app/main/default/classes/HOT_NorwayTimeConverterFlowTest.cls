@IsTest
private class HOT_NorwayTimeConverterFlowTest {
    @IsTest
    static void convertUtcToNorwayTimeHandlesWinterAndSummerTime() {
        HOT_NorwayTimeConverterFlow.Request winterRequest = new HOT_NorwayTimeConverterFlow.Request();
        winterRequest.startUtc = Datetime.newInstanceGmt(2026, 1, 15, 12, 0, 0);
        winterRequest.endUtc = Datetime.newInstanceGmt(2026, 1, 15, 13, 30, 0);

        HOT_NorwayTimeConverterFlow.Request summerRequest = new HOT_NorwayTimeConverterFlow.Request();
        summerRequest.startUtc = Datetime.newInstanceGmt(2026, 7, 15, 12, 0, 0);
        summerRequest.endUtc = Datetime.newInstanceGmt(2026, 7, 15, 13, 30, 0);

        Test.startTest();
        List<HOT_NorwayTimeConverterFlow.Response> responses = HOT_NorwayTimeConverterFlow.convertUtcToNorwayTime(
            new List<HOT_NorwayTimeConverterFlow.Request>{ winterRequest, summerRequest }
        );
        Test.stopTest();

        System.assertEquals(2, responses.size(), 'Expected one response per request item.');

        System.assertEquals('15.01.2026 13:00', responses[0].startNorwayTime, 'Winter time should be CET (UTC+1).');
        System.assertEquals('15.01.2026 14:30', responses[0].endNorwayTime, 'Winter end time should be CET (UTC+1).');
        System.assertEquals(
            '15.01.2026 13:00 - 15.01.2026 14:30',
            responses[0].rangeNorwayTime,
            'Winter range should include both CET-converted values.'
        );

        System.assertEquals('15.07.2026 14:00', responses[1].startNorwayTime, 'Summer time should be CEST (UTC+2).');
        System.assertEquals('15.07.2026 15:30', responses[1].endNorwayTime, 'Summer end time should be CEST (UTC+2).');
        System.assertEquals(
            '15.07.2026 14:00 - 15.07.2026 15:30',
            responses[1].rangeNorwayTime,
            'Summer range should include both CEST-converted values.'
        );
    }

    @IsTest
    static void convertUtcToNorwayTimeSupportsCustomPatternAndSeparator() {
        HOT_NorwayTimeConverterFlow.Request requestItem = new HOT_NorwayTimeConverterFlow.Request();
        requestItem.startUtcText = '2026-03-01T10:05:00.000Z';
        requestItem.endUtcText = '2026-03-01T11:35:00.000Z';
        requestItem.outputPattern = 'yyyy-MM-dd HH:mm';
        requestItem.rangeSeparator = ' til ';

        Test.startTest();
        List<HOT_NorwayTimeConverterFlow.Response> responses = HOT_NorwayTimeConverterFlow.convertUtcToNorwayTime(
            new List<HOT_NorwayTimeConverterFlow.Request>{ requestItem }
        );
        Test.stopTest();

        System.assertEquals(
            '2026-03-01 11:05',
            responses[0].startNorwayTime,
            'Custom pattern should be used for start.'
        );
        System.assertEquals('2026-03-01 12:35', responses[0].endNorwayTime, 'Custom pattern should be used for end.');
        System.assertEquals(
            '2026-03-01 11:05 til 2026-03-01 12:35',
            responses[0].rangeNorwayTime,
            'Custom separator should be used in range text.'
        );
    }
}
