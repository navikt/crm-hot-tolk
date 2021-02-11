public class MaskinportenService {
    @TestVisible
    private String encodedJWT;
    @TestVisible
    List<Maskinportenclient__mdt> clients;

    public MaskinportenService(String clientDeveloperName) {
        // Find MaskinportenClient custom metadata record for the given client
        this.clients = [
            SELECT
                Id,
                Endpoint__c,
                Audience__c,
                Issuer__c,
                KeyId__c,
                PrivateKey__c,
                Scopes__c
            FROM Maskinportenclient__mdt
            WHERE DeveloperName = :clientDeveloperName
        ];
    }

    public AuthResponse doMaskinportenJWTExchange() {
        if (clients.isEmpty())
            return null;
        Maskinportenclient__mdt client = clients[0];

        // Initialize HttpRequest
        HttpRequest req = new HttpRequest();
        req.setEndpoint(client.Endpoint__c);
        req.setMethod('POST');
        req.setHeader('Content-type', 'application/x-www-form-urlencoded');

        // Set body with JWT assertion
        this.encodedJWT = new JWT(client).issue();
        String postBody = 'grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer';
        postBody += '&assertion=' + encodedJWT;
        req.setBody(postBody);

        // Do callout, parse body, and return parsed response
        HttpResponse res = new Http().send(req);
        return (AuthResponse) Json.deserialize(
            res.getBody(),
            AuthResponse.class
        );
    }

    public class AuthResponse {
        public String access_token;
        Integer expires_in;
        String scope;
    }
}
