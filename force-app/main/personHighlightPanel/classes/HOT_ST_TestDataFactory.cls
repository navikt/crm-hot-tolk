@isTest
public class HOT_ST_TestDataFactory {
    public static List<QuickText> createQuickTexts(Integer amount) {
        List<QuickText> quickTexts = new List<QuickText>();
        for (Integer i = 0; i < amount; i++) {
            QuickText qt = new QuickText(Name = 'Test ' + i, Message = 'Dette er en melding');
            quickTexts.add(qt);
        }
        insert quickTexts;
        return quickTexts;
    }

    public static Case createCase(String lastname) {
        Account a = [SELECT Id FROM Account WHERE LastName = :lastname];
        Case c = new Case(AccountId = a.Id, Status = 'New', Origin = 'Web');
        insert c;
        return c;
    }

    public static List<Person__c> createPersons(Integer amount) {
        List<Person__c> persons = new List<Person__c>();
        for (Integer i = 0; i < amount; i++) {
            Person__c p = new Person__c(
                Name = '1234567890' + i,
                INT_MunicipalityNumber__c = '0301',
                INT_LastName__c = 'Test' + i,
                INT_Confidential__c = 'UGRADERT',
                INT_MaritalStatus__c = 'UOPPGITT'
            );
            persons.add(p);
        }
        insert persons;
        Integer i = 1;
        for (Person__c p : persons) {
            createPersonAccount(i, p);
            i++;
        }
        return persons;
    }

    public static void createPersonAccount(Integer i, Person__c p) {
        String personAccountRecordType = Schema.getGlobalDescribe()
            .get('Account')
            .getDescribe()
            .getRecordTypeInfosByDeveloperName()
            .get('PersonAccount')
            .getRecordTypeId();
        Account acc = new Account(
            FirstName = 'Harry',
            LastName = 'Potter',
            INT_PersonIdent__c = '1234567890' + i,
            RecordTypeId = personAccountRecordType,
            CRM_Person__c = p.Id
        );
        insert acc;
    }

    public static List<LiveChatTranscript> createLiveChatTranscripts(Integer amount) {
        LiveChatVisitor v = HOT_ST_TestDataFactory.createLiveChatVisitor();
        List<LiveChatTranscript> liveChatTranscripts = new List<LiveChatTranscript>();
        for (Integer i = 0; i < amount; i++) {
            LiveChatTranscript lct = new LiveChatTranscript(LiveChatVisitorId = v.Id);
            liveChatTranscripts.add(lct);
        }
        insert liveChatTranscripts;
        return liveChatTranscripts;
    }
    public static LiveChatVisitor createLiveChatVisitor() {
        LiveChatVisitor visitor = new LiveChatVisitor();
        insert visitor;
        return visitor;
    }

    /* This method is used for creating a record. The record is inserted before it's returned,
     * and default fields are populated.
     * @param record [sObject: the record]
     * @return       [sObject: the record, inserted and with defualt fields populated]
     */
    public static sObject createRecord(sObject record) {
        return createRecord(record, true);
    }

    public static User createUser(Profile profile, Account account) {
        User user = createUser('User', profile);
        user.ContactId = account.PersonContactId;
        return user;
    }

    public static User createUser(String lastName, Profile profile) {
        User user = new User(
            Username = 'HOT.' + lastName + '@nav.hot.no',
            LastName = lastName,
            Email = 'HOT_testuser@nav.hot.no',
            Alias = lastName,
            CommunityNickname = lastName,
            TimeZoneSidKey = 'Europe/Paris',
            LocaleSidKey = 'no_NO',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'no',
            ProfileId = profile.id
        );

        return user;
    }

    /* This method is used for creating a record using a dynamic reference. The record id is returned.
     * Use this when implementing field defaults for child objects that have required parent relationships
     * so that the framework stays independent of the database model
     * @param record [sObject: the record]
     * @return       [sObject: the record, inserted and with defualt fields populated]
     */
    public static Id createRecord(String objectName, String recordType) {
        sObject record = Schema.getGlobalDescribe().get(ObjectName).newSObject();
        if (String.isNotBlank(recordType)) {
            record.put(
                'RecordTypeId',
                Schema.getGlobalDescribe()
                    .get(objectName)
                    .getDescribe()
                    .getRecordTypeInfosByDeveloperName()
                    .get(recordType)
                    .getRecordTypeId()
            );
        }
        return (Id) createRecord(record, true).get('Id');
    }

