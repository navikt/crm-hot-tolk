public without sharing class HOT_InvoiceController {
    public class InvoiceShares {
        @InvocableVariable(required=true)
        public Id userId;

        @InvocableVariable(required=true)
        public Id invoiceId;
    }

    @InvocableMethod
    public static void createInvoiceShare(List<InvoiceShares> invoiceShares) {
        if (invoiceShares == null || invoiceShares.isEmpty()) {
            return;
        }

        List<HOT_Invoice__Share> sharesToInsert = new List<HOT_Invoice__Share>();

        for (InvoiceShares invShare : invoiceShares) {
            if (invShare == null || invShare.userId == null || invShare.invoiceId == null) {
                continue;
            }

            sharesToInsert.add(
                new HOT_Invoice__Share(
                    ParentId = invShare.invoiceId,
                    UserOrGroupId = invShare.userId,
                    AccessLevel = 'Edit',
                    RowCause = Schema.HOT_Invoice__Share.RowCause.Manual
                )
            );
        }

        if (sharesToInsert.isEmpty()) {
            return;
        }

        try {
            insert sharesToInsert;
        } catch (Exception e) {
            handleException(e);
        }
    }

    private static void handleException(Exception e) {
        LoggerUtility logger = new LoggerUtility();
        logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
        logger.publishSynch();
    }
}
