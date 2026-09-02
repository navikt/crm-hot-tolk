import { LightningElement, api, track, wire } from 'lwc';

import NAV_ICONS from '@salesforce/resourceUrl/HOT_tindIcons';

import getAccountPersonDetails from '@salesforce/apex/HOT_HighlightPanelController.getAccountPersonDetails';
import hasAccess from '@salesforce/apex/HOT_TindAccessErrorController.hasAccess';

const CONFIDENTIAL_LABELS = {
    FORTROLIG: 'Skjermet adresse - fortrolig',
    STRENGT_FORTROLIG: 'Skjermet adresse - strengt fortrolig',
    STRENGT_FORTROLIG_UTLAND: 'Skjermet adresse - strengt fortrolig'
};

export default class hot_personHighlightPanel extends LightningElement {
    @api recordId;
    @api objectApiName;
    @api relationshipField;

    noPerson = false;
    personId;
    actorId;
    fullName;
    firstName;
    personIdent;
    errorMessageList = {};
    errorMessages;
    personDetails = {};
    uuAlertText = '';
    navEmployeeLabel = 'Skjermet person (NAV-ansatt)';

    @track loadingStates = {
        getRecordPerson: true
    };

    capitalizeFirstLetter(str) {
        if (!str || typeof str !== 'string') {
            return '';
        }
        return str.charAt(0).toUpperCase() + str.slice(1).toLowerCase();
    }

    formatMaritalStatus(str) {
        if (typeof str !== 'string') {
            return str;
        }
        return str.replace(/_/g, ' ').replace(' eller enkemann', '/-mann');
    }

    translateVedtakLabel(value) {
        switch (value) {
            case 'Hearing impaired or deaf':
                return 'Hørselshemmet eller døv';
            case 'Deafblind':
                return 'Døvblind';
            default:
                return value;
        }
    }

    @wire(getAccountPersonDetails, { recordId: '$recordId' })
    wiredPersonDetails({ error, data }) {
        if (data) {
            this.personData = data;
            console.log('Person details:', this.personData);

            this.actorId = this.personData.CRM_Person__r?.INT_ActorId__c;
            this.fullName =
                this.personData.CRM_Person__r?.INT_FirstName__c + ' ' + this.personData.CRM_Person__r?.INT_LastName__c;
            this.firstName = this.personData.CRM_Person__r?.INT_FirstName__c;
            this.personIdent = this.personData.CRM_Person__r?.Name;
            this.personDetails = {
                personId: this.personData.CRM_Person__c,
                firstName: this.firstName,
                personIdent: this.personIdent,
                actorId: this.actorId,
                fullName: this.fullName,
                gender: this.personData.CRM_Person__r?.INT_Sex__c,
                isDeceased: this.personData.CRM_Person__r?.INT_IsDeceased__c,
                age: this.personData.CRM_Person__r?.CRM_Age__c,
                citizenship: this.capitalizeFirstLetter(this.personData.CRM_Person__r?.INT_Citizenships__c),
                legalStatus: this.personData.CRM_Person__r?.INT_LegalStatus__c,
                municipalityName: this.personData.CRM_Person__r?.CRM_Municipality__r?.Name,
                districtName: this.personData.CRM_Person__r?.CRM_District__r?.Name,
                vedtak: this.translateVedtakLabel(
                    this.personData.CRM_Person__r?.HOT_DegreeOfHearingAndVisualImpairment__c
                ),
                navEmployee: this.personData.CRM_Person__r?.INT_IsNavEmployee__c,
                confidentialStatus: this.personData.CRM_Person__r?.INT_Confidential__c
            };
            this.loadingStates.getRecordPerson = false;

            console.log('is nav employee:', this.personDetails?.navEmployee);
            console.log('confidential status:', this.personDetails?.confidentialStatus);
            this.handleBackgroundColor();
        } else if (error) {
            this.loadingStates.getRecordPerson = false;
            this.handleBackgroundColor();
            hasAccess(this.personId).then((access) => {
                if (access) {
                    this.addErrorMessage('getAccountPersonDetails', error);
                    console.error('getAccountPersonDetails error:', error);
                }
            });
        }
    }

