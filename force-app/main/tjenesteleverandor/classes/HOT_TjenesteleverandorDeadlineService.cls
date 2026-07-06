public without sharing class HOT_TjenesteleverandorDeadlineService {
    private static final String DEFAULT_CONFIG_NAME = 'Default';

    @TestVisible
    private static Config testConfig;

    public class Request {
        @InvocableVariable(required=true label='Transfer Date')
        public Datetime transferDate;
    }

    public class Result {
        @InvocableVariable(label='Deadline')
        public Datetime deadline;
    }

    private class Config {
        Integer startHour;
        Integer endHour;
        Integer deadlineMinutes;
        String timezoneSidKey;
        Set<Integer> weekdays;
    }

    private class LocalMoment {
        Date localDate;
        Integer minuteOfDay;
    }

    @InvocableMethod(
        label='Calculate Tjenesteleverandor Deadline'
        description='Calculates the supplier acceptance deadline from configurable opening hours.'
        category='HOT Tolketjeneste'
        iconName='slds:standard:service_appointment'
    )
    public static List<Result> calculate(List<Request> requests) {
        List<Result> results = new List<Result>();
        if (requests == null) {
            return results;
        }

        for (Request request : requests) {
            Result result = new Result();
            result.deadline = request?.transferDate == null ? null : calculateDeadline(request.transferDate);
            results.add(result);
        }
        return results;
    }

    public static Datetime calculateDeadline(Datetime transferDate) {
        if (transferDate == null) {
            return null;
        }

        Config config = getConfig();
        LocalMoment current = normalizeToOpenTime(toLocalMoment(transferDate, config.timezoneSidKey), config);
        Integer remainingMinutes = config.deadlineMinutes;

        while (remainingMinutes > 0) {
            Integer endMinute = config.endHour * 60;
            Integer availableMinutes = endMinute - current.minuteOfDay;

            if (remainingMinutes <= availableMinutes) {
                current.minuteOfDay += remainingMinutes;
                remainingMinutes = 0;
            } else {
                remainingMinutes -= availableMinutes;
                current = firstOpenMomentAfter(current.localDate, config);
            }
        }

        return localToUtc(current.localDate, current.minuteOfDay, config.timezoneSidKey);
    }

    @TestVisible
    private static void setTestConfig(
        Integer startHour,
        Integer endHour,
        Integer deadlineMinutes,
        String timezoneSidKey,
        Set<Integer> weekdays
    ) {
        Config config = new Config();
        config.startHour = startHour;
        config.endHour = endHour;
        config.deadlineMinutes = deadlineMinutes;
        config.timezoneSidKey = timezoneSidKey;
        config.weekdays = weekdays;
        testConfig = config;
    }

    @TestVisible
    private static void clearTestConfig() {
        testConfig = null;
    }

    private static Config getConfig() {
        if (testConfig != null) {
            return testConfig;
        }

        HOT_TL_Deadline_Config__mdt metadata = HOT_TL_Deadline_Config__mdt.getInstance(DEFAULT_CONFIG_NAME);
        Config config = new Config();
        config.startHour = metadata?.StartHour__c == null ? 8 : Integer.valueOf(metadata.StartHour__c);
        config.endHour = metadata?.EndHour__c == null ? 16 : Integer.valueOf(metadata.EndHour__c);
        Decimal deadlineHours = metadata?.DeadlineHours__c == null ? 4 : metadata.DeadlineHours__c;
        config.deadlineMinutes = Integer.valueOf((deadlineHours * 60).setScale(0));
        config.timezoneSidKey = String.isBlank(metadata?.TimezoneSidKey__c) ? 'Europe/Oslo' : metadata.TimezoneSidKey__c;
        config.weekdays = parseWeekdays(String.isBlank(metadata?.Weekdays__c) ? '1,2,3,4,5' : metadata.Weekdays__c);

        if (config.endHour <= config.startHour) {
            config.startHour = 8;
            config.endHour = 16;
        }
        if (config.deadlineMinutes <= 0) {
            config.deadlineMinutes = 240;
        }
        if (config.weekdays.isEmpty()) {
            config.weekdays.addAll(new List<Integer>{ 1, 2, 3, 4, 5 });
        }

        return config;
    }

    private static Set<Integer> parseWeekdays(String weekdays) {
        Set<Integer> parsedWeekdays = new Set<Integer>();
        for (String token : weekdays.split(',')) {
            String trimmedToken = token.trim();
            if (String.isBlank(trimmedToken)) {
                continue;
            }
            Integer weekday = Integer.valueOf(trimmedToken);
            if (weekday >= 1 && weekday <= 7) {
                parsedWeekdays.add(weekday);
            }
        }
        return parsedWeekdays;
    }

    private static LocalMoment normalizeToOpenTime(LocalMoment moment, Config config) {
        Integer startMinute = config.startHour * 60;
        Integer endMinute = config.endHour * 60;

        while (!isOpenWeekday(moment.localDate, config)) {
            moment.localDate = moment.localDate.addDays(1);
            moment.minuteOfDay = startMinute;
        }

        if (moment.minuteOfDay < startMinute) {
            moment.minuteOfDay = startMinute;
        } else if (moment.minuteOfDay >= endMinute) {
            moment = firstOpenMomentAfter(moment.localDate, config);
        }

        return moment;
    }

    private static LocalMoment firstOpenMomentAfter(Date localDate, Config config) {
        LocalMoment moment = new LocalMoment();
        moment.localDate = localDate.addDays(1);
        moment.minuteOfDay = config.startHour * 60;

        while (!isOpenWeekday(moment.localDate, config)) {
            moment.localDate = moment.localDate.addDays(1);
        }
        return moment;
    }

    private static Boolean isOpenWeekday(Date localDate, Config config) {
        return config.weekdays.contains(weekdayNumber(localDate));
    }

    private static Integer weekdayNumber(Date localDate) {
        Integer daysSinceMonday = Date.newInstance(1900, 1, 1).daysBetween(localDate);
        return Math.mod(daysSinceMonday, 7) + 1;
    }

    private static LocalMoment toLocalMoment(Datetime value, String timezoneSidKey) {
        LocalMoment moment = new LocalMoment();
        moment.localDate = Date.valueOf(value.format('yyyy-MM-dd', timezoneSidKey));
        moment.minuteOfDay =
            Integer.valueOf(value.format('H', timezoneSidKey)) * 60 +
            Integer.valueOf(value.format('m', timezoneSidKey));
        return moment;
    }

    private static Datetime localToUtc(Date localDate, Integer minuteOfDay, String timezoneSidKey) {
        Time localTime = Time.newInstance(Math.floor(minuteOfDay / 60).intValue(), Math.mod(minuteOfDay, 60), 0, 0);
        Datetime assumedUtc = Datetime.newInstanceGmt(localDate, localTime);
        TimeZone timezone = TimeZone.getTimeZone(timezoneSidKey);
        Integer offset = timezone.getOffset(assumedUtc);
        Datetime utc = assumedUtc.addSeconds(-(offset / 1000));
        Integer adjustedOffset = timezone.getOffset(utc);

        if (adjustedOffset != offset) {
            utc = assumedUtc.addSeconds(-(adjustedOffset / 1000));
        }
        return utc;
    }
}
