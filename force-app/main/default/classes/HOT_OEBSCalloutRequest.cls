public with sharing class HOT_OEBSCalloutRequest {
    public String kilde;
    public String klasse;
    public String type;
    public String referanse;
    public String juridiskEnhet;
    public String dato;
    public String hbDato;
    public String valuta;

    public FakturaPart fakturaTil;
    public FakturaPart solgtTil;
    public FakturaPart betalendeKunde;

    public String betalingsbetingelse;
    public String forfallsdato;
    public String selger;

    public List<Fakturalinje> linjer;
    public List<Notat> notater;

    /*
     * Konstruktør
     */
    public HOT_OEBSCalloutRequest() {
        this.fakturaTil = new FakturaPart();
        this.solgtTil = new FakturaPart();
        this.betalendeKunde = new FakturaPart();

        this.linjer = new List<Fakturalinje>();
        this.notater = new List<Notat>();
    }

    public void addLinje(Fakturalinje linje) {
        if (this.linjer == null) {
            this.linjer = new List<Fakturalinje>();
        }

        this.linjer.add(linje);
    }

    public void addNotat(Notat notat) {
        if (this.notater == null) {
            this.notater = new List<Notat>();
        }

        this.notater.add(notat);
    }

    public class FakturaPart {
        public String navn;
        public String nummer;
        public String sted;
        public String adresse1;
        public String adresse2;
        public String adresse3;
    }

    public class Fakturalinje {
        public String nr;
        public String artikkel;
        public String beskrivelse;
        public String enhet;
        public String mengde;
        public String enhetspris;
        public String belop;
        public String avgiftsklassifisering;
        public String transaksjon;
        public List<Kontering> konteringer;

        public Fakturalinje() {
            this.konteringer = new List<Kontering>();
        }

        public void addKontering(Kontering kontering) {
            if (this.konteringer == null) {
                this.konteringer = new List<Kontering>();
            }
            this.konteringer.add(kontering);
        }
    }

    public class Kontering {
        public String linje;
        public String prosent;
        public String belop;
        public String hbKonto;
    }

    public class Notat {
        public String dato;
        public String notat;
    }

    /*
     * JSON serializer
     */
    public String toJson() {
        JSONGenerator gen = JSON.createGenerator(true);

        gen.writeStartObject();

        /*
         * Header
         */
        gen.writeStringField('Kilde', this.kilde);
        gen.writeStringField('Klasse', this.klasse);
        gen.writeStringField('Type', this.type);
        gen.writeStringField('Referanse', this.referanse);
        gen.writeStringField('Juridisk enhet', this.juridiskEnhet);

        gen.writeStringField('Dato', this.dato);
        gen.writeStringField('HB-dato', this.hbDato);

        gen.writeStringField('Valuta', this.valuta);

        /*
         * Faktura til
         */
        writeFakturaPart(gen, 'Faktura til', this.fakturaTil);

        /*
         * Solgt til
         */
        writeFakturaPart(gen, 'Solgt til', this.solgtTil);

        /*
         * Betalende kunde
         */
        writeFakturaPart(gen, 'Betalende kunde', this.betalendeKunde);

        /*
         * Faktura
         */
        gen.writeStringField('Betalingsbetingelse', this.betalingsbetingelse);

        gen.writeStringField('Forfallsdato', this.forfallsdato);

        gen.writeStringField('Selger', this.selger);

        /*
         * Linjer
         */
        gen.writeFieldName('Linjer');
        gen.writeStartArray();

        for (Fakturalinje linje : this.linjer) {
            gen.writeStartObject();

            gen.writeStringField('Nr', linje.nr);

            gen.writeStringField('Artikkel', linje.artikkel);

            gen.writeStringField('Beskrivelse', linje.beskrivelse);

            gen.writeStringField('Enhet', linje.enhet);

            gen.writeStringField('Mengde', linje.mengde);

            gen.writeStringField('Enhetspris', linje.enhetspris);

            gen.writeStringField('Beløp', linje.belop);

            gen.writeStringField('Avgiftsklassifisering', linje.avgiftsklassifisering);

            gen.writeStringField('Transaksjon', linje.transaksjon);

            /*
             * Konteringer
             */
            gen.writeFieldName('Konteringer');
            gen.writeStartArray();

            for (Kontering kontering : linje.konteringer) {
                gen.writeStartObject();

                gen.writeStringField('Linje', kontering.linje);

                gen.writeStringField('%', kontering.prosent);

                gen.writeStringField('Beløp', kontering.belop);

                gen.writeStringField('HB-Konto', kontering.hbKonto);

                gen.writeEndObject();
            }

            gen.writeEndArray();

            gen.writeEndObject();
        }

        gen.writeEndArray();

        /*
         * Notater
         */
        gen.writeFieldName('Notater');
        gen.writeStartArray();

        for (Notat notat : this.notater) {
            gen.writeStartObject();

            gen.writeStringField('Dato', notat.dato);

            gen.writeStringField('Notat', notat.notat);

            gen.writeEndObject();
        }

        gen.writeEndArray();

        gen.writeEndObject();

        return gen.getAsString();
    }

    /*
     * Private helper
     */
    private void writeFakturaPart(JSONGenerator gen, String prefix, FakturaPart part) {
        if (part == null) {
            return;
        }

        gen.writeStringField(prefix + ': Navn', part.navn);

        gen.writeStringField(prefix + ': Nummer', part.nummer);

        gen.writeStringField(prefix + ': Sted', part.sted);

        gen.writeStringField(prefix + ': Adresse 1', part.adresse1);

        gen.writeStringField(prefix + ': Adresse 2', part.adresse2);

        gen.writeStringField(prefix + ': Adresse 3', part.adresse3);
    }
}
