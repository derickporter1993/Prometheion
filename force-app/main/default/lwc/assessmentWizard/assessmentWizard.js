import { LightningElement, api, track } from "lwc";
import loadWizard from "@salesforce/apex/AssessmentWizardController.loadWizard";
import getAvailableWizards from "@salesforce/apex/AssessmentWizardController.getAvailableWizards";
import startSession from "@salesforce/apex/AssessmentWizardController.startSession";
import saveStep from "@salesforce/apex/AssessmentWizardController.saveStep";
import completeAssessment from "@salesforce/apex/AssessmentWizardController.completeAssessment";
import getInProgressSessions from "@salesforce/apex/AssessmentWizardController.getInProgressSessions";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import AW_WizardTitle from "@salesforce/label/c.AW_WizardTitle";
import AW_SelectWizard from "@salesforce/label/c.AW_SelectWizard";
import AW_Loading from "@salesforce/label/c.AW_Loading";
import AW_ErrorLoading from "@salesforce/label/c.AW_ErrorLoading";
import AW_NextStep from "@salesforce/label/c.AW_NextStep";
import AW_PreviousStep from "@salesforce/label/c.AW_PreviousStep";
import AW_CompleteAssessment from "@salesforce/label/c.AW_CompleteAssessment";
import AW_StepCompleted from "@salesforce/label/c.AW_StepCompleted";
import AW_AssessmentComplete from "@salesforce/label/c.AW_AssessmentComplete";
import AW_InProgressSessions from "@salesforce/label/c.AW_InProgressSessions";
import AW_NoSessions from "@salesforce/label/c.AW_NoSessions";

export default class AssessmentWizard extends LightningElement {
  @api wizardName;

  label = {
    AW_WizardTitle,
    AW_SelectWizard,
    AW_Loading,
    AW_ErrorLoading,
    AW_NextStep,
    AW_PreviousStep,
    AW_CompleteAssessment,
    AW_StepCompleted,
    AW_AssessmentComplete,
    AW_InProgressSessions,
    AW_NoSessions,
  };

  @track wizardConfig;
  @track availableWizards = [];
  @track inProgressSessions = [];
  error;
  isLoading = true;
  isSaving = false;

  async connectedCallback() {
    await this.initialize();
  }

  async initialize() {
    this.isLoading = true;
    this.error = undefined;
    try {
      if (this.wizardName) {
        this.wizardConfig = await loadWizard({ wizardName: this.wizardName });
      } else {
        const [wizards, sessions] = await Promise.all([
          getAvailableWizards(),
          getInProgressSessions(),
        ]);
        this.availableWizards = wizards.map((name) => ({
          label: name.replace(/_/g, " "),
          value: name,
        }));
        this.inProgressSessions = sessions;
      }
    } catch (err) {
      this.error = err;
    } finally {
      this.isLoading = false;
    }
  }

  get hasError() {
    return !!this.error;
  }

  get hasConfig() {
    return !!this.wizardConfig;
  }

  get showPicker() {
    return !this.wizardConfig && !this.isLoading && !this.hasError;
  }

  get currentStage() {
    if (!this.wizardConfig?.stages) return null;
    return this.wizardConfig.stages.find((s) => s.stageOrder === this.wizardConfig.currentStage);
  }

  get currentStepConfig() {
    const stage = this.currentStage;
    if (!stage?.steps) return null;
    return stage.steps.find((s) => s.stepOrder === this.wizardConfig.currentStep);
  }

  get isFirstStep() {
    return this.wizardConfig?.currentStage === 1 && this.wizardConfig?.currentStep === 1;
  }

  get isLastStep() {
    if (!this.wizardConfig?.stages?.length) return false;
    const lastStage = this.wizardConfig.stages[this.wizardConfig.stages.length - 1];
    return (
      this.wizardConfig.currentStage === lastStage.stageOrder &&
      this.wizardConfig.currentStep === lastStage.steps[lastStage.steps.length - 1]?.stepOrder
    );
  }

  get progressPercent() {
    return this.wizardConfig?.percentComplete ?? 0;
  }

  get hasSessions() {
    return this.inProgressSessions?.length > 0;
  }

  get sessionItems() {
    return (this.inProgressSessions || []).map((s) => ({
      ...s,
      displayName: (s.wizardName || "").replace(/_/g, " "),
      percentLabel: `${Math.round(s.percentComplete || 0)}%`,
    }));
  }

  async handleWizardSelect(event) {
    const selectedWizard = event.detail.value;
    if (!selectedWizard) return;

    this.isLoading = true;
    try {
      this.wizardConfig = await loadWizard({ wizardName: selectedWizard });
      if (!this.wizardConfig.sessionId) {
        const sessionId = await startSession({
          wizardName: selectedWizard,
          framework: this.wizardConfig.framework,
        });
        this.wizardConfig.sessionId = sessionId;
      }
    } catch (err) {
      this.error = err;
    } finally {
      this.isLoading = false;
    }
  }

  async handleResumeSession(event) {
    const sessionWizardName = event.currentTarget.dataset.wizard;
    if (!sessionWizardName) return;

    this.isLoading = true;
    try {
      this.wizardConfig = await loadWizard({ wizardName: sessionWizardName });
    } catch (err) {
      this.error = err;
    } finally {
      this.isLoading = false;
    }
  }

  async handleStepComplete(event) {
    const { stepId, responseData } = event.detail;
    if (!this.wizardConfig?.sessionId || !stepId) return;

    this.isSaving = true;
    try {
      this.wizardConfig = await saveStep({
        sessionId: this.wizardConfig.sessionId,
        stepId,
        responseData: responseData || "",
      });
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Success",
          message: this.label.AW_StepCompleted,
          variant: "success",
        })
      );
    } catch (err) {
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Error",
          message: err.body?.message || this.label.AW_ErrorLoading,
          variant: "error",
        })
      );
    } finally {
      this.isSaving = false;
    }
  }

  handlePrevious() {
    if (!this.wizardConfig?.stages) return;

    let newStage = this.wizardConfig.currentStage;
    let newStep = this.wizardConfig.currentStep - 1;

    if (newStep < 1) {
      newStage--;
      if (newStage < 1) return;
      const prevStage = this.wizardConfig.stages.find((s) => s.stageOrder === newStage);
      newStep = prevStage?.steps?.length || 1;
    }

    this.wizardConfig = {
      ...this.wizardConfig,
      currentStage: newStage,
      currentStep: newStep,
    };
  }

  async handleComplete() {
    if (!this.wizardConfig?.sessionId) return;

    this.isSaving = true;
    try {
      await completeAssessment({ sessionId: this.wizardConfig.sessionId });
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Success",
          message: this.label.AW_AssessmentComplete,
          variant: "success",
        })
      );
      this.wizardConfig = null;
      await this.initialize();
    } catch (err) {
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Error",
          message: err.body?.message || this.label.AW_ErrorLoading,
          variant: "error",
        })
      );
    } finally {
      this.isSaving = false;
    }
  }
}
