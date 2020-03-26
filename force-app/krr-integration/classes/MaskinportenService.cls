public class MaskinportenService {

    public static MaskinportenResponse doMaskinportenJWTExchange(String clientDeveloperName) {
        // Find MaskinportenClient custom metadata record for the given client
        List<Maskinportenclient__mdt> clients = [
                SELECT Id, Endpoint__c, Audience__c, Issuer__c, KeyId__c, PrivateKey__c, Scopes__c
                FROM Maskinportenclient__mdt
                WHERE DeveloperName = :clientDeveloperName
        ];
        if (clients.isEmpty()) return null;
        Maskinportenclient__mdt client = clients[0];

        // Initialize HttpRequest
        HttpRequest req = new HttpRequest();
        req.setEndpoint(client.Endpoint__c);
        req.setMethod('POST');
        req.setHeader('Content-type', 'application/x-www-form-urlencoded');

        // Set body with JWT assertion
        String postBody = 'grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer';
        postBody += '&assertion=' + new JWT(client).issue();
        req.setBody(postBody);

        // Do callout, parse body, and return parsed response
        HttpResponse res = new Http().send(req);
        return (MaskinportenResponse) Json.deserialize(res.getBody(), MaskinportenResponse.class);
    }

    public class MaskinportenResponse {
        public String access_token;
        Integer expires_in;
        String scope;
    }
}