import { LightningElement, wire, track } from 'lwc';
import getServiceResourceSkill from '@salesforce/apex/HOT_FreelanceQualificationsController.getServiceResourceSkill';
//import getInfoFromSkills from '@salesforce/apex/HOT_FreelanceUserInformationController.getInfoFromSkills';

export default class Hot_frilanstolkQualifications extends LightningElement {
    @track serviceResourceSkill;
    // @track serviceResourceId;
    // @track skillNumber;
    @track recordId;
    @track serviceResourceSkillList;

    @wire(getServiceResourceSkill)
    wiredGetServiceResourceSkill(result) {
        //Dette er nå en liste, og vi må legge dette inn i en liste, sånn at den henter ut riktig data til riktig indeksplassering.
        if (result.data) {
            this.serviceResourceSkill = result.data;
            this.recordId = this.serviceResourceSkill.Id;
            console.log(this.serviceResourceSkill);
            this.serviceResourceSkillListFunction();

            // this.recordId = this.serviceResourceSkill.Id;
            // this.skillNumber = this.serviceResourceSkill.SkillNumber;
            // console.log(this.skillNumber + 'tester ut skillnumber');
            // console.log(this.recordId + ' tester ut recordId');
        }
    }
    serviceResourceSkillListFunction() {
        var tempSRSkillList = [];
        for (var i = 0; i < this.serviceResourceSkill.length; i++) {
            tempSRSkillList.push(this.serviceResourceSkill[i]);
        }
        this.serviceResourceSkillList = tempSRSkillList;
        //console.log(toString(serviceResourceSkillList));
    }

    //Apinavnet til skills heter skill, så opprett en controller som henter inn skill. hent ut id og Name.

    // @wire(getInfoFromSkills)
    // wiredGetInfoFromSkills(result) {
    //     if (result.data) {
    //         console.log('success getinfo ´from skills');
    //     }
    // }

    // for(let i=0 ; i<10; i++){
    //     console.log(i);
    //   }
}
