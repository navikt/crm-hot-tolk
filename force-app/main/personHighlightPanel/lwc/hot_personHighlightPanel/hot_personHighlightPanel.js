import { LightningElement, api, track, wire } from 'lwc';
import { getFieldValue, getRecord } from 'lightning/uiRecordApi';
import { resolve } from 'c/hot_componentsUtils';

import PERSON_ACTORID_FIELD from '@salesforce/schema/Person__c.INT_ActorId__c';
import PERSON_FIRST_NAME from '@salesforce/schema/Person__c.INT_FirstName__c';
import PERSON_IDENT_FIELD from '@salesforce/schema/Person__c.Name';
import GENDER_FIELD from '@salesforce/schema/Person__c.INT_Sex__c';
import IS_DECEASED_FIELD from '@salesforce/schema/Person__c.INT_IsDeceased__c';
import FULL_NAME_FIELD from '@salesforce/schema/Person__c.NKS_Full_Name__c';
import AGE_FIELD from '@salesforce/schema/Person__c.CRM_Age__c';
import CITIZENSHIP_FIELD from '@salesforce/schema/Person__c.INT_Citizenships__c';
import LEGAL_STATUS_FIELD from '@salesforce/schema/Person__c.INT_LegalStatus__c';
import MUNICIPALITY_NAME__FIELD from '@salesforce/schema/Person__c.CRM_Municipality__r.Name';
import DISTRICT_NAME_FIELD from '@salesforce/schema/Person__c.CRM_District__r.Name';
import VEDTAK_FIELD from '@salesforce/schema/Person__c.HOT_DegreeOfHearingAndVisualImpairment__c';

import NAV_ICONS from '@salesforce/resourceUrl/HOT_navIcons';

import getRelatedRecord from '@salesforce/apex/HOT_RecordInfoController.getRelatedRecord';
import hasAccess from '@salesforce/apex/HOT_AccessErrorController.hasAccess';

const PERSON_FIELDS = [
    PERSON_FIRST_NAME,
    PERSON_IDENT_FIELD,
    PERSON_ACTORID_FIELD,
    GENDER_FIELD,
    IS_DECEASED_FIELD,
    FULL_NAME_FIELD,
    AGE_FIELD,
    CITIZENSHIP_FIELD,
    LEGAL_STATUS_FIELD,
    MUNICIPALITY_NAME__FIELD,
    DISTRICT_NAME_FIELD,
    VEDTAK_FIELD
];

export default class hot_personHighlightPanel extends LightningElement {
    @api recordId;
    @api objectApiName;
    @api relationshipField;

    noPerson = false;
    personId;
    wireFields;
    actorId;
    fullName;
    firstName;
    personIdent;
    errorMessageList = {};
    errorMessages;
    personDetails = {};
    uuAlertText = '';

    @track loadingStates = {
        getRecordPerson: true
    };

    connectedCallback() {
        this.wireFields = [`${this.objectApiName}.Id`];
    }

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

    getRelatedRecordId(relationshipField, objectApiName) {
        getRelatedRecord({
            parentId: this.recordId,
            relationshipField: relationshipField,
            objectApiName: objectApiName
        })
            .then((record) => {
                this.personId = resolve(relationshipField, record);
                if (record && !this.personId) {
                    this.noPerson = true;
                    this.loadingStates.getRecordPerson = false;
                }
            })
            .catch((error) => {
                this.addErrorMessage('getRelatedRecord', error);
                console.error(error);
            });
    }

    @wire(getRecord, {
        recordId: '$personId',
        fields: PERSON_FIELDS
    })
    wiredPersonInfo({ error, data }) {
        if (data) {
            this.actorId = getFieldValue(data, PERSON_ACTORID_FIELD);
            this.fullName = getFieldValue(data, FULL_NAME_FIELD);
            this.firstName = getFieldValue(data, PERSON_FIRST_NAME);
            this.personIdent = getFieldValue(data, PERSON_IDENT_FIELD);
            this.personDetails = {
                personId: this.personId,
                firstName: this.firstName,
                personIdent: this.personIdent,
                actorId: this.actorId,
                fullName: this.fullName,
                gender: getFieldValue(data, GENDER_FIELD),
                isDeceased: getFieldValue(data, IS_DECEASED_FIELD),
                age: getFieldValue(data, AGE_FIELD),
                citizenship: this.capitalizeFirstLetter(getFieldValue(data, CITIZENSHIP_FIELD)),
                legalStatus: getFieldValue(data, LEGAL_STATUS_FIELD),
                municipalityName: getFieldValue(data, MUNICIPALITY_NAME__FIELD),
                districtName: getFieldValue(data, DISTRICT_NAME_FIELD),
                vedtak: getFieldValue(data, VEDTAK_FIELD)
            };
            this.loadingStates.getRecordPerson = false;
            this.handleBackgroundColor();
        } else if (error) {
            this.loadingStates.getRecordPerson = false;
            this.handleBackgroundColor();
            hasAccess(this.personId).then((access) => {
                if (access) {
                    this.addErrorMessage('getRecord', error);
                    console.error('Error in wiredPersonInfo:', error);
                }
            });
        }
    }

    @wire(getRecord, {
        recordId: '$recordId',
        fields: '$wireFields'
    })
    wiredRecordInfo({ error, data }) {
        if (data) {
            if (this.relationshipField && this.objectApiName) {
                this.getRelatedRecordId(this.relationshipField, this.objectApiName);
            }
        }
        if (error) {
            this.addErrorMessage('wiredRecordInfo', error);
            console.error(error);
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
}
