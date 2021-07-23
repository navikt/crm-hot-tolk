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
            // for (let s of this.serviceResourceSkill) {
            //     tempSRSkillList.push(this.s);
            // }
            for (var i = 0; i < this.serviceResourceSkill.length; i++) {
                tempSRSkillList.push(this.serviceResourceSkill[i]);
            }
            this.serviceResourceSkillList = tempSRSkillList;

            for (let j = 0; j < this.skill.length; j++) {
                this.serviceResourceSkillList.forEach((element) => {
                    if (element.SkillId == this.skill[j].Id) {
                        showSkillList.push(this.skill[j]);
                        this.serviceResourceSkillList = [];
                        this.serviceResourceSkillList = showSkillList;
                    }
                });
            }
        }
    }
    //TODO Denne skal til edit-siden

    //funksjon som henter inn alle serviceResourceSkill-idene og sjekker de når man trykker på edit-knappen
    @track userSelectedRows = [];
    @track selectedRows = [];
    editSkills() {
        let initialSelectedRows = [];
        this.serviceResourceSkillList.forEach((element) => {
            initialSelectedRows.push(element.Id);
        });
        this.selectedRows = initialSelectedRows;
    }
    //Jeg må sjekke initalselectedrows opp mot userselectedrow, og de som ikke er like, må det settes enddate til date.today();
    selectedRowHandler(event) {
        this.userSelectedRows = event.detail.selectedRows;
    }

    handleSelect() {
        //denne håndterer updating, men tror koden er feil nå, for den vil legge alle skills inn i rowsfordeactivation-listen
        let rowsForDeactivationsList = [];
        //  for (let user of this.userSelectedRows) {
        for (let init of initialSelectedRows) {
            //bruke .contains?? her
            if (user.Id != init.Id) {
                rowsForDeactivationsList.push(init);
            }
        }

        // updateServiceResourceSkill({ serviceResource: this.serviceResource, skill: this.rowsForDeactivations });
        createServiceResourceSkill({ serviceResource: this.serviceResource, skill: this.userSelectedRows });
        // this.connectedCallback();
    }

    // connectedCallback() {
    //     refreshApex(this.wiredGetServiceResourceSkill);
    // }
    //TODO sjekk ut denne force-app/main/freelanceCommunity/classes/HOT_MyServiceAppointmentListController.cls, og se hvordan de creater new.
}
