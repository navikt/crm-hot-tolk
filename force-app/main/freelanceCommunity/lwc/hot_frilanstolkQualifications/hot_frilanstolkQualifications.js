import { LightningElement, wire, track } from 'lwc';
import getServiceResourceSkill from '@salesforce/apex/HOT_FreelanceQualificationsController.getServiceResourceSkill';
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

    //tracking for serviceresourceskill
    @track serviceResourceSkill;

    @track serviceResourceSkillList;
    //Tracking for Skills
    @track Id;
    @track skill;
    //correct skillslist
    @track showSkillList;

    @wire(getServiceResourceSkill)
    wiredGetServiceResourceSkill(result) {
        if (result.data) {
            this.serviceResourceSkill = result.data;
            //this.recordId = this.serviceResourceSkill.Id;
            // this.serviceResourceSkillListFunction();
        }
    }
    //Denne henter ut alle skills
    @wire(getAllSkillsList)
    wiredgetAllSkillsList(resultList) {
        if (resultList.data) {
            this.skill = resultList.data;
            this.serviceResourceSkillListFunction();
        }
    }

    //Denne henter ut skillsene serviceresource har.
    serviceResourceSkillListFunction() {
        let tempSRSkillList = [];
        let showSkillList = [];
        for (var i = 0; i < this.serviceResourceSkill.length; i++) {
            tempSRSkillList.push(this.serviceResourceSkill[i]);
        }
        this.serviceResourceSkillList = tempSRSkillList;

        for (let j = 0; j < this.skill.length; j++) {
            this.serviceResourceSkillList.forEach((element) => {
                if (element.SkillId == this.skill[j].Id) {
                    // console.log('et funn er funnet' + this.skill[j].MasterLabel);
                    showSkillList.push(this.skill[j]);
                    this.serviceResourceSkillList = [];
                    this.serviceResourceSkillList = showSkillList;
                }
            });
        }
    }
    //TODO Denne skal til edit-siden

    @track selectedRows = [];

    selectedRowHandler(event) {
        let tempSelectedRows = [];
        let anotherOne = [];
        tempSelectedRows = event.detail.selectedRows;

        anotherOne.push(tempSelectedRows[0]);
        this.selectedRows = anotherOne;
        console.log(this.selectedRows[0].MasterLabel);
    }
    handleSelect() {
        // const rows = [Id];
        // this.selectedRows = rows;
        console.log(this.selectedRows + ' 1 ');
        let counter = 0;
        for (let h = 0; h < this.selectedRows.length; h++) {
            counter++;

            console.log(counter);
            if (this.serviceResourceSkillList.Id != this.selectedRows[h].Id) {
                this.serviceResourceSkillList.push(this.selectedRows[h]);
            } else {
                console.log('Denne finnes allerede ' + this.selectedRows[h].MasterLabel);
            }

            //Dette er bare front-end , ikke bakend, men skal prøve å pushe de nye taskene til brukeren.

            //Her må vi opprette en serviceresourceskill først, og legge til startdate og ved sletting må vi sette enddate til now.
            //this.serviceResourceSkill.push(this.selectedRows[h].)
        }
    }

    // Denne er til å refreshe apes kanskje?? kalle på servicecresourceskill?? så enkelt? ja takk.
    //refreshApex(this.wiredServiceResourceSkill);

    // jeg må sammenlikne skillid med id fra skills med skillid fra serviceresourceid, slik at serviceresourceskill blir oppdatert
    //All info vil jo serviceresoruceskill fse for meg, så lenge jeg har id, og oppdaterer startdate og enddate
}