    handleBackgroundColor() {
        const genderWrapper = this.template.querySelector('.gender-wrapper');
        if (!genderWrapper) return;
        const className = !this.personDetails?.fullName
            ? 'confidentialBackground'
            : this.personDetails?.isDeceased
              ? 'deadBackground'
              : this.personDetails?.gender === 'Kvinne'
                ? 'femaleBackground'
                : this.personDetails?.gender === 'Mann'
                  ? 'maleBackground'
                  : 'unknownBackground';
        genderWrapper.className = 'gender-wrapper ' + className;
    }

    setUuAlertText() {
        const securityMeasures = this.badges?.find((badge) => badge.badgeContentType === 'SecurityMeasure');
        const hasSecurityMeasures = securityMeasures?.badgeContent.length > 0;
        if (!(hasSecurityMeasures || this.isConfidential || this.isNavEmployee)) {
            this.uuAlertText = '';
            return;
        }

        const navEmployeeText = ' er egen ansatt';
        const isConfidentialText = ' skjermet';
        let alertText = `Bruker${this.isNavEmployee ? navEmployeeText : ''}`;
        const securityMeasureText = hasSecurityMeasures
            ? ` har ${securityMeasures?.label}: ${securityMeasures?.badgeContent
                  .map((secMeasure) => secMeasure.SecurityMeasure)
                  .join(', ')}`
            : '';
        const confidentialityText =
            this.isNavEmployee && this.isConfidential ? ', og' : this.isConfidential ? ' er' : '';
        alertText += confidentialityText;
        alertText += this.isConfidential ? isConfidentialText : '';
        alertText += (this.isNavEmployee || this.isConfidential) && hasSecurityMeasures ? ' og' : '';
        alertText += securityMeasureText || '';
        alertText += '.';
        this.uuAlertText = alertText;
    }

    addErrorMessage(errorName, error) {
        if (Array.isArray(error)) {
            this.errorMessageList[errorName] = error.flat();
        } else if (typeof error === 'object') {
            this.errorMessageList[errorName] = error.body?.exceptionType + ': ' + error.body?.message;
        } else {
            this.errorMessageList[errorName] = error;
        }
        this.updateErrorMessages();
    }

    closeErrorMessage(event) {
        const errorName = event.currentTarget.dataset.errorName;
        this.closeErrorMessages(errorName);
    }

    closeErrorMessages(errorName) {
        if (Object.keys(this.errorMessageList).includes(errorName)) {
            delete this.errorMessageList[errorName];
            this.updateErrorMessages();
        }
    }

    updateErrorMessages() {
        this.errorMessages = Object.keys(this.errorMessageList).map((errorName) => {
            return { errorName: errorName, error: this.errorMessageList[errorName] };
        });
    }

    get isLoading() {
        return Object.keys(this.loadingStates).some((key) => this.loadingStates[key]);
    }

    get isPersonDetailsLoaded() {
        return !this.loadingStates.getRecordPerson;
    }
    get panelClass() {
        return this.fullName ? 'highlightPanel' : 'highlightPanelConfidential';
    }

    get warningIconSrc() {
        return NAV_ICONS + '/warningTriangle.svg#warningTriangle';
    }

    get xMarkIconSrc() {
        return NAV_ICONS + '/xMarkIcon.svg#xMarkIcon';
    }

    get personIdent() {
        return this.personData?.personIdent;
    }

    get isNavEmployeeBadge() {
        return this.personDetails?.navEmployee === true;
    }

    get isConfidentialBadge() {
        return this.personDetails?.confidentialStatus && this.personDetails?.confidentialStatus !== 'UGRADERT';
    }

    get confidentialLabel() {
        return CONFIDENTIAL_LABELS[this.personDetails?.confidentialStatus] ?? false;
    }

    // Used to determine whether to show the bottom panel with personal info, or just the name
    get shouldShowBottomPanel() {
        return this.personDetails.fullName === 'Skjermet person' ? false : true;
    }
}
