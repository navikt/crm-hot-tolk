public with sharing class HOT_DatabaseOperations {
    private static final String INSERTOPERATOR = 'insert';
    private static final String UPDATEOPERATOR = 'update';
    private static final String UPSERTOPERATOR = 'upsert';
    private static final String DELETEOPERATOR = 'delete';
    private static final String UNDELETEOPERATOR = 'undelete';

    public static void insertRecords(SObject record) {
        List<SObject> records = new List<SObject>{ record };
        dmlOperation(INSERTOPERATOR, records);
    }

    public static void insertRecords(List<SObject> records) {
        dmlOperation(INSERTOPERATOR, records);
    }

    public static void updateRecords(SObject record) {
        List<SObject> records = new List<SObject>{ record };
        dmlOperation(UPDATEOPERATOR, records);
    }

    public static void updateRecords(List<SObject> records) {
        dmlOperation(UPDATEOPERATOR, records);
    }

    public static void upsertRecords(SObject record) {
        List<SObject> records = new List<SObject>{ record };
        dmlOperation(UPSERTOPERATOR, records);
    }

    public static void upsertRecords(List<SObject> records) {
        dmlOperation(UPSERTOPERATOR, records);
    }

    public static void deleteRecords(SObject record) {
        List<SObject> records = new List<SObject>{ record };
        dmlOperation(DELETEOPERATOR, records);
    }

    public static void deleteRecords(List<SObject> records) {
        dmlOperation(DELETEOPERATOR, records);
    }

    public static void undeleteRecords(SObject record) {
        List<SObject> records = new List<SObject>{ record };
        dmlOperation(UNDELETEOPERATOR, records);
    }

    public static void undeleteRecords(List<SObject> records) {
        dmlOperation(UNDELETEOPERATOR, records);
    }

    private static void dmlOperation(String operation, List<SObject> records) {
        try {
            switch on operation {
                when 'insert' {
                    insert records;
                }
                when 'update' {
                    update records;
                }
                when 'upsert' {
                    upsert records;
                }
                when 'delete' {
                    delete records;
                }
                when 'undelete' {
                    undelete records;
                }
                when else {
                    System.debug('Invalid dmlOperation choice. The given choice was ' + operation);
                }
            }
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
            logger.publishSynch();
        }
    }
}
