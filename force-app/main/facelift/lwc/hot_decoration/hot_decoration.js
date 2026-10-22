import { LightningElement } from 'lwc';
import CHRISTMAS_LIGHTS from '@salesforce/resourceUrl/Christmaslights';

export default class Hot_decoration extends LightningElement {
    decorationStyle = `background-image: url("${CHRISTMAS_LIGHTS}");`;

    get isChristmasSeason() {
        const today = new Date();
        const month = today.getMonth();
        const day = today.getDate();

        return (month === 10 && day === 30) || month === 11 || (month === 0 && day <= 2);
    }
}
