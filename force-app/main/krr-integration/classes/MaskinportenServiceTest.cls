@IsTest
public class MaskinportenServiceTest {
    @IsTest
    public static void testDoMaskinportenJWTExchange() {
        // Set mock maskinporten response. Returned access token is hardcoded "super-secret-access-token".
        SingleRequestMock mockResponse = new SingleRequestMock(
            200,
            'Complete',
            '{"access_token": "super-secret-access-token", "token_type": "Bearer", "expires_in": 119, "scope": "global/kontaktinformasjon.read global/spraak.read global/sikkerdigitalpost.read global/varslingsstatus.read"}',
            null
        );
        Test.setMock(HttpCalloutMock.class, mockResponse);

        // Query for actual Maskinporten client custom metadata. Used to assert that the JWT has been constructed properly.
        MaskinportenClient__mdt krrClient = [
            SELECT
                Id,
                Endpoint__c,
                Audience__c,
                Issuer__c,
                KeyId__c,
                PrivateKey__c,
                Scopes__c
            FROM Maskinportenclient__mdt
            WHERE
                DeveloperName = :Test.isRunningTest()
                    ? 'salesforce_krr_test'
                    : 'salesforce_krr'
            LIMIT 1
        ];

        // Initialize the MaskinportenService with the developername of the client custom metadata record
        MaskinportenService ms = new MaskinportenService(
            Test.isRunningTest() ? 'salesforce_krr_test' : 'salesforce_krr'
        );

        // Perform token exchange and assert that the response is correctly parsed
        MaskinportenService.AuthResponse response = ms.doMaskinportenJWTExchange();
        System.assertEquals('super-secret-access-token', response.access_token);

        // Parse the constructed JWT in order to verify that the header and claim values correspond to the custom metadata record passed in
        String encodedJWT = ms.encodedJWT;

        // Header, claims and signature are separated with '.'
        Integer headerLength = encodedJWT.indexOf('.');
        Integer claimsLength = encodedJWT.lastIndexOf('.');
        String jwtHeaders = encodedJWT.left(headerLength);
        String jwtClaims = encodedJWT.mid(
            headerLength + 1,
            claimsLength -
            headerLength -
            1
        );

        // Decode the base64 values and and deserialize them into inner classes
        JWTHeader headerDeserialized = (JWTHeader) Json.deserialize(
            EncodingUtil.base64Decode(jwtHeaders).toString(),
            JWTHeader.class
        );
        JWTClaims claimsDeserialized = (JWTClaims) Json.deserialize(
            EncodingUtil.base64Decode(jwtClaims).toString(),
            JWTClaims.class
        );

        // Assert that the MaskinportenClient__mdt record values match the JWT
        System.assertEquals(krrClient.KeyId__c, headerDeserialized.kid);
        System.assertEquals(krrClient.Audience__c, claimsDeserialized.aud);
        System.assertEquals(krrClient.Issuer__c, claimsDeserialized.iss);
        System.assertEquals(krrClient.Scopes__c, claimsDeserialized.scope);
    }

    private class JWTHeader {
        String alg;
        String kid;
    }

    private class JWTClaims {
        String iss;
        String aud;
        String scope;
    }
}
