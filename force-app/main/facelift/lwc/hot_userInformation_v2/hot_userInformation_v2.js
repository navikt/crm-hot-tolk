import { LightningElement, wire, api } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { formatDate } from 'c/datetimeFormatter';
import { refreshApex } from '@salesforce/apex';

import updateKrrStatus from '@salesforce/apex/HOT_UserInformationController.updateKrrStatus';
import getPerson from '@salesforce/apex/HOT_UserInformationController.getPerson';
import getNotificationPickListValues from '@salesforce/apex/HOT_UserInformationController.getNotificationPickListValues';
import changeUserNotificationSetting from '@salesforce/apex/HOT_UserInformationController.changeUserNotificationSetting';

import MOBILEKRR from '@salesforce/schema/Person__c.INT_KrrMobilePhone__c';
import MOBILEOVERRIDE from '@salesforce/schema/Person__c.HOT_MobilePhoneOverride__c';
import MOBILEOVERRIDEREASON from '@salesforce/schema/Person__c.HOT_MobilePhoneOverrideReason__c';
import EMAIL from '@salesforce/schema/Person__c.INT_KrrEmail__c';
import DEGREE_OF_IMPAIRMENT from '@salesforce/schema/Person__c.HOT_DegreeOfHearingAndVisualImpairment__c';
import SIP_ADDRESS from '@salesforce/schema/Person__c.HOT_SIPAddress__c';
import icons from '@salesforce/resourceUrl/icons';

const FIELDS = [MOBILEKRR, MOBILEOVERRIDE, MOBILEOVERRIDEREASON, EMAIL, DEGREE_OF_IMPAIRMENT, SIP_ADDRESS];

export default class Hot_userInformation_v2 extends LightningElement {
    warningicon = icons + '/warningicon.svg';
    successicon = icons + '/successicon.svg';
    informationIcon = icons + '/informationicon.svg';

    @api recordId;

    mobilePhoneKRR;
    mobilePhoneOverride;
    mobilePhoneOverrideReason;
    email;
    degreeOfImpairment;
    sipAddress;

    person;
    options;
    selectedOption;
    newSelectedOption;
    isReservedAgainstNotifications;
    newIsReservedAgainstNotifications;

    workplaceInterpreter = false;
    dailyLifeInterpreter = false;
    educationInterpreter = false;
    interpreterAW = false;
    remoteInterpreter = false;
    signLanguage = false;
    writtenInterpreter = false;
    supportMouthReading = false;
    speechInterpreting = false;
    tactileSignLanguage = false;
    signLimitedView = false;
    hapticCommunication = false;
    escort = false;

    viewUserNotificationSettings = true;
    successMessage = '';
    showSuccess = false;
    securityMeasures;
    hasSecurityMeasures = false;

    picklistOptions = [
        { name: 'SMS', label: 'SMS', selected: false },
        { name: 'Push-varsel i appen', label: 'Push-varsel i appen', selected: false },
        { name: 'Reserver mot alle varsler', label: 'Reserver mot alle varsler', selected: false }
    ];

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredPerson({ error, data }) {
        if (data) {
            this.mobilePhoneOverride = data.fields.HOT_MobilePhoneOverride__c.value;
            this.mobilePhoneOverrideReason = data.fields.HOT_MobilePhoneOverrideReason__c.value;
            this.mobilePhoneKRR = data.fields.INT_KrrMobilePhone__c.value;
            this.email = data.fields.INT_KrrEmail__c.value;
            this.degreeOfImpairment = data.fields.HOT_DegreeOfHearingAndVisualImpairment__c.displayValue;
            this.sipAddress = data.fields.HOT_SIPAddress__c.value;
        } else if (error) {
            console.error('feil' + error);
        }
    }

    personWireResult;
    @wire(getPerson)
    wiredGetPerson(result) {
        this.personWireResult = result;
        if (result.data) {
            this.person = result.data;
            this.recordId = this.person.Id;
            this.selectedOption = this.person.HOT_NotificationChannel__c;
            this.isReservedAgainstNotifications = this.person.HOT_IsReservationAgainstNotifications__c;
            this.newSelectedOption = this.selectedOption;

            this.workplaceInterpreter = !!this.person.HOT_WorkplaceInterpreter__c;
            this.dailyLifeInterpreter = !!this.person.HOT_DailyLifeInterpreter__c;
            this.educationInterpreter = !!this.person.HOT_EducationInterpreter__c;
            this.interpreterAW = !!this.person.HOT_InterpreterAtWork__c;
            this.remoteInterpreter = !!this.person.HOT_RemoteInterpreter__c;
            this.signLanguage = !!this.person.HOT_SignLanguage__c;
            this.writtenInterpreter = !!this.person.HOT_WritenInterpreting__c;
            this.supportMouthReading = !!this.person.HOT_SignToSupportMouthReading__c;
            this.speechInterpreting = !!this.person.HOT_SpeechInterpreting__c;
            this.tactileSignLanguage = !!this.person.HOT_TactileSignLanguage__c;
            this.signLimitedView = !!this.person.HOT_SignLanguageWithLimitedFieldOfView__c;
            this.hapticCommunication = !!this.person.HOT_HapticCommunication__c;
            this.escort = !!this.person.HOT_Escort__c;

            getNotificationPickListValues({
                chosen: this.selectedOption
            }).then((data) => {
                this.options = data;
                this.picklistOptions = this.picklistOptions.map((option) => ({
                    ...option,
                    selected:
                        (this.isReservedAgainstNotifications && option.name === 'Reserver mot alle varsler') ||
                        (!this.isReservedAgainstNotifications && option.name === this.selectedOption)
                }));
            });
            if (this.person.INT_SecurityMeasures__c != null && this.person.INT_SecurityMeasures__c !== '') {
                this.hasSecurityMeasures = true;
                let secMeasures = JSON.parse(this.person.INT_SecurityMeasures__c);
                let securityMeasuresFormatted = [];
                secMeasures.forEach((sm) => {
                    securityMeasuresFormatted.push(
                        sm.beskrivelse +
                            ' (' +
                            sm.tiltaksType +
                            '), gyldig: ' +
                            formatDate(sm.gyldigFraOgMed) +
                            ' - ' +
                            formatDate(sm.gyldigTilOgMed)
                    );
                });
                this.securityMeasures = securityMeasuresFormatted;
            }
        }
    }

