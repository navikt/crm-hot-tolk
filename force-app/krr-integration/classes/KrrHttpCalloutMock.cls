public  class KrrHttpCalloutMock implements HttpCalloutMock {

    public HTTPResponse respond(HttpRequest request) {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('{"personer":[{"personidentifikator":"24079412372","reservasjon":"NEI","status":"AKTIV","varslingsstatus":"KAN_VARSLES","kontaktinformasjon":{"epostadresse":"24079412372-test@minid.norge.no","epostadresse_oppdatert":"2020-01-21T18:20:53+01","epostadresse_sist_verifisert":"2020-01-21T18:20:55+01"}}]}');
        response.setStatusCode(200);
        return response;
    }

}