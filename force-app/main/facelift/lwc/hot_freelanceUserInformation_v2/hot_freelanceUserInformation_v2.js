import { LightningElement, api, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getServiceResource from '@salesforce/apex/HOT_FreelanceUserInformationController.getServiceResource';
import updateServiceResourceName from '@salesforce/apex/HOT_FreelanceUserInformationController.updateServiceResourceName';

import getUserServiceResourceSkills from '@salesforce/apex/HOT_FreelanceQualificationsController.getUserServiceResourceSkills';
import editServiceResourceSkill from '@salesforce/apex/HOT_FreelanceQualificationsController.editServiceResourceSkill';
import getAllSkillsList from '@salesforce/apex/HOT_FreelanceQualificationsController.getAllSkillsList';

export default class Hot_freelanceUserInformation_v2 extends LightningElement {
    helpText =
        'Her kan du skrive inn tilleggsinformasjon om dine kvalifikasjoner, samt annen viktig informasjon som formidlere kan ta hensyn til (fobier, allergier etc.). Maksimalt 255 tegn.';

    serviceResource;
    wiredServiceResourceResult;
    recordId;

    // Stores result of the user skills
    wiredUserServiceResourceSkillsResult;
    skill;
    serviceResourceSkillList;

    originalUserData;
    originalRegionOptions;
    originalServiceResourceSkillList;

    viewUserInformation = true;
    editUserInformation = false;

    userData = {
        nameValue: '',
        emailValue: '',
        mobilePhoneValue: '',
        addressValue: '',
        addressFormulaValue: null,
        mobileDeviceValue: '',
        isSkilledValue: false,
        isAvailableForAcuteAssignmentsValue: false,
        preferredRegionsValue: '',
        notificationChannelValue: '',
        preferences: ''
    };

    regionOptions = [
        { label: 'Agder', value: 'Agder', selected: false },
        { label: 'Innlandet', value: 'Innlandet', selected: false },
        { label: 'Møre og Romsdal', value: 'More_og_Romsdal', selected: false },
        { label: 'Nordland', value: 'Nordland', selected: false },
        { label: 'Oslo', value: 'Oslo', selected: false },
        { label: 'Rogaland', value: 'Rogaland', selected: false },
        { label: 'Trøndelag', value: 'Trondelag', selected: false },
        { label: 'Troms og Finnmark', value: 'Tromso', selected: false },
        { label: 'Vest-Viken', value: 'Vest_Viken', selected: false },
        { label: 'Vestland', value: 'Vestland', selected: false },
        { label: 'Vestfold og Telemark', value: 'Vestfold_og_Telemark', selected: false },
        { label: 'Øst-Viken', value: 'Ost_Viken', selected: false }
    ];

    notificationChannelOptions = [
        { label: 'SMS', value: 'SMS', selected: false },
        { label: 'Push-varsel i appen', value: 'Push-varsel i appen', selected: false }
    ];

    qualificationOptions = [{ fieldName: 'MasterLabel', type: 'text' }];

    // Track selected Skill Ids here
    userSelectedSkillIds = [];

    // Fetch the user Service Resource record
    @wire(getServiceResource)
    wiredGetServiceResource(result) {
        if (result.data) {
            this.serviceResource = result.data;
            this.recordId = this.serviceResource.Id;
            this.wiredServiceResourceResult = result;

            this.selectedOption = this.serviceResource.HOT_NotificationChannel__c;
            this.newSelectedOption = this.selectedOption;

            this.userData = {
                nameValue: this.serviceResource.Name || '',
                emailValue: this.serviceResource.HOT_EmailOverride__c || '',
                mobilePhoneValue: this.serviceResource.HOT_MobilePhoneOverride__c || '',
                addressFormulaValue: this.serviceResource.HOT_Address__c || null,
                addressValue: this.serviceResource.HOT_AddressOverride__c,
                mobileDeviceValue: this.serviceResource.HOT_MobileDevice__c || '',
                notificationChannelValue: this.serviceResource.HOT_NotificationChannel__c || '',
                isSkilledValue: this.serviceResource.HOT_Skilled__c || false,
                isAvailableForAcuteAssignmentsValue:
                    this.serviceResource.HOT_IsAvailableForAcuteAssignments__c || false,
                preferredRegionsValue: this.serviceResource.HOT_PreferredRegions__c || '',
                preferences: this.serviceResource.HOT_MoreInformation__c || ''
            };

            this.handlePreferredNotificationChannel();
            this.handlePreferredPicklistRegion();
        }
    }

    // Fetch current user's ServiceResourceSkills
    @wire(getUserServiceResourceSkills)
    wiredGetUserServiceResourceSkills(result) {
        this.wiredUserServiceResourceSkillsResult = result;
        if (result.data) {
            this.serviceResourceSkillList = result.data;
            // Initialize selected skill IDs to those without EffectiveEndDate (active skills)
            this.userSelectedSkillIds = this.serviceResourceSkillList
                .filter((skill) => !skill.EffectiveEndDate)
                .map((skill) => skill.SkillId);
        }
    }

    // Fetch all available skills
    @wire(getAllSkillsList)
    wiredGetAllSkillsList(resultList) {
        if (resultList.data) {
            this.skill = resultList.data;
            this.filterServiceResourceSkills();
        }
    }

    get userQualificationSelectedSkillList() {
        return this.filteredSkillsToShowList || [];
    }

    get skillsList() {
        return this.skill ? this.skill : [];
    }

    get name() {
        return this.userData ? this.userData.nameValue : '';
    }

    get email() {
        return this.userData ? this.userData.emailValue : '';
    }

    get mobilePhone() {
        return this.userData ? this.userData.mobilePhoneValue : '';
    }

    get address() {
        if (this.userData.addressFormulaValue == ', ,') {
            return '';
        } else {
            return this.userData ? this.userData.addressFormulaValue : this.userData.addressValue;
        }
    }

    get mobileDevice() {
        return this.userData ? this.userData.mobileDeviceValue : '';
    }

    get selectedNotificationChannel() {
        return this.userData?.notificationChannelValue || '';
    }

    get isSkilled() {
        return this.userData && this.userData.isSkilledValue ? true : false;
    }

    get isAvailableForAcuteAssignments() {
        return this.userData && this.userData.isAvailableForAcuteAssignmentsValue ? true : false;
    }

    get formattedRegions() {
        return this.userData?.preferredRegionsValue ? this.userData.preferredRegionsValue.split(';').join(', ') : '';
    }

    get selectedRegionLabels() {
        return (this.regionOptions || [])
            .filter((region) => region.selected)
            .map((region) => region.label)
            .join(', ');
    }

    get leftRegionOptions() {
        return this.regionOptions.slice(0, Math.ceil(this.regionOptions.length / 2));
    }

    get rightRegionOptions() {
        return this.regionOptions.slice(Math.ceil(this.regionOptions.length / 2));
    }

    get userPreferences() {
        return this.userData ? this.userData.preferences : '';
    }

    get skillsWithSelection() {
        if (!this.skill) return [];

        return this.skill.map((skill) => {
            return {
                ...skill,
                selected: this.userSelectedSkillIds.includes(skill.Id)
            };
        });
    }

    handleNameChange(event) {
        this.userData.nameValue = event.target.value;
    }

    handleEmailChange(event) {
        this.userData.emailValue = event.target.value;
        this.handleEmailValidation();
    }

    handleEmailValidation() {
        const userInput = this.template.querySelectorAll('c-input');

        userInput.forEach((input) => {
            if (input.type === 'email') {
                const emailValue = input.getValue();

                if (!emailValue.includes('@') || !emailValue.includes('.')) {
                    input.sendErrorMessage('Oppgi en gyldig e-postadresse, som navn@email.com.');
                } else {
                    input.sendErrorMessage('');
                }
            }
        });
    }

    handleMobilePhoneChange(event) {
        this.userData.mobilePhoneValue = event.target.value;
    }

    handleAddressChange(event) {
        this.userData.addressValue = event.target.value;
    }

    handleMobileDeviceChange(event) {
        this.userData.mobileDeviceValue = event.target.value;
    }

    handleIsSkilledChange(event) {
        this.userData.isSkilledValue = event.detail;
    }

    handleIsAvailableChange(event) {
        this.userData.isAvailableForAcuteAssignmentsValue = event.detail;
    }

    handlePreferredRegionsChange(event) {
        this.userData.preferredRegionsValue = event.detail;
    }

    handleUserPreferences(event) {
        this.userData.preferences = event.detail;
    }

    editProfile() {
        // Snapshot only UserData
        this.originalUserData = JSON.parse(JSON.stringify(this.userData));
        this.originalRegionOptions = JSON.parse(JSON.stringify(this.regionOptions));
        this.originalServiceResourceSkillList = JSON.parse(JSON.stringify(this.serviceResourceSkillList));

        this.viewUserInformation = false;
        this.editUserInformation = true;

        this.handleEditSkills();
    }

    handleAbort() {
        // Restore original user data if it exist
        if (this.originalUserData) {
            this.userData = this.originalUserData;
        }

        if (this.originalRegionOptions) {
            this.regionOptions = this.originalRegionOptions;
        }

        if (this.originalServiceResourceSkillList) {
            this.serviceResourceSkillList = this.originalServiceResourceSkillList;
        }

        this.viewUserInformation = true;
        this.editUserInformation = false;
    }

    // Submits updated user data and refreshes the UI
    handleSubmit() {
        updateServiceResourceName({
            newName: this.userData.nameValue,
            newEmail: this.userData.emailValue,
            newMobilePhone: this.userData.mobilePhoneValue,
            newAddress: this.userData.addressValue,
            newaddressFormula: this.userData.addressFormulaValue,
            newMobileDevice: this.userData.mobileDeviceValue,
            newNotificationChannel: this.userData.notificationChannelValue,
            newIsSkilled: this.userData.isSkilledValue,
            newIsAvailableForAcuteAssignments: this.userData.isAvailableForAcuteAssignmentsValue,
            newPreferredRegions: this.userData.preferredRegionsValue,
            newPreferences: this.userData.preferences
        })
            .then(() => {
                return Promise.all([refreshApex(this.wiredServiceResourceResult)]);
            })
            .then(() => {
                return this.handleSaveQualification();
            })
            .then(() => {
                this.handleSuccess();
                window.scrollTo({ top: 0, behavior: 'smooth' });
            })
            .catch((error) => {
                console.error('Error in handleSubmit process:', error);
            });
    }

    handleSaveQualification() {
        const selectedSkills = this.skill
            ? this.skill.filter((skill) => this.userSelectedSkillIds.includes(skill.Id))
            : [];

        editServiceResourceSkill({ selectedSkills })
            .then(() => {
                return refreshApex(this.wiredUserServiceResourceSkillsResult);
            })
            .then(() => {
                this.filterServiceResourceSkills();
            })
            .catch((error) => {
                console.error('Error saving qualifications:', error);
            });
    }

    handleSuccess() {
        this.viewUserInformation = true;
        this.editUserInformation = false;
    }

    // Updates region selections based on user's selected regions
    handlePreferredPicklistRegion() {
        const preferredList = (this.userData.preferredRegionsValue || '')
            .split(';')
            .map((item) => item.trim().toLowerCase());

        this.regionOptions.forEach((region) => {
            region.selected = preferredList.includes(region.value.toLowerCase());
        });
    }

    handleRegionSelectionChange(event) {
        const selectedValue = event.target.dataset.value;
        const isChecked = event.detail;

        // Find the matching region in regionOptions
        const region = this.regionOptions.find((opt) => opt.value === selectedValue);

        if (region) {
            region.selected = isChecked;
        }

        // Update preferredRegionsValue string from selected options
        const selectedValues = this.regionOptions.filter((opt) => opt.selected).map((opt) => opt.value);

        this.userData.preferredRegionsValue = selectedValues.join(';');
    }

    // Sets selected notification channel based on user's selected notification channel
    handlePreferredNotificationChannel() {
        const preferredList = (this.userData.notificationChannelValue || '')
            .split(';')
            .map((item) => item.trim().toLowerCase());
        this.notificationChannelOptions.forEach((notification) => {
            notification.selected = false;
        });
        const selectedNotification = this.notificationChannelOptions.find((notification) =>
            preferredList.includes(notification.value.toLowerCase())
        );
        if (selectedNotification) {
            selectedNotification.selected = true;
        }
    }

    // Updates user selected notifications channel
    handleNotificationSelectionChange(event) {
        const selectedValue = event.target.value;
        if (!selectedValue) return;

        this.notificationChannelOptions = this.notificationChannelOptions.map((option) => ({
            ...option,
            selected: option.value === selectedValue
        }));

        this.userData.notificationChannelValue = selectedValue;

        console.log('Updated notificationChannelValue: ', this.userData.notificationChannelValue);
    }

    filteredSkillsToShowList = [];
    // Filters out skills that the user has and are still active (no end date)
    filterServiceResourceSkills() {
        let skillsToShowList = [];
        if (!this.serviceResourceSkillList || this.serviceResourceSkillList.length === 0) {
            return;
        }

        this.skill.forEach((skill) => {
            this.serviceResourceSkillList.forEach((element) => {
                if (element.SkillId === skill.Id && element.EffectiveEndDate === undefined) {
                    skillsToShowList.push(skill);
                }
            });
        });
        this.filteredSkillsToShowList = skillsToShowList;
    }

    userSelectedRows = [];
    selectedRows = [];

    // Checks currently active skill record has no EffectiveEndDate
    handleEditSkills() {
        this.selectedRows = [];
        this.serviceResourceSkillList.forEach((element) => {
            if (element.EffectiveEndDate === undefined) {
                this.selectedRows.push(element.SkillId);
            }
        });
    }

    // Saves all selected rows in a list
    handleRowSelect(event) {
        this.userSelectedRows = event.detail.selectedRows;
    }

    // UPDATED: Handle checkbox click for qualifications
    handleCheckboxClick(event) {
        const skillId = event.target.dataset.value;
        const checked = event.detail;

        if (!skillId) return;

        if (checked) {
            if (!this.userSelectedSkillIds.includes(skillId)) {
                this.userSelectedSkillIds = [...this.userSelectedSkillIds, skillId];
            }
        } else {
            this.userSelectedSkillIds = this.userSelectedSkillIds.filter((id) => id !== skillId);
        }
    }
}
