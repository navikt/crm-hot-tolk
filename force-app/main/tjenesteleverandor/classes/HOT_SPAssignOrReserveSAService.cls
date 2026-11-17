public with sharing class HOT_SPAssignOrReserveSAService {
    @InvocableMethod(
        label='Assign or Reserve Service Provider Appointment'
        description='Assigns or reserves an active freelance interpreter after the service provider has accepted the appointment.'
        category='HOT Tolketjeneste'
        iconName='slds:standard:service_appointment'
    )
    public static List<HOT_AssignOrReserveSAService.Result> assignOrReserve(
        List<HOT_AssignOrReserveSAService.Input> reqs
    ) {
        return new HOT_AssignOrReserveSAService(reqs, true).process();
    }
}
