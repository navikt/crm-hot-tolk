public with sharing class HOT_DatabaseOperations {
    public static void insertRecords(SObject record) {
        List<SObject> records = new List<SObject>{ record };
        dmlOperation('insert', records);
    }

    public static void insertRecords(List<SObject> records) {
        dmlOperation('insert', records);
    }

    public static void updateRecords(SObject record) {
        List<SObject> records = new List<SObject>{ record };
        dmlOperation('update', records);
    }

    public static void updateRecords(List<SObject> records) {
        dmlOperation('update', records);
    }

    public static void upsertRecords(SObject record) {
        List<SObject> records = new List<SObject>{ record };
        dmlOperation('upsert', records);
    }

    public static void upsertRecords(List<SObject> records) {
        dmlOperation('upsert', records);
    }

    public static void deleteRecords(SObject record) {
        List<SObject> records = new List<SObject>{ record };
        dmlOperation('delete', records);
    }

    public static void deleteRecords(List<SObject> records) {
        dmlOperation('delete', records);
    }

    public static void undeleteRecords(SObject record) {
        List<SObject> records = new List<SObject>{ record };
        dmlOperation('undelete', records);
    }

    public static void undeleteRecords(List<SObject> records) {
        dmlOperation('undelete', records);
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
            }
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
            logger.publishSynch();
        }
    }
}
