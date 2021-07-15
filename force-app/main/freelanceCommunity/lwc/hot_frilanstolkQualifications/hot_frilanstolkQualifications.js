import { LightningElement, wire, track } from 'lwc';
import getServiceResourceSkill from '@salesforce/apex/HOT_FreelanceQualificationsController.getServiceResourceSkill';
import getAllSkillsList from '@salesforce/apex/HOT_SkillController.getAllSkillsList';
export default class Hot_frilanstolkQualifications extends LightningElement {
    //tracking for serviceresourceskill
    @track serviceResourceSkill;
    @track recordId;
    @track serviceResourceSkillList;
    //Tracking for Skills
    @track Id;
    @track skillList;

    @wire(getServiceResourceSkill)
    wiredGetServiceResourceSkill(result) {
        if (result.data) {
            this.serviceResourceSkill = result.data;
            this.recordId = this.serviceResourceSkill.Id;
            this.serviceResourceSkillListFunction();
        }
    }
    //Denne henter ut skillsene serviceresource har.
    serviceResourceSkillListFunction() {
        var tempSRSkillList = [];
        for (var i = 0; i < this.serviceResourceSkill.length; i++) {
            tempSRSkillList.push(this.serviceResourceSkill[i]);
        }
        this.serviceResourceSkillList = tempSRSkillList;
    }

    //TODO getAllSkillsList fungerer ikke. getAllSKillsList blir ikke importert fra controlleren. console.log blir ikke skrevet ut. @wire(GetAllSkillsList) gjør at hele komponenten forsvinner.

    //Denne kaller på en funksjon som henter ut alle skills unavhengig om serviceresource har noen skills eller ikke. Jeg mistenker at det ikke er lov å bruke
    //wire på to objekter i samme js fil, for når jeg brukte wire på begge funksjonene så forsvant hele komponenten.
    // @wire(getAllSkillsList)
    getAllSkillsList(result2) {
        if (result2.data) {
            this.skill = result2.data;
            this.Id = result2.Id;
        }
        //Er dette feil? sjekkker jeg lengden på arrayet, eller sjekker jeg lengden på et objekt, type at svaret er 1, fordi id =[0] og masterlabel=[1]?
        var tempSkillList = [];
        for (var i2 = 0; i2 < this.skill.length; i2++) {
            tempSkillList.push(this.skill[i2]);
            console.log(tempSkillList() + ' console.loger hele arrayet med()');
            console.log(tempSkillList + ' console.loger hele arrayet uten ()');
        }
        this.skillList = tempSkillList;
    }
}
