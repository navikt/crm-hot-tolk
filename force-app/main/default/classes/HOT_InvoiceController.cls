public without sharing class HOT_InvoiceController {
    private static void handleException(Exception e) {
        LoggerUtility logger = new LoggerUtility();
        logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
        logger.publishSynch();
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

            if (
                serviceAppointment.HOT_AssignedResourceId__c != null &&
                oldServiceAppointment.Status != serviceAppointment.Status &&
                serviceAppointment.Status == 'Dispatched'
            ) {
                serviceAppointmentsToCreateInvoice.add(serviceAppointment);
            }

            if (
                serviceAppointment.HOT_AssignedResourceId__c != null &&
                oldServiceAppointment.HOT_AssignedResourceId__c != null &&
                serviceAppointment.HOT_AssignedResourceId__c != oldServiceAppointment.HOT_AssignedResourceId__c &&
                serviceAppointment.Status == 'Dispatched'
            ) {
                serviceAppointmentsToUpdateInvoice.add(serviceAppointment);
            }
        }

        try {
            if (!serviceAppointmentsToCreateInvoice.isEmpty()) {
                createOrUpdateInvoices(serviceAppointmentsToCreateInvoice);
            }
            if (!serviceAppointmentsToUpdateInvoice.isEmpty()) {
                updateInvoices(serviceAppointmentsToUpdateInvoice);
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

    private static void createOrUpdateInvoices(List<ServiceAppointment> serviceAppointments) {
        Id otherPayerRecordTypeId = getOtherPayerRecordTypeId();

        Set<Id> serviceAppointmentIds = new Set<Id>();
        for (ServiceAppointment serviceAppointment : serviceAppointments) {
            serviceAppointmentIds.add(serviceAppointment.Id);
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

        for (ServiceAppointment serviceAppointment : serviceAppointments) {
            HOT_Invoice__c existingInvoice = invoiceByServiceAppointmentId.get(serviceAppointment.Id);

            if (existingInvoice == null) {
                HOT_Invoice__c invoice = new HOT_Invoice__c();
                invoice.RecordTypeId = otherPayerRecordTypeId;
                invoice.ServiceAppointment__c = serviceAppointment.Id;
                invoice.WorkOrder__c = serviceAppointment.HOT_WorkOrderID__c;
                invoice.ServiceResource__c = serviceAppointment.HOT_AssignedResourceId__c;
                invoice.Status__c = 'New';
                invoicesToInsert.add(invoice);
            } else {
                existingInvoice.RecordTypeId = otherPayerRecordTypeId;
                existingInvoice.WorkOrder__c = serviceAppointment.HOT_WorkOrderID__c;
                existingInvoice.ServiceResource__c = serviceAppointment.HOT_AssignedResourceId__c;
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

    private static void updateInvoices(List<ServiceAppointment> serviceAppointments) {
        Id otherPayerRecordTypeId = getOtherPayerRecordTypeId();

        Set<Id> serviceAppointmentIds = new Set<Id>();
        Map<Id, ServiceAppointment> serviceAppointmentById = new Map<Id, ServiceAppointment>();

        for (ServiceAppointment serviceAppointment : serviceAppointments) {
            serviceAppointmentIds.add(serviceAppointment.Id);
            serviceAppointmentById.put(serviceAppointment.Id, serviceAppointment);
        }

        List<HOT_Invoice__c> invoicesToUpdate = [
            SELECT Id, ServiceAppointment__c, ServiceResource__c, Status__c, WorkOrder__c, RecordTypeId
            FROM HOT_Invoice__c
            WHERE ServiceAppointment__c IN :serviceAppointmentIds
        ];

        for (HOT_Invoice__c invoice : invoicesToUpdate) {
            ServiceAppointment serviceAppointment = serviceAppointmentById.get(invoice.ServiceAppointment__c);
            if (serviceAppointment == null) {
                continue;
            }

            invoice.RecordTypeId = otherPayerRecordTypeId;
            invoice.WorkOrder__c = serviceAppointment.HOT_WorkOrderID__c;
            invoice.ServiceResource__c = serviceAppointment.HOT_AssignedResourceId__c;
            invoice.Status__c = 'New';
        }

        if (!invoicesToUpdate.isEmpty()) {
            update invoicesToUpdate;
        }
    }
}
