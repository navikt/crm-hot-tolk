@isTest
public without sharing class HOT_ServiceAppointmentStatusUpdateBTest {
    @isTest
    static void HOT_ServiceAppointmentStatusUpdateee() {
        List<ServiceAppointment> ls = [
            SELECT Id, Status
            FROM ServiceAppointment
            WHERE Status = 'Released to Freelance' OR Status = 'None'
        ];
    }
}
