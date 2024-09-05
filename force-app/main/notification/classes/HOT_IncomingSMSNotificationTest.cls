@isTest
private class HOT_IncomingSMSNotificationTest {
    @TestSetup
    static void makeData(){
        Account acc = new Account();
        acc.Name = 'Gunnar Gunn Gundersen';
        insert acc;
    }

    @isTest
    static void getGroupIdsFromSendersTest() {
        List<Account> accounts = TestDataFactory_Community.getPersonAccounts(3);
        List<Person__c> persons = new List<Person__c>();

        for( Account acc : accounts ) {
            Person__c person = [
                SELECT 
                    Id, 
                    CRM_Account__c, 
                    INT_MunicipalityNumber__c, 
                    INT_RegionNumber__c 
                FROM Person__c 
                WHERE CRM_Account__c = :acc.Id];
            persons.add(person);
        }


        persons[0].INT_MunicipalityNumber__c = String.valueOf(3216); //Vestby
        persons[0].INT_RegionNumber__c = '0' + String.valueOf(2); //Akershus

        persons[1].INT_MunicipalityNumber__c = String.valueOf(5001); //Trondheim 
        persons[1].INT_RegionNumber__c = String.valueOf(50); //Trøndelag

        persons[2].INT_MunicipalityNumber__c = String.valueOf(3407); //Gjøvik 
        persons[2].INT_RegionNumber__c = String.valueOf(34); // Innlandet

        ApexSharingRule__mdt regionOslo = [
            SELECT Id, DeveloperName FROM ApexSharingRule__mdt
            WHERE DeveloperName = 'HOT_Person_03_Municipality'
        ];

        ApexSharingRule__mdt regionTrondelag = [
            SELECT Id, DeveloperName FROM ApexSharingRule__mdt
            WHERE DeveloperName = 'HOT_Person_50' 
        ];

        ApexSharingRule__mdt regionInnlandet = [
            SELECT Id, DeveloperName FROM ApexSharingRule__mdt
            WHERE DeveloperName = 'HOT_Person_34_Region'
        ];



        Test.startTest();
        List<Id> groupIds = HOT_IncomingSMSNotification.getGroupIdsFromSenders(persons);
        Test.stopTest();

        System.assertEquals(regionOslo.Id, groupIds[0], 'Person 0 should belong to Oslo region');
        System.assertEquals(regionTrondelag.Id, groupIds[1], 'Person 1 should belong to trondelag region');
        System.assertEquals(regionInnlandet.Id, groupIds[2], 'Person 2 should belong to Innlandet region');
    }

    @isTest
    static void shouldNotifyDispatchersAboutSMSTest() {
        Account acc = [SELECT Id, Name FROM Account WHERE Name = 'Gunnar Gunn Gundersen'];
        SMS__c testSMS = new SMS__c();
        testSMS.Domain__c = 'HOT';
        testSMS.Type__c = 'Incoming SMS';
        testSMS.Recipient__c = HOT_IncomingSMSNotification.DISPATCH_INCOMING_NUMBER;
        testSMS.Account__c = acc.Id;

        Test.startTest();
        Boolean shouldNotify = 
            HOT_IncomingSMSNotification.shouldNotifyDispatchersAboutSMS(testSMS);
        Test.stopTest();

        System.assertEquals(true, shouldNotify, 'SMS should trigger notification of dispatchers');
    }
}