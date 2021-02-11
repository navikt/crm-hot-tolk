public class JWT {
    public String alg { get; set; }
    public String iss { get; set; }
    public String sub { get; set; }
    public String aud { get; set; }
    public String exp { get; set; }
    public String iat { get; set; }
    public String kid { get; set; }
    public Map<String, String> claims { get; set; }
    public Integer validFor { get; set; }
    public String cert { get; set; }
    public String pkcs8 { get; set; }
    public String privateKey { get; set; }

    public static final String HS256 = 'HS256';
    public static final String RS256 = 'RS256';
    public static final String NONE = 'none';

    public JWT(String alg) {
        this.alg = alg;
        this.validFor = 10;
    }

    public JWT(Maskinportenclient__mdt client) {
        this('RS256');
        this.iss = client.Issuer__c;
        this.aud = client.Audience__c;
        this.kid = client.KeyId__c;
        this.claims = new Map<String, String>{ 'scope' => client.Scopes__c };
        if (Test.isRunningTest()) {
            // Set fake private key in test mode
            this.pkcs8 = 'MIIEpAIBAAKCAQEAr+tNkpfoGybSjwmWLvFZc2kPQUDDn1yGRSQX8+ulKNoWdGY9PceiTs2KWD2hE1rIx6kVERW2rbR0VDUNTMFo/ThEKMUEKANG4Nlz7alCXL6Tn2yveJbqmaM3IxC5wGmmsYycZMGiV0zX2TUNQRnQxcc9KF9TDWyEz7diExtYZNpMdEWBkNYJAFy93glb4xz98gCE1RPx2ieNBbFYr4flNlIlgtmcu0Xv7EX3hnAiN9nf/YylNHMekYe4vd/tw7zV40hxGhgaQsgkZN8VBkyJZZ8Homvw+zMe9x9vgHB9cqRJgjsBKWsXcr679WDkBYpUQN5Y3UI3/DJK9QsP8JCtZQIDAQABAoIBAF8zTXWJc3hOGCCEJZwdzDSipDjB3Zt+LMN59uRvn59t9jzjnzyxrmpK3RVHtMWOmZ1DKT1nrMZwI4v2cc4Z1MFEE86kX81viInh49S3hkw+bhEWdhciRK8EHrCBOqSgCC+JUpFMIJhx41WOWi/i0pJVcglJHN7k3TKzoQWKBNn+R69K2GHBukXTq53NhzxBnSCRQIF4c8GLAOSmswjjDzO3zjAU2MASVcjUYW+BQvqsqMVOn7RX+9uV4Q2EZStm5P7UHBLJuHSMV472jRGobHI3Mz74WScheesIa0i3Ry/X6v9ae2j4sss+PfqPw6PLWHy4lC2mUYg3rFzwm8orIcECgYEA/Ml3Ii/QEzCD/Y/dOGZ24fZqyuYtq07oXriMKs0SB5gZJWdStSSY4W8k5BfzsP8K9JnHC2fjTy101BmzUumycd98/385Dgdg9GNMrNswQD9apAVne6bQSqMyYgRbokai8Bb1KqNvB+iWvHAFaIuH1UG1iUcF+6tarwwl9GfhfJ0CgYEAsie4XAaBqki5Biqt+MVx/50uyYxSNRck45wv78SXRVLBq434kg+aAGtbWoRd2R7w4Li0krB8O6NK4x2LcmNYKBAHXNMWhIrxEYWE+xmlan4sNkvfoVmQbSIPc8XGaN8CGArBSs/tR5FPJ7hrrbB/+ZNMM81sAu1pCWe2HKeDhWkCgYEAs3xEx5RVVFq9TRuKApLWVGjHuNsokBsN6Lt2YqmK5LN9H062rgGXP3HQKthK4mCkobpSVunjvwNSkYrSBcwDNNFvimYF180rbTrYZV+YafXR4OYpbOWrvWMU0f2wJo+q/3f9idHTczUVWiTb4jg4MRZf1GIGgIRRdjrU9C2SMA0CgYA7m96rq+GmwD5oOc+L9UR3anhFJ5Y5/Uxye8fuSbDzmQUECbSp6l501XbzimZ8R0YBasvAaRyoN7LO2wvVcjgE75gHDvnxzytp2WrtOV+Hij/wyuJAcl9IpKTW7827OSLSOIcEKR4TXCNH/wTIUM4BC6/rhUgmkpkadIEShVoUQQKBgQCdaMsD4JXyoNLCw4DTs7V3BeQGDtdN4nykjvYNwJdmpwfQvbfHfI8FKrGABYMuVIWzquNrZrhkaZ6MZaH8Yp75aS2D9imO4OXSOSl4ogyIb6uy8fjI8rYlV1bkDf0qxU5J73Mnth7JLwSQ1pMleKQdIlR1RLZ45s2OowtIFVPt8w==';
        } else {
            this.pkcs8 = client.PrivateKey__c;
        }
    }

    public String issue() {
        String jwt = '';

        JSONGenerator header = JSON.createGenerator(false);
        header.writeStartObject();
        header.writeStringField('alg', this.alg);
        header.writeStringField('kid', this.kid);
        header.writeEndObject();
        String encodedHeader = base64URLencode(
            Blob.valueOf(header.getAsString())
        );

        JSONGenerator body = JSON.createGenerator(false);
        body.writeStartObject();
        body.writeStringField('iss', this.iss);
        body.writeStringField('aud', this.aud);
        Long rightNow = (dateTime.now().getTime() / 1000) + 1;
        body.writeNumberField('iat', rightNow);
        body.writeNumberField('exp', (rightNow + validFor));
        if (claims != null) {
            for (String claim : claims.keySet()) {
                body.writeStringField(claim, claims.get(claim));
            }
        }
        body.writeEndObject();

        jwt =
            encodedHeader +
            '.' +
            base64URLencode(Blob.valueOf(body.getAsString()));

        if (this.alg == HS256) {
            Blob key = EncodingUtil.base64Decode(privateKey);
            Blob signature = Crypto.generateMac(
                'hmacSHA256',
                Blob.valueof(jwt),
                key
            );
            jwt += '.' + base64URLencode(signature);
        } else if (this.alg == RS256) {
            Blob signature = null;

            if (cert != null) {
                signature = Crypto.signWithCertificate(
                    'rsa-sha256',
                    Blob.valueOf(jwt),
                    cert
                );
            } else {
                Blob privateKey = EncodingUtil.base64Decode(pkcs8);
                signature = Crypto.sign(
                    'rsa-sha256',
                    Blob.valueOf(jwt),
                    privateKey
                );
            }
            jwt += '.' + base64URLencode(signature);
        } else if (this.alg == NONE) {
            jwt += '.';
        }
        return jwt;
    }

    public String base64URLencode(Blob input) {
        String output = encodingUtil.base64Encode(input);
        output = output.replace('+', '-');
        output = output.replace('/', '_');
        while (output.endsWith('=')) {
            output = output.subString(0, output.length() - 1);
        }
        return output;
    }
}
