import { LightningElement, api } from 'lwc';

export default class FrameworkSelector extends LightningElement {
    @api frameworks = [];
    selectedFramework;

    handleFrameworkChange(event) {
        this.selectedFramework = event.detail.value;
        const selectedEvent = new CustomEvent('frameworkselected', {
            detail: { framework: this.selectedFramework }
        });
        this.dispatchEvent(selectedEvent);
    }

    get frameworkOptions() {
        return this.frameworks.map(fw => ({
            label: fw.framework + ' (' + fw.score + '%)',
            value: fw.framework
        }));
    }
}
