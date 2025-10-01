import { LightningElement, api, track, wire } from 'lwc';
import { getFieldValue, getRecord } from 'lightning/uiRecordApi';
import { resolve } from 'c/hot_componentsUtils';
import { NavigationMixin } from 'lightning/navigation';

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
//import MUNICIPALITY_URL__FIELD from '@salesforce/schema/Person__c.CRM_Municipality__r.HOT_Url__c';
import DISTRICT_NAME_FIELD from '@salesforce/schema/Person__c.CRM_District__r.Name';
//import DISTRICT_URL_FIELD from '@salesforce/schema/Person__c.CRM_District__r.HOT_Url__c';

import NAV_ICONS from '@salesforce/resourceUrl/HOT_navIcons';

import getPersonAccessBadges from '@salesforce/apex/HOT_PersonAccessBadgesController.getPersonAccessBadges';
import getPersonBadgesAndInfo from '@salesforce/apex/HOT_PersonBadgesController.getPersonBadgesAndInfo';
import getHistorikk from '@salesforce/apex/HOT_FullmaktController.getHistorikk';
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
    //MUNICIPALITY_URL__FIELD,
    DISTRICT_NAME_FIELD
    //DISTRICT_URL_FIELD
];

export default class hot_personHighlightPanel extends NavigationMixin(LightningElement) {
    @api recordId;
    @api objectApiName;
    @api relationshipField;
    @api modalTitle = '';

    isModalOpen = false;
    currentFlow;

    // Handle Flow buttons
    handleFlowButton(event) {
        this.currentFlow = event.target.dataset.flow;
        this.modalTitle = `Run ${this.currentFlow}`;
        this.isModalOpen = true;

        // Wait for modal to render, then start Flow
        setTimeout(() => {
            const flow = this.template.querySelector('lightning-flow');
            if (flow) {
                flow.startFlow(this.currentFlow, [
                    {
                        name: 'recordId',
                        type: 'String',
                        value: this.recordId
                    }
                ]);
            }
        }, 0);
    }

    closeModal() {
        this.isModalOpen = false;
        this.currentFlow = null;
    }

    handleStatusChange(event) {
        if (event.detail.status === 'FINISHED' || event.detail.status === 'FINISHED_SCREEN') {
            this.closeModal();
        }
    }

