import { LightningElement, wire, track } from 'lwc';
import getUserServiceResourceSkills from '@salesforce/apex/HOT_FreelanceQualificationsController.getUserServiceResourceSkills';
import editServiceResourceSkill from '@salesforce/apex/HOT_FreelanceQualificationsController.editServiceResourceSkill';
import getAllSkillsList from '@salesforce/apex/HOT_FreelanceQualificationsController.getAllSkillsList';
import { refreshApex } from '@salesforce/apex';
export default class Hot_frilanstolkQualifications extends LightningElement {
    columns = [
        {
            label: 'Velg dine kvalifikasjoner',
            fieldName: 'MasterLabel',
            type: 'text'
        }
    ];
    masterLabelColumns = [
        {
            label: 'Kvalifikasjonene du innehar',
            fieldName: 'MasterLabel',
            type: 'text'
        }
    ];
    //Henter ut ServiceResourceSkills som bruker har
    wiredUserServiceResourceSkillsResult;
    @wire(getUserServiceResourceSkills)
    wiredGetUserServiceResourceSkills(result) {
        this.wiredUserServiceResourceSkillsResult = result;
        if (result.data) {
            this.serviceResourceSkillList = result.data;
        }
    }
    //Henter ut alle skills som eksisterer i org
    @track skill;
    @wire(getAllSkillsList)
    wiredgetAllSkillsList(resultList) {
        if (resultList.data) {
            this.skill = resultList.data;
            this.filterServiceResourceSkills();
        }
    }
    //Viser skills som huket av om de ikke har en end date
    @track serviceResourceSkillList;
    filterServiceResourceSkills() {
        let skillsToShowList = [];
        if (this.serviceResourceSkillList === 'undefined' || this.serviceResourceSkillList.length === 0) {
            return;
         }
        for (let i = 0; i < this.skill.length; i++) {
            this.serviceResourceSkillList.forEach((element) => {
                if (element.SkillId === this.skill[i].Id && element.EffectiveEndDate === undefined) {
                    skillsToShowList.push(this.skill[i]);
                }
            });
        }
        this.serviceResourceSkillList = skillsToShowList;
    }
    isViewQualifications = true;
    isEditQualifications = false;
    @track userSelectedRows = [];
    @track selectedRows = [];
    //Viser alle eksisterende og nye huket av skills
    handleEditSkills() {
        this.isViewQualifications = false;
        this.isEditQualifications = true;
        this.selectedRows = [];
        this.serviceResourceSkillList.forEach((element) => {
            this.selectedRows.push(element.Id);
        });
    }
    //Lagrer alle huket av skills i en liste
    handleRowSelect(event) {
        this.userSelectedRows = event.detail.selectedRows;
    }
    //Sender inn alle huket av skills til Controller og refresher Apex
    handleSave() {
        try {
            editServiceResourceSkill({
                selectedSkills: this.userSelectedRows
            }).then(() => {
                this.isViewQualifications = true;
                this.isEditQualifications = false;
                refreshApex(this.wiredUserServiceResourceSkillsResult).then(() => {
                    this.filterServiceResourceSkills();
                });
            });
        } catch (error) {
            console.log(JSON.stringify(error));
        }
    }
    handleAbort() {
        this.isViewQualifications = true;
        this.isEditQualifications = false;
    }
}
