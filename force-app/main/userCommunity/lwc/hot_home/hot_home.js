import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
import NAME_FIELD from '@salesforce/schema/User.FirstName';
import checkAssignedPermissionSet from '@salesforce/apex/HOT_Utility.checkAssignedPermissionSet';
import checkAssignedPermissionSetGroup from '@salesforce/apex/HOT_Utility.checkAssignedPermissionSetGroup';

export default class Hot_home extends NavigationMixin(LightningElement) {
    @track name;
    @wire(getRecord, {
        recordId: USER_ID,
        fields: [NAME_FIELD]
    })
    wireuser({ data }) {
        if (data) {
            this.name = data.fields.FirstName.value;
        }
    }

    connectedCallback() {
        window.scrollTo(0, 0);
        let baseURLArray = window.location.pathname.split('/');
        baseURLArray.pop();
        let baseURL = baseURLArray.join('/');
        this.setLinkURLs(baseURL);
    }

    newRequest;
    myRequests;
    mySchedule;
    myPage;
    myServiceAppointments;
    freelanceMyPage;
    setLinkURLs(baseURL) {
        this.newRequest = baseURL + '/ny-bestilling';
        this.myRequests = baseURL + '/mine-bestillinger';
        this.mySchedule = baseURL + '/min-tidsplan';
        this.myPage = baseURL + '/min-side';
        this.myServiceAppointments = baseURL + '/mine-oppdrag';
        this.freelanceMyPage = baseURL + '/frilanstolk-min-side';
    }

    @track isFrilans = false;
    @wire(checkAssignedPermissionSetGroup, {
        permissionSetGroupName: 'HOT_Tolk_Frilans_Gruppe'
    })
    async wireIsFrilans({ data }) {
        this.isFrilans = data;
    }
    @wire(checkAssignedPermissionSet, { permissionSetName: 'HOT_Admin' }) //Use this when developing/testing
    wireIsAdmin({ data }) {
        if (!this.isFrilans) {
            this.isFrilans = data;
        }
    }
}