    /* This method is used for creating a record. Default fields are populated before it's returned
     * @param record    [sObject: the record]
     * @param doInsert  [Boolean: true if the record is to be inserted, false otherwise]
     * @return          [sObject: the record, with defualt fields populate]
     */
    public static sObject createRecord(sObject record, Boolean doInsert) {
        Type t = getDefaultClassName(record);
        if (t != null) {
            FieldDefaults defaults = (FieldDefaults) t.newInstance();
            addFieldDefaults(record, defaults);
        }
        if (doInsert)
            insert record;
        return record;
    }

    /* This method is used for creating a list of records. The list is inserted before it's returned,
     * and default fields are populated.
     * @param record    [sObject: a sObject record]
     * @param numRecords[Integer: the number of records to create]
     * @return          [List<sObject>: the list of sObjects, with defualt fields populate]
     */
    public static list<sObject> createRecordList(sObject record, Integer numRecords) {
        return createRecordList(record, numRecords, true);
    }

    /* This method is used for creating a list of records. Default fields are populated before it's returned.
     * @param record    [sObject: a sObject record]
     * @param length    [Integer: the length of the list]
     * @param doInsert  [Boolean: true if the list is to be inserted, false otherwise]
     * @return          [List<sObject>: the list of sObjects, with defualt fields populate]
     */
    public static List<sObject> createRecordList(sObject record, Integer numRecords, Boolean doInsert) {
        List<sObject> records = new List<sObject>();
        for (Integer i = 0; i < numRecords; i++) {
            records.add(record.clone(false, false, false, false));
        }
        return createRecordList(records, doInsert);
    }

    /* This method is used for creating a list of record. The list is inserted before it's returned,
     * and default fields are populated.
     * @param record    [List<sObject>: a list of records]
     * @return          [List<sObject>: the list of records, with default fields populated]
     */
    public static List<sObject> createRecordList(List<sObject> records) {
        return createRecordList(records, true);
    }

    /* This method is used for creating a list of records. Default fields are populated before it's returned.
     * @param record    [List<sObject>: a list of records]
     * @param doInsert  [Boolean: true if the list is to be inserted, false otherwise]
     * @return          [List<sObject>: the list of sObjects, with defualt fields populated]
     */
    public static List<sObject> createRecordList(List<sObject> records, Boolean doInsert) {
        String objectName = String.valueOf(records[0].getSObjectType());
        Map<String, List<sObject>> relationListMap = new Map<String, List<sObject>>();
        Type t = getDefaultClassName(records[0]);
        if (t != null) {
            FieldDefaults defaults = (FieldDefaults) t.newInstance();
            if (!defaults.getDmlFields().isEmpty()) {
                //If there are any fielddefaults that require dml we bulkifyify these
                relationListMap = bulkifyifyRelations(defaults.getDmlFields(), records.size());
            }
            for (Integer i = 0; i < records.size(); i++) {
                addFieldDefaults(records[i], defaults, i, relationListMap);
                String uniqFieldName = uniqueField.get(objectName);
                if (uniqFieldName == null) {
                    continue;
                }
                if (objectName != 'User')
                    records[i].put(uniqFieldName, 'Test ' + i);
                if (objectName == 'User')
                    records[i].put(uniqFieldName, generateRandomUsername());
            }
        }
        if (doInsert)
            insert records;
        return records;
    }

    public static Map<String, List<sObject>> bulkifyifyRelations(Map<String, String> dmlFields, Integer numRecords) {
        //Mapping a list of related records to a dml field
        Map<String, List<sObject>> relationListMap = new Map<String, List<sObject>>();

        for (String field : dmlFields.keySet()) {
            String objectName = dmlFields.get(field);
            sObject record = Schema.getGlobalDescribe().get(ObjectName).newSObject();
            List<sObject> relationList = createRecordList(record, numRecords);
            relationListMap.put(field, relationList);
        }

        return relationListMap;
    }

    // Used, when creating a list, to define which fields should be unique among the records.
    public static final Map<String, String> uniqueField = new Map<String, String>{
        'Contact' => 'LastName',
        'User' => 'Username',
        'QuickText' => 'Name',
        'NavUnit__c' => 'Name'
    };

