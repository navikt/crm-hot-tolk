public class KrrCalloutService {
    public static List<Personer> doPersonOppslag(
        List<String> personIdentifikatorer
    ) {
        // Initialize request format
        if (personIdentifikatorer.isEmpty())
            return null;
        PersonOppslagRequest requestBody = new PersonOppslagRequest();
        requestBody.personidentifikatorer = personIdentifikatorer;

        // Obtain access token from Maskinporten
        String access_token = new MaskinportenService(
                Test.isRunningTest() ? 'salesforce_krr_test' : 'salesforce_krr'
            )
            .doMaskinportenJWTExchange()
            .access_token;

        // Initialize HttpRequest
        HttpRequest req = new HttpRequest();
        String endpoint = Test.isRunningTest()
            ? 'https://difiKrrExampleEndpoint.no'
            : 'callout:Kontaktregisteret_Oppslagstjenesten_REST'; // Use sample endpoint for tests in order to be able to mock response
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setHeader('Content-type', 'application/json;charset=UTF-8');
        req.setHeader('Accept', '*/*');
        req.setHeader('Authorization', 'Bearer ' + access_token);
        req.setBody(JSON.serialize(requestBody));
        HttpResponse res = new Http().send(req);
        PersonOppslagResponse response = (PersonOppslagResponse) Json.deserialize(
            res.getBody(),
            PersonOppslagResponse.class
        );
        return response.personer;
    }

    private class PersonOppslagRequest {
        List<String> personidentifikatorer;
    }

    private class PersonOppslagResponse {
        List<Personer> personer;
    }

    public class Personer {
        public String personidentifikator;
        String reservasjon;
        String status;
        String varslingsstatus;
        public Kontaktinformasjon kontaktinformasjon;
    }

    public class Kontaktinformasjon {
        public String epostadresse;
        public Datetime epostadresse_oppdatert;
        public Datetime epostadresse_sist_verifisert;
        public String mobiltelefonnummer;
        public Datetime mobiltelefonnummer_oppdatert;
        public Datetime mobiltelefonnummer_sist_verifisert;
    }
}
