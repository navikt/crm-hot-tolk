public without sharing class HOT_InvoiceController {
    private static void handleException(Exception e) {
        LoggerUtility logger = new LoggerUtility();
        logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
        logger.publishSynch();
    }

    public static void notifyInterpretersAboutInvoice(List<ServiceAppointment> serviceAppointments) {
        if (serviceAppointments == null || serviceAppointments.isEmpty()) {
            return;
        }

        Set<Id> serviceAppointmentIds = new Set<Id>();
        for (ServiceAppointment sa : serviceAppointments) {
            if (sa != null && sa.Id != null) {
                serviceAppointmentIds.add(sa.Id);
            }
        }

        if (serviceAppointmentIds.isEmpty()) {
            return;
        }

        List<HOT_Invoice__c> invoices = [
            SELECT Id, Serviceappointment__c, ServiceResource__c, Status__c
            FROM HOT_Invoice__c
            WHERE Serviceappointment__c IN :serviceAppointmentIds
        ];

        HOT_InvoiceNotification.sendInvoiceNotification(invoices, 'New');
    }

    public static void resourceServiceAppointmentChanged(
        List<ServiceAppointment> serviceAppointments,
        Map<Id, sObject> triggerOldMap
    ) {
        List<ServiceAppointment> serviceAppointmentsToCreateInvoice = new List<ServiceAppointment>();
        List<ServiceAppointment> serviceAppointmentsToUpdateInvoice = new List<ServiceAppointment>();

        for (ServiceAppointment serviceAppointment : serviceAppointments) {
            ServiceAppointment oldServiceAppointment = (ServiceAppointment) triggerOldMap.get(serviceAppointment.Id);
            if (oldServiceAppointment == null) {
                continue;
            }

            if (serviceAppointment.HOT_IsOtherEconomicProvicer__c != true) {
                continue;
            }
            //NY TOLK ER TILDELT
            if (
                serviceAppointment.HOT_AssignedResourceId__c != null &&
                oldServiceAppointment.Status != serviceAppointment.Status &&
                serviceAppointment.Status == 'Dispatched'
            ) {
                serviceAppointmentsToCreateInvoice.add(serviceAppointment);
            }
            //TOLK ER ENDRET
            if (
                serviceAppointment.HOT_AssignedResourceId__c != null &&
                serviceAppointment.HOT_AssignedResourceId__c != oldServiceAppointment.HOT_AssignedResourceId__c &&
                serviceAppointment.Status == 'Dispatched'
            ) {
                serviceAppointmentsToUpdateInvoice.add(serviceAppointment);
            }
        }

        try {
            if (!serviceAppointmentsToCreateInvoice.isEmpty()) {
                upsertInvoicesForServiceAppointments(serviceAppointmentsToCreateInvoice);
            }
            if (!serviceAppointmentsToUpdateInvoice.isEmpty()) {
                upsertInvoicesForServiceAppointments(serviceAppointmentsToUpdateInvoice);
            }
        } catch (Exception e) {
            handleException(e);
        }
    }

    private static Id getOtherPayerRecordTypeId() {
        Schema.RecordTypeInfo rtInfo = Schema.SObjectType.HOT_Invoice__c
            .getRecordTypeInfosByDeveloperName()
            .get('OtherPayer');

        if (rtInfo == null) {
            throw new IllegalArgumentException('Missing record type HOT_Invoice__c.OtherPayer');
        }

        return rtInfo.getRecordTypeId();
    }

    private static void upsertInvoicesForServiceAppointments(List<ServiceAppointment> serviceAppointments) {
        if (serviceAppointments == null || serviceAppointments.isEmpty()) {
            return;
        }

        Id otherPayerRecordTypeId = getOtherPayerRecordTypeId();

        Set<Id> serviceAppointmentIds = new Set<Id>();
        Map<Id, ServiceAppointment> serviceAppointmentById = new Map<Id, ServiceAppointment>();
        for (ServiceAppointment sa : serviceAppointments) {
            serviceAppointmentIds.add(sa.Id);
            serviceAppointmentById.put(sa.Id, sa);
        }

        Map<Id, HOT_Invoice__c> invoiceByServiceAppointmentId = new Map<Id, HOT_Invoice__c>();
        for (HOT_Invoice__c invoice : [
            SELECT Id, ServiceAppointment__c, WorkOrder__c, ServiceResource__c, Status__c, RecordTypeId
            FROM HOT_Invoice__c
            WHERE ServiceAppointment__c IN :serviceAppointmentIds
        ]) {
            if (!invoiceByServiceAppointmentId.containsKey(invoice.ServiceAppointment__c)) {
                invoiceByServiceAppointmentId.put(invoice.ServiceAppointment__c, invoice);
            }
        }

        List<HOT_Invoice__c> invoicesToInsert = new List<HOT_Invoice__c>();
        List<HOT_Invoice__c> invoicesToUpdate = new List<HOT_Invoice__c>();

        for (Id saId : serviceAppointmentIds) {
            ServiceAppointment sa = serviceAppointmentById.get(saId);
            if (sa == null) {
                continue;
            }

            HOT_Invoice__c existingInvoice = invoiceByServiceAppointmentId.get(saId);
            if (existingInvoice == null) {
                HOT_Invoice__c invoice = new HOT_Invoice__c();
                invoice.RecordTypeId = otherPayerRecordTypeId;
                invoice.ServiceAppointment__c = sa.Id;
                invoice.WorkOrder__c = sa.HOT_WorkOrderID__c;
                invoice.ServiceResource__c = sa.HOT_ServiceResource__c;
                invoice.SubsistenceAllowanceDay1__c = null;
                invoice.SubsistenceAllowanceDay2__c = null;
                invoice.SubsistenceAllowanceDay3__c = null;
                invoice.SubsistenceAllowanceDay4__c = null;
                invoice.SubsistenceAllowanceDay5__c = null;
                invoice.ExpenseTypeA__c = null;
                invoice.ExpenseTypeB__c = null;
                invoice.ExpenseTypeC__c = null;
                invoice.ExpenseTypeD__c = null;
                invoice.ExpenseTypeE__c = null;
                invoice.ExpenseTypeF__c = null;
                invoice.ExpenseTypeG__c = null;
                invoice.ExpenseTypeH__c = null;
                invoice.ExpenseTypeI__c = null;
                invoice.ExpenseTypeJ__c = null;

                invoice.Status__c = 'New';
                invoicesToInsert.add(invoice);
            } else {
                existingInvoice.RecordTypeId = otherPayerRecordTypeId;
                existingInvoice.ServiceResource__c = sa.HOT_ServiceResource__c;
                existingInvoice.SubsistenceAllowanceDay1__c = null;
                existingInvoice.SubsistenceAllowanceDay2__c = null;
                existingInvoice.SubsistenceAllowanceDay3__c = null;
                existingInvoice.SubsistenceAllowanceDay4__c = null;
                existingInvoice.SubsistenceAllowanceDay5__c = null;
                existingInvoice.ExpenseTypeA__c = null;
                existingInvoice.ExpenseTypeB__c = null;
                existingInvoice.ExpenseTypeC__c = null;
                existingInvoice.ExpenseTypeD__c = null;
                existingInvoice.ExpenseTypeE__c = null;
                existingInvoice.ExpenseTypeF__c = null;
                existingInvoice.ExpenseTypeG__c = null;
                existingInvoice.ExpenseTypeH__c = null;
                existingInvoice.ExpenseTypeI__c = null;
                existingInvoice.ExpenseTypeJ__c = null;
                existingInvoice.Status__c = 'New';
                invoicesToUpdate.add(existingInvoice);
            }
        }

        if (!invoicesToInsert.isEmpty()) {
            insert invoicesToInsert;
        }
        if (!invoicesToUpdate.isEmpty()) {
            update invoicesToUpdate;
        }
    }
}
