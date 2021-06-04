@IsTest
private class UriEventServiceTest {
    @TestSetup
    static void makeData() {
        TestDataFactory.getPublicGroup('HMS Agder', 'group_47001');
        TestDataFactory.getPublicGroup('NKS Veiledere', 'group_41001');
        TestDataFactory.getPersons(1, true);
        TestDataFactory.getAccounts(1, true);
    }

    @IsTest
    private static void addPersonRelatedRecordsToLog_forHotRequest() {
        Person__c testPerson = [SELECT Id, Name, CRM_Account__c FROM Person__c LIMIT 1][0];
        HOT_Request__c request = new HOT_Request__c(Account__c = testPerson.CRM_Account__c, Person__c = testPerson.Id);
        insert request;

        List<UriEvent> uriEvents = new List<UriEvent>();
        uriEvents.add(
            new UriEvent(request.Id, DateTime.now(), 'HOT_Request__c', 'Read', 'user@user.nav.no', 'Standard')
        );

        Test.startTest();
        UriEventService.addPersonRelatedRecordsToLog(uriEvents);
        Test.stopTest();

        List<Log__c> logs = [
            SELECT CRM_PersonIdent__c
            FROM Log__c
            WHERE CRM_Type__c = 'LightningUriEvent' AND CRM_QueriedEntity__c = 'HOT_Request__c'
        ];
        System.assertEquals(1, logs.size(), 'One log element is created');
        System.assertEquals(
            testPerson.Name,
            logs[0].CRM_PersonIdent__c,
            'Log element should have persons fødselsr / dnr'
        );
    }
}
