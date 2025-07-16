public with sharing class HOT_PersonBadgesController {
    /**
     * @description Get an apex type holding all the data we need for showing badges.
     */
    @AuraEnabled(cacheable=true)
    public static PersonBadgeData getPersonBadgesAndInfo(
        String field,
        String parentObject,
        String parentRecordId,
        Boolean filterOpenSTO
    ) {
        Id personId = getPersonId(field, parentObject, parentRecordId);
        Person__c person = getPerson(personId);
        PersonBadgeData badges = new PersonBadgeData(person);
        return badges;
    }

    /**
     * @description Dynamically find the person ID
     * Example: field = 'Account.CRM_Person__c', parentObject = 'Case', parentRecordId = '5001X000007xMSuQAM'
     */
    private static Id getPersonId(String field, String parentObject, String parentRecordId) {
        String queryString = 'SELECT ' + field + ' FROM ' + parentObject + ' WHERE Id = :parentRecordId LIMIT 1';
        List<SObject> objList = Database.query(String.escapeSingleQuotes(queryString));
        return !objList.isEmpty() ? (Id) getFieldValue(objList[0], field) : null;
    }

    /**
     * @description recursive method for collecting the value of a field on a sObject
     */
    private static Object getFieldValue(SObject obj, String fieldName) {
        if (obj == null) {
            return null;
        }
        List<String> fieldNameList = fieldName.split('\\.');

        return fieldNameList.size() > 1
            ? getFieldValue(obj.getSObject(fieldNameList.remove(0)), String.join(fieldNameList, '.'))
            : obj.get(fieldNameList[0]);
    }

    /**
     * @description The get Person query is made dynamic in order to use some HOT fields without having a package dependency.
     */
    private static Person__c getPerson(Id personId) {
        Set<String> objectFields = Schema.SObjectType.Person__c.fields.getMap().keySet();
        Set<String> fields = new Set<String>{
            'Id',
            'INT_GuardianshipOrFuturePowerOfAttorney__c',
            'INT_PowerOfAttorney__c',
            'INT_KRR_Reservation__c'
        };

        String queryString = 'SELECT ';
        for (String str : fields) {
            if (objectFields.contains(str.toLowerCase())) {
                queryString += str += ', ';
            }
        }

        queryString +=
            '(' +
            '	SELECT Id,' +
            '		INT_Person__c,' +
            '		toLabel(INT_SecurityMeasure__c),' +
            '		INT_ValidFromDate__c,' +
            '		INT_ValidToDate__c' +
            '	FROM SecurityMeasures__r' +
            ')';
        queryString += ' FROM Person__c WHERE Id = :personId';

        List<Person__c> personList = (List<Person__c>) Database.query(queryString);
        return personList.isEmpty() ? null : personList[0];
    }

    /**
     * @description Apex type as an inner class. The constructor accepts a person record to populate all the variables.
     */
    public class PersonBadgeData {
        @AuraEnabled
        public List<Badge> badges;
        @AuraEnabled
        public List<GuardianshipOrFuturePowerOfAttorney> guardianships;
        @AuraEnabled
        public List<PowerOfAttorney> powerOfAttorneys;
        @AuraEnabled
        public List<String> errors;

        private Person__c person;
        private Set<String> fieldSet;
        private Map<String, String> personIdentNameMap;

        public PersonBadgeData(Person__c person) {
            this.badges = new List<Badge>();
            this.guardianships = new List<GuardianshipOrFuturePowerOfAttorney>();
            this.powerOfAttorneys = new List<PowerOfAttorney>();
            this.errors = new List<String>();
            this.personIdentNameMap = new Map<String, String>();
            // this.entitlements = new List<String>();

            if (person != null) {
                this.person = person;
                //Get field set for use later in the class
                this.fieldSet = Schema.SObjectType.Person__c.fields.getMap().keySet();
                setBadgeData();
            }
        }

        private void setBadgeData() {
            setPowerOfAttorney();
            setGuardianshipOrFuturePowerOfAttorney();
            setPersonName();
            setKrrReservation();
        }

        private void setKrrReservation() {
            if (person.INT_KRR_Reservation__c) {
                badges.add(new Badge('krr', getFieldLabel('INT_KRR_Reservation__c')));
            }
        }

        private void setPowerOfAttorney() {
            try {
                List<HOT_FullmaktController.Fullmaktsgiver> fullmaktsgivere = (List<HOT_FullmaktController.Fullmaktsgiver>) HOT_FullmaktController.getFullmaktsgiver(
                    person.Id,
                    'Person__c'
                );
                filterFullmaktOmraade(fullmaktsgivere);

                if (fullmaktsgivere == null || fullmaktsgivere.isEmpty())
                    return;

                Date today = Date.today();
                for (Integer i = 0; i < fullmaktsgivere.size(); i++) {
                    HOT_FullmaktController.Fullmaktsgiver fullmaktsgiver = fullmaktsgivere[i];

                    if (
                        fullmaktsgiver.gyldigFraOgMed <= today &&
                        (fullmaktsgiver.gyldigTilOgMed >= today ||
                        fullmaktsgiver.gyldigTilOgMed == null)
                    ) {
                        PowerOfAttorney poa = new PowerOfAttorney();
                        poa.motpartsPersonident = fullmaktsgiver.motpartsPersonident;
                        poa.omraader = fullmaktsgiver.omraader;
                        poa.gyldigFraOgMed = fullmaktsgiver.gyldigFraOgMed;
                        poa.gyldigTilOgMed = fullmaktsgiver.gyldigTilOgMed;
                        poa.motpartsNavn = fullmaktsgiver.motpartsNavn;
                        poa.motpartsRolle = fullmaktsgiver.motpartsRolle;

                        poa.id = String.valueOf(i);
                        personIdentNameMap.put(poa.motpartsPersonident, '');
                        powerOfAttorneys.add(poa);
                    }
                }

                if (!powerOfAttorneys.isEmpty()) {
                    badges.add(
                        new Badge(
                                'powerOfAttorney',
                                'Fullmakt',
                                'slds-theme_warning slds-m-left_x-small slds-m-vertical_xx-small pointer yellowBadge',
                                '',
                                '',
                                true
                            )
                            .setBadgeContent(powerOfAttorneys)
                    );
                }
            } catch (Exception e) {
                errors.add('Feil ved uthenting av fullmakts detaljer:\n' + e.getMessage());
            }
        }

        private void filterFullmaktOmraade(List<HOT_FullmaktController.Fullmaktsgiver> fullmaktsgivere) {
            if (fullmaktsgivere == null || fullmaktsgivere.isEmpty())
                return;

            for (Integer i = (fullmaktsgivere.size() - 1); i >= 0; i--) {
                HOT_FullmaktController.Fullmaktsgiver fullmakt = fullmaktsgivere[i];
                for (Integer j = (fullmakt.omraader.size() - 1); j >= 0; j--) {
                    HOT_FullmaktController.Omraade omraade = fullmakt.omraader[j];
                    if (omraade.handling.contains('KOMMUNISER') || omraade.handling.contains('SKRIV')) {
                        continue;
                    }
                    fullmakt.omraader.remove(j);
                }
                if (fullmakt.omraader == null || fullmakt.omraader.isEmpty()) {
                    fullmaktsgivere.remove(i);
                }
            }
        }

        private void setGuardianshipOrFuturePowerOfAttorney() {
            if (String.isNotBlank(person.INT_GuardianshipOrFuturePowerOfAttorney__c)) {
                try {
                    List<GuardianShipOrFuturePowerOfAttorney> guardianshipList = (List<GuardianshipOrFuturePowerOfAttorney>) JSON.deserialize(
                        person.INT_GuardianshipOrFuturePowerOfAttorney__c,
                        List<GuardianshipOrFuturePowerOfAttorney>.class
                    );
                    for (Integer i = 0; i < guardianshipList.size(); i++) {
                        GuardianShipOrFuturePowerOfAttorney guardianship = guardianshipList[i];
                        guardianship.id = String.valueOf(i);
                        if (String.isNotBlank(guardianship.actualMotpartsPersonident)) {
                            personIdentNameMap.put(guardianship.actualMotpartsPersonident, '');
                        }
                        guardianships.add(guardianship);
                    }
                } catch (Exception e) {
                    errors.add('Feil ved uthenting av vergemål detaljer');
                }

                badges.add(
                    new Badge(
                            'guardianshipOrFuturePowerOfAttorney',
                            'Vergemål',
                            'slds-theme_warning slds-m-left_x-small slds-m-vertical_xx-small pointer yellowBadge',
                            '',
                            '',
                            true
                        )
                        .setBadgeContent(guardianships)
                );
            }
        }

        private void setPersonName() {
            for (Account acc : [
                SELECT Name, CRM_Person__r.Name, CRM_Person__r.NKS_Full_Name__c
                FROM Account
                WHERE CRM_Person__c != NULL AND CRM_Person__r.Name IN :personIdentNameMap.keySet()
                WITH SYSTEM_MODE
            ]) {
                String name = String.isNotBlank(acc.CRM_Person__r.NKS_Full_Name__c)
                    ? acc.CRM_Person__r.NKS_Full_Name__c
                    : acc.Name;
                personIdentNameMap.put(acc.CRM_Person__r.Name, name);
            }

            for (GuardianshipOrFuturePowerOfAttorney gofoa : guardianships) {
                String name = personIdentNameMap.get(gofoa.actualMotpartsPersonident);
                if (String.isNotBlank(name)) {
                    gofoa.actualNavn = new Navn(name);
                }
            }

            for (PowerOfAttorney poa : powerOfAttorneys) {
                String name = personIdentNameMap.get(poa.motpartsPersonident);
                if (String.isNotBlank(name)) {
                    poa.motpartsNavn = name;
                }
            }
        }

        private String getFieldLabel(String fieldApiName) {
            SObjectType type = Person__c.sObjectType;
            Map<String, Schema.SObjectField> mfields = type.getDescribe().fields.getMap();
            return mfields.get(fieldApiName).getDescribe().getLabel();
        }
    }

    public class Badge {
        @AuraEnabled
        public String name;
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String styling;
        @AuraEnabled
        public String iconName;
        @AuraEnabled
        public String iconAltText;
        @AuraEnabled
        public Boolean clickable;
        @AuraEnabled
        public String tabindex;
        @AuraEnabled
        public String badgeInfo; //Optional additional info to be sent to frontend
        @AuraEnabled
        public List<BadgeContent> badgeContent;
        @AuraEnabled
        public String badgeContentType {
            get {
                if (this.badgeContent == null || this.badgeContent?.size() == 0)
                    return null;
                return String.valueOf(this.badgeContent[0]).split(':')[0]; // Returns the name of the class instance
            }
        }

        /**
         * @description Constructor for only showing a badge without any formatting or logic
         * @param name name to use in the LWC to identify the badge
         * @param label the label for the badge
         *
         */
        public Badge(String name, String label) {
            this(
                name,
                label,
                'slds-theme_warning slds-m-left_x-small slds-m-vertical_xx-small yellowBadge',
                '',
                '',
                false
            );
        }

        /**
         * @description Constructor for showing badge with formatting or icons
         * @param name  name to use in the LWC to identify the badge
         * @param label the label for the badge
         * @param styling styling to use on the component in the LWC
         * @param iconName icon to use in the LWC, use the icons from SF
         * @param iconAltText alt text to add to the icon
         * @param clickable true if the user should be able to click on the badge to show more info
         */
        public Badge(
            String name,
            String label,
            String styling,
            String iconName,
            String iconAltText,
            Boolean clickable
        ) {
            this.name = name;
            this.label = label;
            this.styling = styling;
            this.iconName = iconName;
            this.iconAltText = iconAltText;
            this.clickable = clickable;
            this.tabindex = this.clickable ? '0' : '-1';
        }

        /**
         * @description Constructor for showing badge with formatting or icons
         * @param name  name to use in the LWC to identify the badge
         * @param label the label for the badge
         * @param styling styling to use on the component in the LWC
         * @param iconName icon to use in the LWC, use the icons from SF
         * @param iconAltText alt text to add to the icon
         * @param clickable true if the user should be able to click on the badge to show more info
         */
        public Badge(
            String name,
            String label,
            String styling,
            String iconName,
            String iconAltText,
            Boolean clickable,
            String badgeInfo
        ) {
            this(name, label, styling, iconName, iconAltText, clickable);
            this.badgeInfo = badgeInfo;
        }

        public Badge setBadgeContent(List<BadgeContent> content) {
            this.badgeContent = content;
            return this;
        }

        public Badge setBadgeContent(BadgeContent content) {
            this.badgeContent = new List<BadgeContent>{ content };
            return this;
        }
    }

    public interface BadgeContent {
    }

    public class PowerOfAttorney extends HOT_FullmaktController.Fullmaktsgiver implements BadgeContent {
    }

    public class Navn {
        @AuraEnabled
        public String fornavn;
        @AuraEnabled
        public String mellomnavn;
        @AuraEnabled
        public String etternavn;
        public Navn(String navn) {
            fornavn = navn;
        }
        @AuraEnabled
        public String fullName {
            get {
                return String.join(new List<String>{ this.fornavn, this.mellomnavn, this.etternavn }, ' ')
                    .normalizeSpace();
            }
        }
    }

    public class Tjenesteomraade {
        @AuraEnabled
        public String tjenesteoppgave;
        @AuraEnabled
        public String tjenestevirksomhet;
    }

    public class GuardianshipOrFuturePowerOfAttorney implements BadgeContent {
        // Common between both old and new
        @AuraEnabled
        public String type;
        @AuraEnabled
        public String embete;
        @AuraEnabled
        public String id;

        // Old format
        @AuraEnabled
        public Navn navn;
        @AuraEnabled
        public String motpartsPersonident;
        @AuraEnabled
        public String omfang;
        @AuraEnabled
        public Boolean omfangetErInnenPersonligOmraade;

        // New format
        @AuraEnabled
        public VergeEllerFullmektig vergeEllerFullmektig;

        @AuraEnabled
        public String omfangLabel {
            get {
                String actualOmfang = vergeEllerFullmektig != null ? vergeEllerFullmektig.omfang : omfang;
                String label = this.omfangMap.get(actualOmfang);
                return String.isNotBlank(label) ? label : actualOmfang;
            }
        }

        @AuraEnabled
        public String omfangetErInnenPersonligOmraadeTxt {
            get {
                Boolean actualOmfangetErInnenPersonligOmraade = vergeEllerFullmektig != null ? vergeEllerFullmektig.omfangetErInnenPersonligOmraade : omfangetErInnenPersonligOmraade;
                return true == actualOmfangetErInnenPersonligOmraade ? 'Ja' : 'Nei';
            }
        }

        @AuraEnabled
        public Navn actualNavn {
            get {
                return vergeEllerFullmektig != null ? vergeEllerFullmektig.navn : navn;
            }
            set {
                if(vergeEllerFullmektig != null){
                    vergeEllerFullmektig.navn = value;
                } else {
                    navn = value;
                }
            }
        }

        @AuraEnabled
        public String actualMotpartsPersonident {
            get {
                return vergeEllerFullmektig != null ? vergeEllerFullmektig.motpartsPersonident : motpartsPersonident;
            }
        }

        @AuraEnabled
        public String motpartLabel {
            get {
                List<String> retString = new List<String>();
                if (String.isNotEmpty(this.actualNavn?.fullName)) {
                    retString.add(this.actualNavn.fullName);
                }
                if (String.isNotEmpty(this.actualMotpartsPersonIdent)) {
                    retString.add(this.actualMotpartsPersonident);
                }

                return String.join(retString, ' - ');
            }
        }

        private Map<String, String> typeMap {
            get {
                return new Map<String, String>{
                    'ensligMindreaarigAsylsoeker' => 'Enslig mindreårig asylsøker',
                    'ensligMindreaarigFlyktning' => 'Enslig mindreårig flyktning inklusive midlertidige saker for denne gruppen',
                    'voksen' => 'Voksen',
                    'midlertidigForVoksen' => 'Voksen midlertidig',
                    'mindreaarig' => 'Mindreårig (unntatt EMF)',
                    'midlertidigForMindreaarig' => 'Mindreårig midlertidig (unntatt EMF)',
                    'forvaltningUtenforVergemaal' => 'Forvaltning utenfor vergemål',
                    'stadfestetFremtidsfullmakt' => 'Fremtidsfullmakt'
                };
            }
        }

        @AuraEnabled
        public String typeLabel {
            get {
                String label = this.typeMap.get(this.type);
                return String.isNotBlank(label) ? label : this.type;
            }
        }

        private Map<String, String> omfangMap {
            get {
                return new Map<String, String>{
                    'utlendingssakerPersonligeOgOekonomiskeInteresser' => 'Ivareta personens interesser innenfor det personlige og økonomiske området herunder utlendingssaken (kun for EMA)',
                    'personligeOgOekonomiskeInteresser' => 'Ivareta personens interesser innenfor det personlige og økonomiske området',
                    'oekonomiskeInteresser' => 'Ivareta personens interesser innenfor det økonomiske området',
                    'personligeInteresser' => 'Ivareta personens interesser innenfor det personlige området'
                };
            }
        }

    }

    public class VergeEllerFullmektig {
        @AuraEnabled
        public String motpartsPersonident;
        @AuraEnabled
        public List<Tjenesteomraade> tjenesteomraade;
        @AuraEnabled
        public Navn navn;
        @AuraEnabled
        public String omfang;
        @AuraEnabled
        public Boolean omfangetErInnenPersonligOmraade;

        @AuraEnabled
        public String tjenesteomraadeLabel {
            get {
                String label = '';
                if (this.tjenesteomraade != null) {
                    for (Tjenesteomraade omraade : this.tjenesteomraade) {
                        if (omraade.tjenestevirksomhet == 'nav') {
                            label +=
                                omraade.tjenesteoppgave.replaceAll('([A-Z])', ' $1').toLowerCase().capitalize() + ', ';
                        }
                    }
                }
                return label.removeEnd(', ');
            }
        }
    }
}
