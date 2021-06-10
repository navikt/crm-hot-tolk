global class HOT_SAReportingSchedulable implements Schedulable {
    global void execute(SchedulableContext sc) {
        HOT_ServiceAppointmentReportController btch = new HOT_ServiceAppointmentReportController();
        Database.executeBatch(btch, 1000);
    }
}
