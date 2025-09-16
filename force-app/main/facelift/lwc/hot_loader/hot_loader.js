import { LightningElement, api } from 'lwc';

export default class hot_loader extends LightningElement {
    @api size = 'medium';
    // Velg størrelse: "3xlarge", "2xlarge", "xlarge", "large", "medium", "small", "xsmall" (default: "medium")

    @api variant = 'neutral';
    // Velg design: "neutral" (default grå), "interaction" (blå), "inverted"

    @api transparent = false;
    // Setter svg-background til transparent (default: false)

    @api title = '';
    // Tittel

    get loaderClasses() {
        let classes = `navds-loader navds-loader--${this.size} navds-loader--${this.variant}`;
        if (this.transparent) {
            classes += ' navds-loader--transparent';
        }
        return classes;
    }
}
