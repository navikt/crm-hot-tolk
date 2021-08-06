import { LightningElement, wire, track } from 'lwc';
import getServiceResourceSkill from '@salesforce/apex/HOT_FreelanceQualificationsController.getServiceResourceSkill';
import createServiceResourceSkill from '@salesforce/apex/HOT_FreelanceQualificationsController.createServiceResourceSkill';
import myServiceResource from '@salesforce/apex/HOT_FreelanceQualificationsController.myServiceResource';
import getAllSkillsList from '@salesforce/apex/HOT_SkillController.getAllSkillsList';

export default class Hot_frilanstolkQualifications extends LightningElement {
    @track columns = [
        {
            label: 'Name',
            fieldName: 'MasterLabel',
            type: 'text'
        },
        {
            label: 'Skill Id',
            fieldName: 'Id',
            type: 'text'
        }
    ];
    @track masterLabelColumns = [
        {
            label: 'Name',
            fieldName: 'MasterLabel',
            type: 'text'
        }
    ];

    //henter ut serviceresource
    @track serviceResource;
    @wire(myServiceResource)
    wiredMyServiceresource(result) {
        if (result.data) {
            this.serviceResource = result.data;
        }
    }
    // henter ut informasjon om serviceresourceSkills som bruker har
    @track serviceResourceSkill;
    @wire(getServiceResourceSkill)
    wiredGetServiceResourceSkill(result) {
        if (result.data) {
            this.serviceResourceSkill = result.data;
        }
    }

    //Denne henter ut alle skills
    @track Id;
    @track skill;
    @wire(getAllSkillsList)
    wiredgetAllSkillsList(resultList) {
        if (resultList.data) {
            this.skill = resultList.data;

            this.serviceResourceSkillListFunction();
        }
    }
    //Denne henter ut skillene serviceresource har.
    @track serviceResourceSkillList;
    @track showSkillList;
    serviceResourceSkillListFunction() {
        let tempSRSkillList = [];
        let showSkillList = [];
        if (typeof this.serviceResourceSkill !== 'undefined') {
            for (var i = 0; i < this.serviceResourceSkill.length; i++) {
                tempSRSkillList.push(this.serviceResourceSkill[i]);
            }
            this.serviceResourceSkillList = tempSRSkillList;

            for (let j = 0; j < this.skill.length; j++) {
                this.serviceResourceSkillList.forEach((element) => {
                    if (element.SkillId == this.skill[j].Id && element.EffectiveEndDate == null) {
                        showSkillList.push(this.skill[j]);
                        console.log(this.skill[j].MasterLabel);
                    }
                });
            }
            this.serviceResourceSkillList = [];
            this.serviceResourceSkillList = showSkillList;
        }
    }

    //funksjon som henter inn alle serviceResourceSkill-idene og sjekker de når man trykker på edit-knappen
    @track viewQualifications = true;
    @track editQualifications = false;
    @track userSelectedRows = [];
    @track selectedRows = [];
    // @track initialSelectedRows = [];
    editSkills() {
        this.viewQualifications = false;
        this.editQualifications = true;
        let initialSelectedRows = [];
        this.serviceResourceSkillList.forEach((element) => {
            initialSelectedRows.push(element.Id);
        });
        this.selectedRows = initialSelectedRows;
        console.log('test this old');
    }
    //Jeg må sjekke initalselectedrows opp mot userselectedrow, og de som ikke er like, må det settes enddate til date.today();
    selectedRowHandler(event) {
        this.userSelectedRows = event.detail.selectedRows;
    }

    handleSelect() {
        try {
            createServiceResourceSkill({
                serviceResource: this.serviceResource,
                selectedSkills: this.userSelectedRows
            });
            this.viewQualifications = true;
            this.editQualifications = false;
        } catch (error) {
            console.log(JSON.stringify(error));
        }
    }
}
