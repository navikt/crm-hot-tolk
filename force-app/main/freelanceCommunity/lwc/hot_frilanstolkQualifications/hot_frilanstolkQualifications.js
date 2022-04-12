import { LightningElement, wire, track } from 'lwc';
import getServiceResourceSkill from '@salesforce/apex/HOT_FreelanceQualificationsController.getServiceResourceSkill';
import editServiceResourceSkill from '@salesforce/apex/HOT_FreelanceQualificationsController.editServiceResourceSkill';
import myServiceResource from '@salesforce/apex/HOT_FreelanceQualificationsController.myServiceResource';
import getAllSkillsList from '@salesforce/apex/HOT_FreelanceQualificationsController.getAllSkillsList';
export default class Hot_frilanstolkQualifications extends LightningElement {
    @track columns = [
        {
            label: ' Velg dine kvalifikasjoner',
            fieldName: 'MasterLabel',
            type: 'text'
        }
    ];
    @track masterLabelColumns = [
        {
            label: 'Kvalifikasjonene du innehar',
            fieldName: 'MasterLabel',
            type: 'text'
        }
    ];
    //henter ut serviceResource
    @track serviceResource;
    @wire(myServiceResource)
    wiredMyServiceresource(result) {
        if (result.data) {
            this.serviceResource = result.data;
        }
    }
    //Henter ut ServiceResourceSkills som bruker har
    @track serviceResourceSkill;
    serviceResourceSkillResult;
    @wire(getServiceResourceSkill)
    wiredGetServiceResourceSkill(result) {
        this.serviceResourceSkillResult = result;
        if (result.data) {
            this.serviceResourceSkillList = result.data;
        }
    }
    //Henter ut alle skills
    @track Id;
    @track skill;
    @wire(getAllSkillsList)
    wiredgetAllSkillsList(resultList) {
        if (resultList.data) {
            this.skill = resultList.data;
            this.serviceResourceSkillListFunction();
        }
    }
    //Sjekker serviceResourceSkills
    @track serviceResourceSkillList;
    serviceResourceSkillListFunction() {
        let showSkillList = [];
        if (this.serviceResourceSkillList === 'undefined' || this.serviceResourceSkillList.length === 0) {
            return;
         }
        for (let i = 0; i < this.skill.length; i++) {
            this.serviceResourceSkillList.forEach((element) => {
                console.log(element.EffectiveEndDate);
                if (element.SkillId === this.skill[i].Id && element.EffectiveEndDate === undefined) {
                    showSkillList.push(this.skill[i]);
                }
            });
        }
        this.serviceResourceSkillList = showSkillList;
    }

    //funksjon som henter inn alle serviceResourceSkill-idene og sjekker de når man trykker på edit-knappen
    @track viewQualifications = true;
    @track editQualifications = false;

    @track userSelectedRows = [];
    @track selectedRows = [];
    //Lager en liste som viser alle eksisterende skills ServiceResourcen har
    editSkills() {
        this.viewQualifications = false;
        this.editQualifications = true;
        let initialSelectedRows = [];
        this.serviceResourceSkillList.forEach((element) => {
            initialSelectedRows.push(element.Id);
        });
        this.selectedRows = initialSelectedRows;
    }
    //Lagrer alle huket av skills i en liste
    selectedRowHandler(event) {
        this.userSelectedRows = event.detail.selectedRows;
    }
    //Sender inn alle huket av skills til Controller og refresher siden når det er fullført.
    handleSelect() {
        try {
            editServiceResourceSkill({
                serviceResource: this.serviceResource,
                selectedSkills: this.userSelectedRows
            }).then(() => {
                this.viewQualifications = true;
                this.editQualifications = false;
                location.reload();
            });
        } catch (error) {
            console.log(JSON.stringify(error));
        }
    }

    handleAbort() {
        this.viewQualifications = true;
        this.editQualifications = false;
    }
}