    handleEditRecord() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                actionName: 'edit'
            }
        });
    }

    @track loadingStates = {
        getPersonBadgesAndInfo: true,
        getPersonAccessBadges: true,
        getHistorikk: true,
        getRecordPerson: true
    };

    noPerson = false;
    shownBadge;
    personId;
    wireFields;
    wiredBadge;
    historikkWiredData;
    isLoaded;
    actorId;
    fullName;
    firstName;
    personIdent;

    badges;
    dateOfDeath;
    badgeContent;
    errorMessageList = {};
    errorMessages;
    erNasjonalOppfolging = false;

    personDetails = {};

    uuAlertText = '';

    connectedCallback() {
        this.wireFields = [`${this.objectApiName}.Id`];
    }

    handleActionClick(event) {
        const apiName = event.target.dataset.apiname;
        this[NavigationMixin.Navigate]({
            type: 'standard__quickAction',
            attributes: {
                apiName
            }
        });
    }

    @wire(getPersonBadgesAndInfo, {
        field: '$relationshipField',
        parentObject: '$objectApiName',
        parentRecordId: '$recordId',
        filterOpenSTO: true
    })
    wiredBadgeInfo(value) {
        this.wiredBadge = value;
        const { data, error } = value;
        this.loadingStates.getPersonBadgesAndInfo = !(error || data);
        this.setWiredBadge();
    }

    setWiredBadge() {
        if (this.wiredBadge == null || this.historikkWiredData == null) return;
        const { data, error } = this.wiredBadge;
        const { data: historikkData } = this.historikkWiredData;

        if (data) {
            let badges = [];
            badges = [...badges, ...data.badges];
            if (historikkData && historikkData.length > 0) {
                badges.push({
                    name: 'historicalGuardianship',
                    label: 'Historiske fullmakter',
                    styling: 'slds-m-left_x-small slds-m-vertical_xx-small pointer greyBadge',
                    clickable: true,
                    tabindex: '0',
                    badgeContent: historikkData,
                    badgeContentType: 'historicalPowerOfAttorney'
                });
            }
            this.badges = badges;

            // this.entitlements = data.entitlements;
            if (data.errors && data.errors.length > 0) {
                this.addErrorMessage('setWiredBadge', data.errors);
            }
            this.dateOfDeath = data.dateOfDeath;
            this.setUuAlertText();
        }
        if (error) {
            this.addErrorMessage('setWiredBadge', error);
            console.error(error);
        }
    }

    @wire(getPersonAccessBadges, {
        field: '$relationshipField',
        parentObject: '$objectApiName',
        parentRecordId: '$recordId'
    })
    wiredPersonBadgeInfo(value) {
        this.wiredPersonAccessBadge = value;
        try {
            this.setWiredPersonAccessBadge();
        } catch (error) {
            console.error('There was problem to fetch data from wire-function: ' + error);
        } finally {
            this.loadingStates.getPersonAccessBadges = false;
        }
    }

    @wire(getHistorikk, {
        recordId: '$recordId',
        objectApiName: '$objectApiName'
    })
    wiredHistorikk(value) {
        this.historikkWiredData = value;
        const { data, error } = this.historikkWiredData;
        // data is null if there is no historic data
        this.loadingStates.getHistorikk = !(error || data || data === null);
        if (data) {
            this.setWiredBadge();
        } else if (error) {
            this.addErrorMessage('getHistorikk', error);
            console.error(error);
        }
    }

    setWiredPersonAccessBadge() {
        const { data, error } = this.wiredPersonAccessBadge;

        if (data) {
            this.isNavEmployee = data.some((element) => element.name === 'isNavEmployee');
            this.isConfidential = data.some((element) => element.name === 'isConfidential');
            this.personAccessBadges = data;
            this.setUuAlertText();
        } else if (error) {
            this.addErrorMessage('setWiredPersonAccessBadge', error);
            console.error(error);
        }
    }

    onKeyPressHandler(event) {
        if (event.key === 'Enter' || event.key === ' ') {
            this.onClickHandler(event);
        }
    }

    onClickHandler(event) {
        const selectedBadge = event.target.dataset.id;
        const cmp = this.template.querySelector(
            `lightning-layout-item[data-id="${selectedBadge}"] c-hot_person-panel-badge-content`
        );
        if (cmp == null) return;
        this.handleSelectedBadge(cmp.dataset.id, selectedBadge);
    }

    handleSelectedBadge(selectedBadge, badge) {
        if (this.shownBadge === selectedBadge) {
            this.closeBadge();
            return;
        }
        this.shownBadge = selectedBadge;
        this.setExpanded(badge);
    }

    closeBadge() {
        this.shownBadge = '';
        this.setExpanded(null);
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

    setExpanded(selectedBadge) {
        const badges = this.template.querySelectorAll('.slds-badge');
        badges.forEach((badge) => {
            if (badge instanceof HTMLElement && badge.dataset.id === selectedBadge && badge.ariaExpanded === 'false') {
                // eslint-disable-next-line @locker/locker/distorted-element-set-attribute
                badge.setAttribute('aria-expanded', 'true');
            } else if (badge.role === 'button') {
                // eslint-disable-next-line @locker/locker/distorted-element-set-attribute
                badge.setAttribute('aria-expanded', 'false');
            }
        });
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
                //municipalityUrl: getFieldValue(data, MUNICIPALITY_URL__FIELD),
                districtName: getFieldValue(data, DISTRICT_NAME_FIELD)
                //districtUrl: getFieldValue(data, DISTRICT_URL_FIELD)
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
        //return Object.values(this.loadingStates).some((isLoading) => isLoading);
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
