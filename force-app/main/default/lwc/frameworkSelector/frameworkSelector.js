import { LightningElement, api, track } from "lwc";

export default class FrameworkSelector extends LightningElement {
  @api frameworks = [];
  selectedFramework;
  @track isLoading = false;
  @track hasError = false;
  @track errorMessage = "";

  get hasFrameworks() {
    return this.frameworks && this.frameworks.length > 0;
  }

  get isEmpty() {
    return !this.isLoading && !this.hasError && !this.hasFrameworks;
  }

  handleFrameworkChange(event) {
    this.selectedFramework = event.detail.value;
    const selectedEvent = new CustomEvent("frameworkselected", {
      detail: { framework: this.selectedFramework },
    });
    this.dispatchEvent(selectedEvent);
  }

  get frameworkOptions() {
    return this.frameworks.map((fw) => ({
      label: fw.framework + " (" + fw.score + "%)",
      value: fw.framework,
    }));
  }
}
