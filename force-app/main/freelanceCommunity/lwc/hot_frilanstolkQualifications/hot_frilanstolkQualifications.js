import { LightningElement, wire, track } from 'lwc';
import getServiceResourceSkill from '@salesforce/apex/HOT_FreelanceQualificationsController.getServiceResourceSkill';
import getAllSkillsList from '@salesforce/apex/HOT_SkillController.getAllSkillsList';
export default class Hot_frilanstolkQualifications extends LightningElement {
    @track serviceResourceSkill;
    @track recordId;
    @track serviceResourceSkillList;
    @track Id;
    @wire(getServiceResourceSkill)
    wiredGetServiceResourceSkill(result) {
        if (result.data) {
            this.serviceResourceSkill = result.data;
            this.recordId = this.serviceResourceSkill.Id;
            this.serviceResourceSkillListFunction();
        }
        //Denne kaller på en funksjon som henter ut alle skills unavhengig om serviceresource har noen skills eller ikke.
        getAllSkillsList();
    }
    //Denne henter ut skillsene serviceresource har.
    serviceResourceSkillListFunction() {
        var tempSRSkillList = [];
        for (var i = 0; i < this.serviceResourceSkill.length; i++) {
            tempSRSkillList.push(this.serviceResourceSkill[i]);
        }
        this.serviceResourceSkillList = tempSRSkillList;
    }
    //Denne henter ut alle skills som finnes. Denne fungerer ikke enda.
    getAllSkillsList(result2) {
        if (result2.data) {
            this.skill = result2.data;
            this.Id = result2.Id;
        }
        //Er dette feil? sjekkker jeg lengden på arrayet, eller sjekker jeg lengden på et objekt, type at svaret er 1, fordi id =[0] og masterlabel=[1]?
        var tempSkillList = [];
        for (var i2 = 0; i2 < this.skill.length; i2++) {
            tempSkillList.push(this.skill[i2]);
            console.log(tempSkillList);
        }
        this.skillList = tempSkillList;
    }
}
