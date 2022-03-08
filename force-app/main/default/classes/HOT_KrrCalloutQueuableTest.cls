@isTest
private class HOT_KrrCalloutQueuableTest {
    @TestSetup
    static void makeData() {
        Person__c person1 = HOT_TestDataFactory.createPerson();
        person1.Name = '01048800153';
        person1.INT_KrrIntegrationStatus__c = 'Queued';
        Person__c person2 = HOT_TestDataFactory.createPerson();
        person2.Name = '01066100746';
        person2.INT_KrrIntegrationStatus__c = 'Queued';
        Person__c person3 = HOT_TestDataFactory.createPerson();
        person3.Name = '24999412372';
        person3.INT_KrrIntegrationStatus__c = 'Queued';
        Person__c person4 = HOT_TestDataFactory.createPerson();
        person4.Name = '27129323960';
        person4.INT_KrrIntegrationStatus__c = 'Queued';
        insert new List<Person__c>{ person1, person2, person3, person4 };

        WorkType workType = HOT_TestDataFactory.createWorkType();
        insert workType;
        HOT_Request__c request1 = HOT_TestDataFactory.createRequest('Subject', workType);
        request1.Person__c = person1.Id;
        HOT_Request__c request2 = HOT_TestDataFactory.createRequest('Subject', workType);
        request2.Person__c = person2.Id;
        HOT_Request__c request3 = HOT_TestDataFactory.createRequest('Subject', workType);
        request3.Person__c = person3.Id;
        HOT_Request__c request4 = HOT_TestDataFactory.createRequest('Subject', workType);
        request4.Person__c = person4.Id;

        insert new List<HOT_Request__c>{ request1, request2, request3, request4 };
    }

    @IsTest
    public static void testMethod123() {
        // Get the KRR maskinporten client in order to map the endpoint to a mock response
        MaskinportenClient__mdt krrClient = [
            SELECT Endpoint__c
            FROM Maskinportenclient__mdt
            WHERE DeveloperName = :Test.isRunningTest() ? 'salesforce_krr_test' : 'salesforce_krr'
            LIMIT 1
        ];

        // Construct mock responses for all callouts that will be performed
        SingleRequestMock maskinPortenResponse = new SingleRequestMock(
            200,
            'Complete',
            '{"access_token": "super-secret-access-token", "token_type": "Bearer", "expires_in": 119, "scope": "global/kontaktinformasjon.read global/spraak.read global/sikkerdigitalpost.read global/varslingsstatus.read"}',
            null
        );
        SingleRequestMock krrResponse = new SingleRequestMock(
            200,
            'Complete',
            '{"personer":[{"personidentifikator":"01048800153","reservasjon":"NEI","status":"AKTIV","varslingsstatus":"KAN_VARSLES","kontaktinformasjon":{"epostadresse":"01048800153-test@minid.norge.no","epostadresse_sist_verifisert":"2020-01-14T17:57:58+01","mobiltelefonnummer":"+4799999999","mobiltelefonnummer_sist_verifisert":"2020-01-14T17:57:58+01"}},{"personidentifikator":"01066100746","reservasjon":"NEI","status":"AKTIV","varslingsstatus":"KAN_VARSLES","kontaktinformasjon":{"epostadresse":"01066100746-test@minid.norge.no","epostadresse_sist_verifisert":"2018-11-05T15:27:22+01","mobiltelefonnummer":"+4799999999","mobiltelefonnummer_sist_verifisert":"2018-11-05T15:27:22+01"}},{"personidentifikator":"27129323960","reservasjon":"NEI","status":"AKTIV","varslingsstatus":"KAN_IKKE_VARSLES","kontaktinformasjon":{"epostadresse":"27129323960-test@minid.norge.no","epostadresse_oppdatert":"2015-03-11T19:59:13+01","mobiltelefonnummer":"+4799999999","mobiltelefonnummer_oppdatert":"2015-03-11T19:59:13+01"}}, {"personidentifikator":"24999412372","status":"IKKE_REGISTRERT","varslingsstatus":"KAN_IKKE_VARSLES"}]}',
            null
        );

        // Map responses to callout endpoints and set mock
        Map<String, HttpCalloutMock> mockResponseByEndpoint = new Map<String, HttpCalloutMock>();
        mockResponseByEndpoint.put(krrClient.Endpoint__c, maskinPortenResponse);
        mockResponseByEndpoint.put('https://difiKrrExampleEndpoint.no', krrResponse);
        HttpCalloutMock multiCalloutMock = new MultiRequestMock(mockResponseByEndpoint);
        Test.setMock(HttpCalloutMock.class, multiCalloutMock);

        Test.startTest();
        // HOT_KRRCalloutQueuable krr = new HOT_KRRCalloutQueuable([SELECT Id FROM HOT_Request__c]);
        List<KRRCalloutService.Personer> personer = KrrCalloutService.doPersonOppslag(
            new List<String>{ '01048800153', '01066100746', '27129323960', '24999412372' }
        );
        Test.stopTest();

        List<Person__c> persons = [
            SELECT
                Id,
                Name,
                INT_KrrMobilePhone__c,
                INT_KrrEmail__c,
                INT_KrrIntegrationStatus__c,
                INT_LastUpdatedFromKRR__c
            FROM Person__c
            ORDER BY Name ASC
        ];
        for (Person__c person : persons) {
            System.debug(person);
        }

        // Assert that result has been correctly parsed
        System.assertEquals(4, persons.size());
        System.assertEquals(persons[0].Name, '01048800153');
        System.assertEquals(persons[0].INT_KrrEmail__c, '01048800153-test@minid.norge.no');
        System.assertEquals(persons[1].Name, '01066100746');
        System.assertEquals(persons[1].INT_KrrEmail__c, '01066100746-test@minid.norge.no');
        System.assertEquals(persons[2].Name, '27129323960');
        System.assertEquals(persons[2].INT_KrrEmail__c, '27129323960-test@minid.norge.no');

        System.assertEquals(persons[3].Name, '24999412372');
        System.assertEquals(persons[3].INT_KrrEmail__c, '');
    }
}
