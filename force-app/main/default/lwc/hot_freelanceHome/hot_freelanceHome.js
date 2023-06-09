import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import ICON_Person from '@salesforce/resourceUrl/TINDPersonIcon';
import ICON_Chat from '@salesforce/resourceUrl/Chat2Icon';
import ICON_Tasklist from '@salesforce/resourceUrl/TaskList';
import ICON_RightArrow from '@salesforce/resourceUrl/rightArrow';

export default class Hot_freelanceHome extends NavigationMixin(LightningElement) {
    @track pageLinks = {};
    personIcon = ICON_Person;
    tasklistIcon = ICON_Tasklist;
    chatIcon = ICON_Chat;
    rightArrow = ICON_RightArrow;
    connectedCallback() {
        sessionStorage.clear(); // Clear session storage when on home
        window.scrollTo(0, 0);
        let baseURLArray = window.location.pathname.split('/');
        baseURLArray.pop();
        let baseURL = baseURLArray.join('/');
        this.pageLinks = {
            myServiceAppointments: baseURL + '/mine-oppdrag',
            freelanceMyPage: baseURL + '/frilanstolk-min-side',
            freelanceMyThreads: baseURL + '/mine-samtaler-frilanstolk'
        };
    }
}
