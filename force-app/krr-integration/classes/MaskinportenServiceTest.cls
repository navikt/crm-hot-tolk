@IsTest
public class MaskinportenServiceTest {

    @IsTest
    public static void testDoMaskinportenJWTExchange() {
        // Set mock maskinporten response. Returned access token is hardcoded "super-secret-access-token".
        SingleRequestMock mockResponse = new SingleRequestMock(200, 'Complete', '{"access_token": "super-secret-access-token", "token_type": "Bearer", "expires_in": 119, "scope": "global/kontaktinformasjon.read global/spraak.read global/sikkerdigitalpost.read global/varslingsstatus.read"}', null);
        Test.setMock(HttpCalloutMock.class, mockResponse);


        // Query for actual Maskinporten client custom metadata. Used to assert that the JWT has been constructed properly.
        MaskinportenClient__mdt krrClient =  [
                SELECT Id, Endpoint__c, Audience__c, Issuer__c, KeyId__c, PrivateKey__c, Scopes__c
                FROM Maskinportenclient__mdt
                WHERE DeveloperName = 'salesforce_krr'
                LIMIT 1
        ];

        // Initialize the MaskinportenService with the developername of the client custom metadata record
        MaskinportenService ms = new MaskinportenService('salesforce_krr');

        // Initialize and inject a fake private key in order to not rely on an actual private key being present in a given environment
        String fakePrivateKey = 'MIIEpAIBAAKCAQEAr+tNkpfoGybSjwmWLvFZc2kPQUDDn1yGRSQX8+ulKNoWdGY9PceiTs2KWD2hE1rIx6kVERW2rbR0VDUNTMFo/ThEKMUEKANG4Nlz7alCXL6Tn2yveJbqmaM3IxC5wGmmsYycZMGiV0zX2TUNQRnQxcc9KF9TDWyEz7diExtYZNpMdEWBkNYJAFy93glb4xz98gCE1RPx2ieNBbFYr4flNlIlgtmcu0Xv7EX3hnAiN9nf/YylNHMekYe4vd/tw7zV40hxGhgaQsgkZN8VBkyJZZ8Homvw+zMe9x9vgHB9cqRJgjsBKWsXcr679WDkBYpUQN5Y3UI3/DJK9QsP8JCtZQIDAQABAoIBAF8zTXWJc3hOGCCEJZwdzDSipDjB3Zt+LMN59uRvn59t9jzjnzyxrmpK3RVHtMWOmZ1DKT1nrMZwI4v2cc4Z1MFEE86kX81viInh49S3hkw+bhEWdhciRK8EHrCBOqSgCC+JUpFMIJhx41WOWi/i0pJVcglJHN7k3TKzoQWKBNn+R69K2GHBukXTq53NhzxBnSCRQIF4c8GLAOSmswjjDzO3zjAU2MASVcjUYW+BQvqsqMVOn7RX+9uV4Q2EZStm5P7UHBLJuHSMV472jRGobHI3Mz74WScheesIa0i3Ry/X6v9ae2j4sss+PfqPw6PLWHy4lC2mUYg3rFzwm8orIcECgYEA/Ml3Ii/QEzCD/Y/dOGZ24fZqyuYtq07oXriMKs0SB5gZJWdStSSY4W8k5BfzsP8K9JnHC2fjTy101BmzUumycd98/385Dgdg9GNMrNswQD9apAVne6bQSqMyYgRbokai8Bb1KqNvB+iWvHAFaIuH1UG1iUcF+6tarwwl9GfhfJ0CgYEAsie4XAaBqki5Biqt+MVx/50uyYxSNRck45wv78SXRVLBq434kg+aAGtbWoRd2R7w4Li0krB8O6NK4x2LcmNYKBAHXNMWhIrxEYWE+xmlan4sNkvfoVmQbSIPc8XGaN8CGArBSs/tR5FPJ7hrrbB/+ZNMM81sAu1pCWe2HKeDhWkCgYEAs3xEx5RVVFq9TRuKApLWVGjHuNsokBsN6Lt2YqmK5LN9H062rgGXP3HQKthK4mCkobpSVunjvwNSkYrSBcwDNNFvimYF180rbTrYZV+YafXR4OYpbOWrvWMU0f2wJo+q/3f9idHTczUVWiTb4jg4MRZf1GIGgIRRdjrU9C2SMA0CgYA7m96rq+GmwD5oOc+L9UR3anhFJ5Y5/Uxye8fuSbDzmQUECbSp6l501XbzimZ8R0YBasvAaRyoN7LO2wvVcjgE75gHDvnxzytp2WrtOV+Hij/wyuJAcl9IpKTW7827OSLSOIcEKR4TXCNH/wTIUM4BC6/rhUgmkpkadIEShVoUQQKBgQCdaMsD4JXyoNLCw4DTs7V3BeQGDtdN4nykjvYNwJdmpwfQvbfHfI8FKrGABYMuVIWzquNrZrhkaZ6MZaH8Yp75aS2D9imO4OXSOSl4ogyIb6uy8fjI8rYlV1bkDf0qxU5J73Mnth7JLwSQ1pMleKQdIlR1RLZ45s2OowtIFVPt8w==';
        ms.clients[0].PrivateKey__c = fakePrivateKey;

        // Perform token exchange and assert that the response is correctly parsed
        MaskinportenService.AuthResponse response = ms.doMaskinportenJWTExchange();
        System.assertEquals('super-secret-access-token', response.access_token);

        // Parse the constructed JWT in order to verify that the header and claim values correspond to the custom metadata record passed in
        String encodedJWT = ms.encodedJWT;

        // Header, claims and signature are separated with '.'
        Integer headerLength = encodedJWT.indexOf('.');
        Integer claimsLength = encodedJWT.lastIndexOf('.');
        String jwtHeaders = encodedJWT.left(headerLength);
        String jwtClaims = encodedJWT.mid(headerLength + 1, claimsLength - headerLength - 1);

        // Decode the base64 values and and deserialize them into inner classes
        JWTHeader headerDeserialized = (JWTHeader) Json.deserialize(EncodingUtil.base64Decode(jwtHeaders).toString(), JWTHeader.class);
        JWTClaims claimsDeserialized = (JWTClaims) Json.deserialize(EncodingUtil.base64Decode(jwtClaims).toString(), JWTClaims.class);

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