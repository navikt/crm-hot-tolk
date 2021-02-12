@IsTest
public class KrrCalloutServiceTest {
    @IsTest
    public static void testSingleSuccesfulPersonOppslag() {
        // Get the KRR maskinporten client in order to map the endpoint to a mock response
        MaskinportenClient__mdt krrClient = [
            SELECT Endpoint__c
            FROM Maskinportenclient__mdt
            WHERE
                DeveloperName = :Test.isRunningTest()
                    ? 'salesforce_krr_test'
                    : 'salesforce_krr'
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
            '{"personer":[{"personidentifikator":"01048800153","reservasjon":"NEI","status":"AKTIV","varslingsstatus":"KAN_VARSLES","kontaktinformasjon":{"epostadresse":"01048800153-test@minid.norge.no","epostadresse_sist_verifisert":"2020-01-14T17:57:58+01","mobiltelefonnummer":"+4799999999","mobiltelefonnummer_sist_verifisert":"2020-01-14T17:57:58+01"}}]}',
            null
        );

        // Map responses to callout endpoints and set mock
        Map<String, HttpCalloutMock> mockResponseByEndpoint = new Map<String, HttpCalloutMock>();
        mockResponseByEndpoint.put(krrClient.Endpoint__c, maskinPortenResponse);
        mockResponseByEndpoint.put(
            'https://difiKrrExampleEndpoint.no',
            krrResponse
        );
        HttpCalloutMock multiCalloutMock = new MultiRequestMock(
            mockResponseByEndpoint
        );
        Test.setMock(HttpCalloutMock.class, multiCalloutMock);

        Test.startTest();
        List<KRRCalloutService.Personer> personer = KrrCalloutService.doPersonOppslag(
            new List<String>{ '01048800153' }
        );
        Test.stopTest();

        // Assert that result has been correctly parsed
        System.assertEquals(1, personer.size());
        System.assertEquals(personer[0].personidentifikator, '01048800153');
        System.assertEquals(
            personer[0].kontaktinformasjon.epostadresse,
            '01048800153-test@minid.norge.no'
        );
        System.assertEquals(
            personer[0].kontaktinformasjon.mobiltelefonnummer,
            '+4799999999'
        );
    }

    @IsTest
    public static void testMultipleSuccesfulPersonOppslag() {
        // Get the KRR maskinporten client in order to map the endpoint to a mock response
        MaskinportenClient__mdt krrClient = [
            SELECT Endpoint__c
            FROM Maskinportenclient__mdt
            WHERE
                DeveloperName = :Test.isRunningTest()
                    ? 'salesforce_krr_test'
                    : 'salesforce_krr'
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
            '{"personer":[{"personidentifikator":"01048800153","reservasjon":"NEI","status":"AKTIV","varslingsstatus":"KAN_VARSLES","kontaktinformasjon":{"epostadresse":"01048800153-test@minid.norge.no","epostadresse_sist_verifisert":"2020-01-14T17:57:58+01","mobiltelefonnummer":"+4799999999","mobiltelefonnummer_sist_verifisert":"2020-01-14T17:57:58+01"}},{"personidentifikator":"01066100746","reservasjon":"NEI","status":"AKTIV","varslingsstatus":"KAN_VARSLES","kontaktinformasjon":{"epostadresse":"01066100746-test@minid.norge.no","epostadresse_sist_verifisert":"2018-11-05T15:27:22+01","mobiltelefonnummer":"+4799999999","mobiltelefonnummer_sist_verifisert":"2018-11-05T15:27:22+01"}},{"personidentifikator":"27129323960","reservasjon":"NEI","status":"AKTIV","varslingsstatus":"KAN_IKKE_VARSLES","kontaktinformasjon":{"epostadresse":"27129323960-test@minid.norge.no","epostadresse_oppdatert":"2015-03-11T19:59:13+01","mobiltelefonnummer":"+4799999999","mobiltelefonnummer_oppdatert":"2015-03-11T19:59:13+01"}}]}',
            null
        );

        // Map responses to callout endpoints and set mock
        Map<String, HttpCalloutMock> mockResponseByEndpoint = new Map<String, HttpCalloutMock>();
        mockResponseByEndpoint.put(krrClient.Endpoint__c, maskinPortenResponse);
        mockResponseByEndpoint.put(
            'https://difiKrrExampleEndpoint.no',
            krrResponse
        );
        HttpCalloutMock multiCalloutMock = new MultiRequestMock(
            mockResponseByEndpoint
        );
        Test.setMock(HttpCalloutMock.class, multiCalloutMock);

        Test.startTest();
        List<KRRCalloutService.Personer> personer = KrrCalloutService.doPersonOppslag(
            new List<String>{ '01048800153', '01066100746', '27129323960' }
        );
        Test.stopTest();

        // Assert that result has been correctly parsed
        System.assertEquals(3, personer.size());
        System.assertEquals(personer[0].personidentifikator, '01048800153');
        System.assertEquals(
            personer[0].kontaktinformasjon.epostadresse,
            '01048800153-test@minid.norge.no'
        );
        System.assertEquals(personer[1].personidentifikator, '01066100746');
        System.assertEquals(
            personer[1].kontaktinformasjon.epostadresse,
            '01066100746-test@minid.norge.no'
        );
        System.assertEquals(personer[2].personidentifikator, '27129323960');
        System.assertEquals(
            personer[2].kontaktinformasjon.epostadresse,
            '27129323960-test@minid.norge.no'
        );
    }

    @IsTest
    public static void testSingleUnsuccesfulPersonOppslag() {
        // Get the KRR maskinporten client in order to map the endpoint to a mock response
        MaskinportenClient__mdt krrClient = [
            SELECT Endpoint__c
            FROM Maskinportenclient__mdt
            WHERE
                DeveloperName = :Test.isRunningTest()
                    ? 'salesforce_krr_test'
                    : 'salesforce_krr'
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
            '{"personer":[{"personidentifikator":"24999412372","status":"IKKE_REGISTRERT","varslingsstatus":"KAN_IKKE_VARSLES"}]}',
            null
        );

        // Map responses to callout endpoints and set mock
        Map<String, HttpCalloutMock> mockResponseByEndpoint = new Map<String, HttpCalloutMock>();
        mockResponseByEndpoint.put(krrClient.Endpoint__c, maskinPortenResponse);
        mockResponseByEndpoint.put(
            'https://difiKrrExampleEndpoint.no',
            krrResponse
        );
        HttpCalloutMock multiCalloutMock = new MultiRequestMock(
            mockResponseByEndpoint
        );
        Test.setMock(HttpCalloutMock.class, multiCalloutMock);

        Test.startTest();
        List<KRRCalloutService.Personer> personer = KrrCalloutService.doPersonOppslag(
            new List<String>{ '24999412372' }
        );
        Test.stopTest();

        // Assert that result has been correctly parsed
        System.assertEquals(1, personer.size());
        System.assertEquals(personer[0].personidentifikator, '24999412372');
        System.assertEquals(personer[0].kontaktinformasjon, null);
    }
}