    /* This method is used for retrieving the type that corresponds to the class we want to use. The class
     * is used to set default field values.
     * @param record    [sObject: a record]
     * @return          [Type: the type that corresponds to the class]
     */
    public static Type getDefaultClassName(sObject record) {
        String objectName = String.valueOf(record.getSObjectType());
        String namespacePrefix = '';
        String className =
            'HOT_ST_TestDataFactory.' +
            objectName.replaceAll('__c|__|_|' + namespacePrefix, '') +
            'Defaults';
        return Type.forName(className);
    }

    /* This method adds default fields to the record if they are blank
     * @param record    [sObject: the record]
     * @param defaults  [Map<String,Object>: map between defualt field names and values]
     */
    public static void addFieldDefaults(sObject record, FieldDefaults defaults) {
        Map<String, Object> fieldDefaults = defaults.getFieldDefaults();
        for (String field : fieldDefaults.keySet()) {
            if (record.get(field) == null) {
                record.put(field, fieldDefaults.get(field));
            }
        }
    }

    /* This method adds defaults and handles bulkifyification when a set of records are created that also
     * requires the creation of related records
     * @param record    [sObject: the record]
     * @param defaults  [Map<String,Object>: map between defualt field names and values]
     */
    public static void addFieldDefaults(
        sObject record,
        FieldDefaults defaults,
        Integer index,
        Map<String, List<sObject>> relationListMap
    ) {
        Map<String, Object> fieldDefaults = defaults.getFieldDefaults(true);
        for (String field : fieldDefaults.keySet()) {
            if (record.get(field) == null) {
                if (defaults.getDmlFields().containsKey(field) && relationListMap.containsKey(field)) {
                    List<sObject> relationList = relationListMap.get(field);
                    record.put(field, (Id) relationList[index].get('Id'));
                } else {
                    record.put(field, fieldDefaults.get(field));
                }
            }
        }
    }

    //      HELPER METHODS              //
    // Helper methods needed for record creation

    /**
     * @description: Generation of random string to be used for i.e. setting
     * required unique fields for test data.
     * @author Stian Ruud Schikora | 10-12-2020
     * @param len
     * @return String
     **/
    public static String generateRandomString(Integer len) {
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
        String randStr = '';
        while (randStr.length() < len) {
            Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
            randStr += chars.substring(idx, idx + 1);
        }
        return randStr;
    }

    public static String generateRandomUsername() {
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ', '').replace(':', '').replace('-', '');
        String rand = generateRandomString(4);
        return orgId + dateString + rand + '@test.com';
    }

    /**
     * @description: Generates a string of random numbers of given length
     * Used for i.e. generating random person idents.
     * @author Stian Ruud Schikora | 10-12-2020
     * @param len
     * @return String
     **/
    public static String generateRandomNumberString(Integer len) {
        final String chars = '0123456789';
        String randStr = '';
        while (randStr.length() < len) {
            Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
            randStr += chars.substring(idx, idx + 1);
        }
        return randStr;
    }

    // Field defaults for all objects
    public interface FieldDefaults {
        Map<String, Object> getFieldDefaults(Boolean bulkify); //When bulkify is true, the name of the object should be returned instead of direct creation to enable recursive bulkification
        Map<String, Object> getFieldDefaults();
        Map<String, String> getDmlFields(); //Mapping the field name to the object type for the default
    }

    //        OBJECT DEFAULTS           //
    // The following classes defines default field values. When a field is made required on an
    // object, a default value should be defined for it in the object's respective class

