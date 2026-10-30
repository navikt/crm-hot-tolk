import { LightningElement, api } from 'lwc';

export default class HotFreelanceCommonTable extends LightningElement {
    @api records = [];
    @api columns = [];
    @api checkbox = false;
    @api checkedRows = [];
}
