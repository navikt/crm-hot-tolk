public without sharing class HOT_InvoiceNotification {
    public static void sendInvoiceNotification(List<HOT_Invoice__c> invoices, String type) {
        if (invoices == null || invoices.isEmpty())
            return;

        CustomNotificationType notificationType = getCustomNotificationType('HOT_NotifyInterpreter');
        List<HOT_Notification__c> notificationListToInsert = new List<HOT_Notification__c>();

        Set<Id> saIds = new Set<Id>();
        Set<Id> serviceResourceIds = new Set<Id>();

        for (HOT_Invoice__c inv : invoices) {
            if (inv.ServiceAppointment__c != null)
                saIds.add(inv.ServiceAppointment__c);

            if (inv.ServiceResource__c != null)
                serviceResourceIds.add(inv.ServiceResource__c);
        }

        Map<Id, ServiceAppointment> saById = saIds.isEmpty()
            ? new Map<Id, ServiceAppointment>()
            : new Map<Id, ServiceAppointment>(
                  [SELECT Id, EarliestStartTime, DueDate, AppointmentNumber FROM ServiceAppointment WHERE Id IN :saIds]
              );

        Map<Id, ServiceResource> srById = serviceResourceIds.isEmpty()
            ? new Map<Id, ServiceResource>()
            : new Map<Id, ServiceResource>(
                  [SELECT Id, RelatedRecordId FROM ServiceResource WHERE Id IN :serviceResourceIds]
              );

        for (HOT_Invoice__c invoice : invoices) {
            ServiceAppointment serviceAppointment = saById.get(invoice.ServiceAppointment__c);
            if (serviceAppointment == null)
                continue;

            ServiceResource sr = srById.get(invoice.ServiceResource__c);
            if (sr == null || sr.RelatedRecordId == null)
                continue;

            Set<String> recipientIds = new Set<String>{ sr.RelatedRecordId };

            String subject;
            switch on type {
                when 'New' {
                    subject = 'Du kan nå fylle ut oppdragskvittering for ' + serviceAppointment.AppointmentNumber;
                }
                when 'Reminder' {
                    subject = 'Påminnelse om fylle ut oppdragskvittering for ' + serviceAppointment.AppointmentNumber;
                }
                when 'Sent In Return' {
                    subject =
                        'Oppdragskvittering din for ' +
                        serviceAppointment.AppointmentNumber +
                        ' ble sendt i retur til deg for endring';
                }
                when else {
                    subject = 'Du kan nå fylle ut oppdragskvittering for ' + serviceAppointment.AppointmentNumber;
                }
            }
            String body =
                'Gjelder for oppdraget som var ' +
                serviceAppointment.EarliestStartTime?.format('dd.MM.yyyy', 'Europe/Oslo') +
                ' kl ' +
                serviceAppointment.EarliestStartTime?.format('HH:mm', 'Europe/Oslo') +
                ' - ' +
                serviceAppointment.DueDate?.format('HH:mm', 'Europe/Oslo') +
                '.';

            HOT_UserNotificationService.invoiceNotification(
                notificationType,
                invoice,
                serviceAppointment,
                recipientIds,
                subject,
                body
            );
            notificationListToInsert.add(createNotificationListObject(invoice, serviceAppointment, subject, body));
        }

        if (!notificationListToInsert.isEmpty()) {
            insert notificationListToInsert;
        }
    }
    public static CustomNotificationType getCustomNotificationType(String devName) {
        CustomNotificationType notificationType = [
            SELECT Id, DeveloperName
            FROM CustomNotificationType
            WHERE DeveloperName = :devName
        ];
        return notificationType;
    }
    public static HOT_Notification__c createNotificationListObject(
        HOT_Invoice__c invoice,
        ServiceAppointment serviceAppointment,
        String subject,
        String body
    ) {
        HOT_Notification__c notification = new HOT_Notification__c();
        notification.HOT_ServiceResource__c = invoice.ServiceResource__c;
        notification.HOT_NotificationChannel__c = 'Push-varsel i appen';
        notification.HOT_Subject__c = subject;
        notification.HOT_NotificationText__c = body;
        notification.HOT_RelatedObject__c = invoice.Id;
        notification.HOT_RelatedObjectType__c = 'invoice';

        return notification;
    }
}