    public class UserDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return getFieldDefaults(false);
        }
        public Map<String, Object> getFieldDefaults(Boolean bulkify) {
            return new Map<String, Object>{
                'FirstName' => 'Test',
                'LastName' => 'Testesen' + generateRandomString(6),
                'Username' => generateRandomString(8) + '@test.com',
                'LanguageLocaleKey' => 'no',
                'TimeZoneSidKey' => 'Europe/Paris',
                'LocaleSidKey' => 'no_NO',
                'EmailEncodingKey' => 'UTF-8',
                'Department' => '1',
                'ProfileId' => [SELECT Id FROM Profile WHERE Name = 'Standard User' OR Name = 'Standardbruker' LIMIT 1]
                .Id,
                'Alias' => generateRandomString(8),
                'Email' => generateRandomString(8) + '@test.com',
                'isActive' => true,
                'username' => generateRandomUsername()
            };
        }
        public Map<String, String> getDmlFields() {
            return new Map<String, String>{};
            //No dml fields
        }
    }

    public class ContactDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return getFieldDefaults(false);
        }
        public Map<String, Object> getFieldDefaults(Boolean bulkify) {
            return new Map<String, Object>{ 'FirstName' => 'Test', 'LastName' => 'Testesen' };
        }
        public Map<String, String> getDmlFields() {
            return new Map<String, String>{};
            //No dml fields
        }
    }

    public class EntitlementDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return getFieldDefaults(false);
        }
        public Map<String, Object> getFieldDefaults(Boolean bulkify) {
            return new Map<String, Object>{ 'Name' => 'STO Entitlement' };
        }
        public Map<String, String> getDmlFields() {
            return new Map<String, String>{};
            //No dml fields
        }
    }

    public class CampaignDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return getFieldDefaults(false);
        }
        public Map<String, Object> getFieldDefaults(Boolean bulkify) {
            return new Map<String, Object>{ 'Name' => 'Test', 'Status' => 'Active', 'isActive' => true };
        }
        public Map<String, String> getDmlFields() {
            return new Map<String, String>{};
            //No dml fields
        }
    }

    public class AccountDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return getFieldDefaults(false);
        }
        public Map<String, Object> getFieldDefaults(Boolean bulkify) {
            return new Map<String, Object>{ 'Name' => 'Test Testesen' };
        }
        public Map<String, String> getDmlFields() {
            return new Map<String, String>{};
            //No dml fields
        }
    }

    public class LeadDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return getFieldDefaults(false);
        }
        public Map<String, Object> getFieldDefaults(Boolean bulkify) {
            return new Map<String, Object>{ 'LastName' => 'Test Testesen', 'Company' => 'Test Company' };
        }
        public Map<String, String> getDmlFields() {
            return new Map<String, String>{};
            //No dml fields
        }
    }

    public class TaskDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return getFieldDefaults(false);
        }
        public Map<String, Object> getFieldDefaults(Boolean bulkify) {
            return new Map<String, Object>{ 'Priority' => 'High', 'Status' => 'In Progress' };
        }
        public Map<String, String> getDmlFields() {
            return new Map<String, String>{};
            //No dml fields
        }
    }

    public class OrderDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return getFieldDefaults(false);
        }
        public Map<String, Object> getFieldDefaults(Boolean bulkify) {
            return new Map<String, Object>{
                'Name' => 'Test Testesen',
                'AccountId' => bulkify ? 'Account' : createRecord('Account', null),
                'EffectiveDate' => Date.today(),
                'Status' => 'Draft',
                'PriceBook2Id' => Test.getStandardPricebookId()
            };
        }
        public Map<String, String> getDmlFields() {
            return new Map<String, String>{ 'AccountId' => 'Account' };
        }
    }

    public class OrderItemDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return getFieldDefaults(false);
        }
        public Map<String, Object> getFieldDefaults(Boolean bulkify) {
            return new Map<String, Object>{
                'PriceBookEntryId' => bulkify ? 'PriceBookEntry' : createRecord('PricebookEntry', null),
                'OrderId' => bulkify ? 'Order' : createRecord('Order', null),
                'Quantity' => 1,
                'UnitPrice' => 100
            };
        }
        public Map<String, String> getDmlFields() {
            return new Map<String, String>{ 'OrderId' => 'Order', 'PriceBookEntryId' => 'PriceBookEntry' };
        }
    }

    public class PriceBookEntryDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return getFieldDefaults(false);
        }
        public Map<String, Object> getFieldDefaults(Boolean bulkify) {
            return new Map<String, Object>{
                'PriceBook2Id' => Test.getStandardPricebookId(),
                'Product2Id' => bulkify ? 'Product2' : createRecord('Product2', null),
                'isActive' => true,
                'UnitPrice' => 100
            };
        }
        public Map<String, String> getDmlFields() {
            return new Map<String, String>{ 'Product2Id' => 'Product2' };
        }
    }

    public class Product2Defaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return getFieldDefaults(false);
        }
        public Map<String, Object> getFieldDefaults(Boolean bulkify) {
            return new Map<String, Object>{ 'Name' => 'SF Merch', 'ProductCode' => '1234', 'isActive' => true };
        }
        public Map<String, String> getDmlFields() {
            return new Map<String, String>{};
            //No dml fields
        }
    }

    public class OpportunityDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return getFieldDefaults(false);
        }
        public Map<String, Object> getFieldDefaults(Boolean bulkify) {
            return new Map<String, Object>{
                'Name' => 'Test Opportunity',
                'CloseDate' => Date.today(),
                'StageName' => 'Closed Won',
                'Amount' => 100,
                'CampaignId' => bulkify ? 'Campaign' : createRecord('Campaign', null)
            };
        }
        public Map<String, String> getDmlFields() {
            return new Map<String, String>{ 'CampaignId' => 'Campaign' };
        }
    }

    public class LiveChatTranscriptDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return getFieldDefaults(false);
        }
        public Map<String, Object> getFieldDefaults(Boolean bulkify) {
            return new Map<String, Object>{
                'LiveChatVisitorId' => bulkify ? 'LiveChatVisitor' : createRecord('LiveChatVisitor', null)
            };
        }
        public Map<String, String> getDmlFields() {
            return new Map<String, String>{ 'LiveChatVisitorId' => 'LiveChatVisitor' };
        }
    }

    public class LiveChatVisitorDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return getFieldDefaults(false);
        }
        public Map<String, Object> getFieldDefaults(Boolean bulkify) {
            return new Map<String, Object>{};
            //No defaults
        }
        public Map<String, String> getDmlFields() {
            return new Map<String, String>{};
            //No dml fields
        }
    }

    public class QuickTextDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return getFieldDefaults(false);
        }
        public Map<String, Object> getFieldDefaults(Boolean bulkify) {
            return new Map<String, Object>{ 'Message' => 'Dette er en melding' };
        }
        public Map<String, String> getDmlFields() {
            return new Map<String, String>{};
            //No dml fields
        }
    }

    public class PersonDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return getFieldDefaults(false);
        }
        public Map<String, Object> getFieldDefaults(Boolean bulkify) {
            return new Map<String, Object>{ 'Name' => generateRandomNumberString(11) };
        }
        public Map<String, String> getDmlFields() {
            return new Map<String, String>{};
            //No dml fields
        }
    }

    public class AsyncRequestDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return getFieldDefaults(false);
        }
        public Map<String, Object> getFieldDefaults(Boolean bulkify) {
            return new Map<String, Object>{
                'CRM_Params__c' => generateRandomString(18),
                'CRM_Status__c' => AsyncRequestService.STATUS_PENDING,
                'CRM_AsyncType__c' => 'TEST_TYPE'
            };
        }
        public Map<String, String> getDmlFields() {
            return new Map<String, String>{};
            //No dml fields
        }
    }

    public class NavTaskDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return getFieldDefaults(false);
        }
        public Map<String, Object> getFieldDefaults(Boolean bulkify) {
            return new Map<String, Object>{
                'CRM_DueDate__c' => Date.today(),
                'CRM_NoPersonInformation__c' => true,
                'CRM_Account__c' => bulkify ? 'Account' : createRecord('Account', null)
            };
        }
        public Map<String, String> getDmlFields() {
            return new Map<String, String>{ 'CRM_Account__c' => 'Account' };
        }
    }

    public class ConversationNoteDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return getFieldDefaults(false);
        }
        public Map<String, Object> getFieldDefaults(Boolean bulkify) {
            return new Map<String, Object>{
                'CRM_Case__c' => bulkify ? 'Case' : createRecord('Case', null),
                'CRM_Account__c' => bulkify ? 'Account' : createRecord('Account', null)
            };
        }
        public Map<String, String> getDmlFields() {
            return new Map<String, String>{ 'CRM_Account__c' => 'Account', 'CRM_Case__c' => 'Case' };
        }
    }

    public class NavUnitDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return getFieldDefaults(false);
        }
        public Map<String, Object> getFieldDefaults(Boolean bulkify) {
            return new Map<String, Object>{ 'Name' => 'NAV test unit' };
        }
        public Map<String, String> getDmlFields() {
            return new Map<String, String>{};
            //No dml fields
        }
    }

    public class CommonCodeDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults() {
            return getFieldDefaults(false);
        }
        public Map<String, Object> getFieldDefaults(Boolean bulkify) {
            return new Map<String, Object>{ 'Name' => 'Test Name', 'CRM_Active__c' => true };
        }
        public Map<String, String> getDmlFields() {
            return new Map<String, String>{};
            //No dml fields
        }
    }
}
