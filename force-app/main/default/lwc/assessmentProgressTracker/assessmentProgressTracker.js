import { LightningElement, api } from "lwc";
import AW_PercentComplete from "@salesforce/label/c.AW_PercentComplete";
import AW_StagePrefix from "@salesforce/label/c.AW_StagePrefix";

export default class AssessmentProgressTracker extends LightningElement {
  @api stages = [];
  @api currentStage = 1;
  @api currentStep = 1;
  @api percentComplete = 0;

  label = {
    AW_PercentComplete,
    AW_StagePrefix,
  };

  get progressLabel() {
    return `${Math.round(this.percentComplete)}% Complete`;
  }

  get progressVariant() {
    if (this.percentComplete >= 100) return "expired";
    if (this.percentComplete >= 50) return "warning";
    return "base";
  }

  get stageItems() {
    return (this.stages || []).map((stage) => {
      const isCurrent = stage.stageOrder === this.currentStage;
      const isComplete = stage.isComplete === true;
      const isPast = stage.stageOrder < this.currentStage;

      let statusClass = "slds-progress__item";
      if (isComplete || isPast) {
        statusClass += " slds-is-completed";
      } else if (isCurrent) {
        statusClass += " slds-is-active";
      }

      return {
        ...stage,
        key: `stage-${stage.stageOrder}`,
        statusClass,
        isCurrent,
        isComplete: isComplete || isPast,
        stageLabel: `Stage ${stage.stageOrder}`,
        stepCount: stage.steps ? stage.steps.length : 0,
        ariaLabel: `Stage ${stage.stageOrder}${isComplete || isPast ? " completed" : isCurrent ? " current" : " upcoming"}`,
      };
    });
  }
}
