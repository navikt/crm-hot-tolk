/**
 * @description: Flow utility for converting UTC datetime values to Norway local time.
 */
public with sharing class HOT_NorwayTimeConverterFlow {
    private static final String NORWAY_TIMEZONE = 'Europe/Oslo';
    private static final String DEFAULT_PATTERN = 'dd.MM.yyyy HH:mm';
    private static final String DEFAULT_SEPARATOR = ' - ';

    /**
     * @description: Flow input variables for UTC values and formatting options.
     */
    public class Request {
        @InvocableVariable(label='Start UTC Datetime')
        public Datetime startUtc;

        @InvocableVariable(label='Start UTC Datetime Text (Optional)')
        public String startUtcText;

        @InvocableVariable(label='End UTC Datetime')
        public Datetime endUtc;

        @InvocableVariable(label='End UTC Datetime Text (Optional)')
        public String endUtcText;

        @InvocableVariable(label='Output Pattern (Optional)')
        public String outputPattern;

        @InvocableVariable(label='Range Separator (Optional)')
        public String rangeSeparator;
    }

    /**
     * @description: Flow output values formatted in Norway local time.
     */
    public class Response {
        @InvocableVariable(label='Start Time In Norway')
        public String startNorwayTime;

        @InvocableVariable(label='End Time In Norway')
        public String endNorwayTime;

        @InvocableVariable(label='Range Time In Norway')
        public String rangeNorwayTime;
    }

    @InvocableMethod(
        label='Convert UTC To Norway Time'
        description='Converts UTC datetimes to Norway local time (CET/CEST).'
    )
    /**
     * @description: Converts one or more UTC datetime inputs to formatted Norway local time text.
     * @param requests List of flow requests with UTC datetime values and optional formatting.
     * @return List of flow responses containing formatted Norway-time strings.
     **/
    public static List<Response> convertUtcToNorwayTime(List<Request> requests) {
        List<Response> responses = new List<Response>();

        for (Request requestItem : requests) {
            Response responseItem = new Response();
            String pattern = String.isBlank(requestItem.outputPattern) ? DEFAULT_PATTERN : requestItem.outputPattern;
            String separator = String.isBlank(requestItem.rangeSeparator)
                ? DEFAULT_SEPARATOR
                : requestItem.rangeSeparator;
            Datetime startUtc = resolveUtcDatetime(requestItem.startUtc, requestItem.startUtcText);
            Datetime endUtc = resolveUtcDatetime(requestItem.endUtc, requestItem.endUtcText);

            if (startUtc != null) {
                responseItem.startNorwayTime = formatInNorway(startUtc, pattern);
            }

            if (endUtc != null) {
                responseItem.endNorwayTime = formatInNorway(endUtc, pattern);
            }

            if (responseItem.startNorwayTime != null && responseItem.endNorwayTime != null) {
                responseItem.rangeNorwayTime = responseItem.startNorwayTime + separator + responseItem.endNorwayTime;
            } else if (responseItem.startNorwayTime != null) {
                responseItem.rangeNorwayTime = responseItem.startNorwayTime;
            } else if (responseItem.endNorwayTime != null) {
                responseItem.rangeNorwayTime = responseItem.endNorwayTime;
            }

            responses.add(responseItem);
        }

        return responses;
    }

    private static String formatInNorway(Datetime utcDateTime, String pattern) {
        return utcDateTime.format(pattern, NORWAY_TIMEZONE);
    }

    private static Datetime resolveUtcDatetime(Datetime utcDateTime, String utcDateTimeText) {
        if (utcDateTime != null) {
            return utcDateTime;
        }

        if (String.isBlank(utcDateTimeText)) {
            return null;
        }

        try {
            String jsonEncodedDateTime = '"' + utcDateTimeText.replace('"', '\\"') + '"';
            return (Datetime) JSON.deserialize(jsonEncodedDateTime, Datetime.class);
        } catch (Exception ex) {
            String normalizedDateTime = utcDateTimeText.replace('T', ' ').replace('Z', '');
            return Datetime.valueOfGmt(normalizedDateTime);
        }
    }
}
