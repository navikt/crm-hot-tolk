public without sharing class HOT_FaultyEventCleanupScheduler implements Schedulable {
    private static final String JOB_NAME = 'HOT Faulty Event Cleanup';
    private static final List<Integer> RUN_MINUTES = new List<Integer>{ 0, 15, 30, 45 };

    public void execute(SchedulableContext sc) {
        HOT_FaultyEventCleanupBatch.run(null);
    }

    public static List<String> scheduleEvery15Minutes() {
        return scheduleEvery15Minutes(null);
    }

    public static List<String> scheduleEvery15Minutes(String jobNamePrefix) {
        List<String> jobIds = new List<String>();
        String baseJobName = String.isNotBlank(jobNamePrefix) ? jobNamePrefix : JOB_NAME;

        for (Integer minute : RUN_MINUTES) {
            String minuteLabel = minute < 10 ? '0' + minute : String.valueOf(minute);
            String cronExpression = '0 ' + minute + ' * * * ?';
            String jobName = baseJobName + ' ' + minuteLabel;
            jobIds.add(System.schedule(jobName, cronExpression, new HOT_FaultyEventCleanupScheduler()));
        }

        return jobIds;
    }
}
