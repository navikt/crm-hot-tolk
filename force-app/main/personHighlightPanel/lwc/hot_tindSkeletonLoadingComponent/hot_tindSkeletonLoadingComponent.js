import { LightningElement, api } from 'lwc';
import personHighlightPanel from './tindPersonHighlightPanel.html';

export default class SkeletonLoadingComponent extends LightningElement {
    @api type;
    render() {
        return personHighlightPanel;
    }
}