    get alternativePhoneNumberText() {
        return 'Du har registrert et alternativ nummer som benyttes til all SMS varsling fra Tolketjenesten. Ta kontakt med din lokale tolketjeneste om du ønsker å endre dette.';
    }
    get isAlternativeNumber() {
        return !!this.mobilePhoneOverride;
    }

    get vedtakLabels() {
        const items = [
            { label: 'Arbeidsliv', value: this.workplaceInterpreter },
            { label: 'Dagligliv', value: this.dailyLifeInterpreter },
            { label: 'Utdanning', value: this.educationInterpreter },
            { label: 'Tolk på arbeidsplass - TPA', value: this.interpreterAW },
            { label: 'Bildetolk', value: this.remoteInterpreter }
        ];
        return items.filter((i) => i.value).map((i) => i.label);
    }

    get tolkemetoderLabels() {
        const items = [
            { label: 'Tegnspråk', value: this.signLanguage },
            { label: 'Skrivetolking', value: this.writtenInterpreter },
            { label: 'Tegn til støtte som munnavlesning', value: this.supportMouthReading },
            { label: 'Taletolking', value: this.speechInterpreting },
            { label: 'Taktilt tegnspråk', value: this.tactileSignLanguage },
            { label: 'Tegnspråk i begrenset synsfelt', value: this.signLimitedView },
            { label: 'Haptisk kommunikasjon', value: this.hapticCommunication },
            { label: 'Ledsaging', value: this.escort }
        ];
        return items.filter((i) => i.value).map((i) => i.label);
    }

    get hasVedtak() {
        return this.vedtakLabels.length > 0;
    }

    get hasTolkemetoder() {
        return this.tolkemetoderLabels.length > 0;
    }

    setKrrIntegrationStatusToQueued() {
        var personCloned = JSON.parse(JSON.stringify(this.person));
        try {
            personCloned.INT_KrrIntegrationStatus__c = 'Queued';
            updateKrrStatus({ receivedPerson: personCloned });
        } catch (error) {
            console.log(error);
        }
    }

    get isKrrQueued() {
        return this.person?.INT_KrrIntegrationStatus__c === 'Queued';
    }

    selectionChangeHandler(event) {
        const selected = event.detail.value || event.detail.name || event.detail.selectedValue || event.detail;

        this.newSelectedOption = selected;

        // Update picklist state
        this.picklistOptions = this.picklistOptions.map((option) => {
            const isSelected = option.name === this.newSelectedOption;
            return { ...option, selected: isSelected };
        });

        if (this.newSelectedOption === 'Reserver mot alle varsler') {
            this.newIsReservedAgainstNotifications = true;
            this.newSelectedOption = null;
        } else {
            this.newIsReservedAgainstNotifications = false;
        }

        this.saveNotificationSettings();
    }

    saveNotificationSettings() {
        changeUserNotificationSetting({
            personId: this.recordId,
            newNotificationValue: this.newSelectedOption,
            isReservedAgainstNotifications: this.newIsReservedAgainstNotifications
        })
            .then(() => {
                return refreshApex(this.personWireResult);
            })
            .then(() => {
                // Update local state with refreshed data
                this.selectedOption = this.person.HOT_NotificationChannel__c;
                this.isReservedAgainstNotifications = this.person.HOT_IsReservationAgainstNotifications__c;

                this.picklistOptions = this.picklistOptions.map((option) => ({
                    ...option,
                    selected:
                        (this.isReservedAgainstNotifications && option.name === 'Reserver mot alle varsler') ||
                        (!this.isReservedAgainstNotifications && option.name === this.selectedOption)
                }));

                // Show success message
                this.successMessage = 'Endringen har blitt lagret.';
                this.showSuccess = true;

                const newMessage = 'Endringen har blitt lagret';
                this.ariaMessage = this.ariaMessage === newMessage ? newMessage + ' ' : newMessage;
            });
    }

    ariaMessage = '';
    handleCloseSuccess() {
        this.showSuccess = false;
        this.successMessage = '';
        this.ariaMessage = '';
    }
}
