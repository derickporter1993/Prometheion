import { LightningElement, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { refreshApex } from "@salesforce/apex";

import getEscalationPaths from "@salesforce/apex/EscalationPathController.getPaths";
import createPath from "@salesforce/apex/EscalationPathController.createPath";
import updatePath from "@salesforce/apex/EscalationPathController.updatePath";
import deletePath from "@salesforce/apex/EscalationPathController.deletePath";

import ESCPATH_Title from "@salesforce/label/c.ESCPATH_Title";
import ESCPATH_Refresh from "@salesforce/label/c.ESCPATH_Refresh";
import ESCPATH_NewEscalationLevel from "@salesforce/label/c.ESCPATH_NewEscalationLevel";
import ESCPATH_EscalationFlow from "@salesforce/label/c.ESCPATH_EscalationFlow";
import ESCPATH_AlertTriggered from "@salesforce/label/c.ESCPATH_AlertTriggered";
import ESCPATH_L1TeamLead from "@salesforce/label/c.ESCPATH_L1TeamLead";
import ESCPATH_L2Manager from "@salesforce/label/c.ESCPATH_L2Manager";
import ESCPATH_L3CISO from "@salesforce/label/c.ESCPATH_L3CISO";
import ESCPATH_Loading from "@salesforce/label/c.ESCPATH_Loading";
import ESCPATH_Level1 from "@salesforce/label/c.ESCPATH_Level1";
import ESCPATH_TeamLeadEscalation from "@salesforce/label/c.ESCPATH_TeamLeadEscalation";
import ESCPATH_Active from "@salesforce/label/c.ESCPATH_Active";
import ESCPATH_Inactive from "@salesforce/label/c.ESCPATH_Inactive";
import ESCPATH_Edit from "@salesforce/label/c.ESCPATH_Edit";
import ESCPATH_Delete from "@salesforce/label/c.ESCPATH_Delete";
import ESCPATH_NoLevel1Paths from "@salesforce/label/c.ESCPATH_NoLevel1Paths";
import ESCPATH_Level2 from "@salesforce/label/c.ESCPATH_Level2";
import ESCPATH_ManagerEscalation from "@salesforce/label/c.ESCPATH_ManagerEscalation";
import ESCPATH_NoLevel2Paths from "@salesforce/label/c.ESCPATH_NoLevel2Paths";
import ESCPATH_Level3 from "@salesforce/label/c.ESCPATH_Level3";
import ESCPATH_CISODirectorEscalation from "@salesforce/label/c.ESCPATH_CISODirectorEscalation";
import ESCPATH_NoLevel3Paths from "@salesforce/label/c.ESCPATH_NoLevel3Paths";
import ESCPATH_NoEscalationPaths from "@salesforce/label/c.ESCPATH_NoEscalationPaths";
import ESCPATH_NoEscalationPathsDesc from "@salesforce/label/c.ESCPATH_NoEscalationPathsDesc";
import ESCPATH_Close from "@salesforce/label/c.ESCPATH_Close";
import ESCPATH_EditEscalationPath from "@salesforce/label/c.ESCPATH_EditEscalationPath";
import ESCPATH_NewEscalationPath from "@salesforce/label/c.ESCPATH_NewEscalationPath";
import ESCPATH_UserLabel from "@salesforce/label/c.ESCPATH_UserLabel";
import ESCPATH_SelectUser from "@salesforce/label/c.ESCPATH_SelectUser";
import ESCPATH_EscalationLevel from "@salesforce/label/c.ESCPATH_EscalationLevel";
import ESCPATH_Role from "@salesforce/label/c.ESCPATH_Role";
import ESCPATH_NotificationMethod from "@salesforce/label/c.ESCPATH_NotificationMethod";
import ESCPATH_EscalationDelay from "@salesforce/label/c.ESCPATH_EscalationDelay";
import ESCPATH_Cancel from "@salesforce/label/c.ESCPATH_Cancel";
import ESCPATH_Save from "@salesforce/label/c.ESCPATH_Save";
import ESCPATH_DeleteEscalationPath from "@salesforce/label/c.ESCPATH_DeleteEscalationPath";
import ESCPATH_DeleteConfirm from "@salesforce/label/c.ESCPATH_DeleteConfirm";
import ESCPATH_CannotBeUndone from "@salesforce/label/c.ESCPATH_CannotBeUndone";
import ESCPATH_Success from "@salesforce/label/c.ESCPATH_Success";
import ESCPATH_PathUpdated from "@salesforce/label/c.ESCPATH_PathUpdated";
import ESCPATH_PathCreated from "@salesforce/label/c.ESCPATH_PathCreated";
import ESCPATH_PathDeleted from "@salesforce/label/c.ESCPATH_PathDeleted";
import ESCPATH_Error from "@salesforce/label/c.ESCPATH_Error";
import ESCPATH_SelectUserError from "@salesforce/label/c.ESCPATH_SelectUserError";
import ESCPATH_ErrorOccurred from "@salesforce/label/c.ESCPATH_ErrorOccurred";

const LEVEL_BADGES = {
  1: { label: "L1", variant: "success" },
  2: { label: "L2", variant: "warning" },
  3: { label: "L3", variant: "error" },
};

export default class EscalationPathConfig extends LightningElement {
  label = {
    ESCPATH_Title, ESCPATH_Refresh, ESCPATH_NewEscalationLevel, ESCPATH_EscalationFlow,
    ESCPATH_AlertTriggered, ESCPATH_L1TeamLead, ESCPATH_L2Manager, ESCPATH_L3CISO,
    ESCPATH_Loading, ESCPATH_Level1, ESCPATH_TeamLeadEscalation, ESCPATH_Active,
    ESCPATH_Inactive, ESCPATH_Edit, ESCPATH_Delete, ESCPATH_NoLevel1Paths,
    ESCPATH_Level2, ESCPATH_ManagerEscalation, ESCPATH_NoLevel2Paths,
    ESCPATH_Level3, ESCPATH_CISODirectorEscalation, ESCPATH_NoLevel3Paths,
    ESCPATH_NoEscalationPaths, ESCPATH_NoEscalationPathsDesc, ESCPATH_Close,
    ESCPATH_EditEscalationPath, ESCPATH_NewEscalationPath, ESCPATH_UserLabel,
    ESCPATH_SelectUser, ESCPATH_EscalationLevel, ESCPATH_Role, ESCPATH_NotificationMethod,
    ESCPATH_EscalationDelay, ESCPATH_Cancel, ESCPATH_Save, ESCPATH_DeleteEscalationPath,
    ESCPATH_DeleteConfirm, ESCPATH_CannotBeUndone, ESCPATH_Success, ESCPATH_PathUpdated,
    ESCPATH_PathCreated, ESCPATH_PathDeleted, ESCPATH_Error, ESCPATH_SelectUserError,
    ESCPATH_ErrorOccurred,
  };

  paths = [];
  isLoading = true;
  isModalOpen = false;
  isDeleteModalOpen = false;
  selectedPath = null;
  isEditMode = false;

  wiredPathsResult;

  formData = {
    userId: "",
    level: 1,
    role: "Team Lead",
    notificationMethod: "Both",
    delayMinutes: 15,
    active: true,
  };

  get levelOptions() {
    return [
      { label: "Level 1 - Team Lead", value: 1 },
      { label: "Level 2 - Manager", value: 2 },
      { label: "Level 3 - CISO/Director", value: 3 },
    ];
  }

  get roleOptions() {
    return [
      { label: "Team Lead", value: "Team Lead" },
      { label: "Manager", value: "Manager" },
      { label: "CISO", value: "CISO" },
      { label: "Director", value: "Director" },
      { label: "VP", value: "VP" },
    ];
  }

  get notificationMethodOptions() {
    return [
      { label: "Mobile Push Only", value: "Mobile" },
      { label: "Email Only", value: "Email" },
      { label: "Mobile + Email", value: "Both" },
      { label: "All Channels", value: "All" },
    ];
  }

  get delayOptions() {
    return [
      { label: "5 minutes", value: 5 },
      { label: "10 minutes", value: 10 },
      { label: "15 minutes", value: 15 },
      { label: "30 minutes", value: 30 },
      { label: "45 minutes", value: 45 },
      { label: "60 minutes", value: 60 },
    ];
  }

  get modalTitle() {
    return this.isEditMode ? this.label.ESCPATH_EditEscalationPath : this.label.ESCPATH_NewEscalationPath;
  }

  get hasPaths() {
    return this.paths && this.paths.length > 0;
  }

  get level1Paths() {
    return this.paths.filter((p) => p.level === 1);
  }

  get level2Paths() {
    return this.paths.filter((p) => p.level === 2);
  }

  get level3Paths() {
    return this.paths.filter((p) => p.level === 3);
  }

  get hasNoLevel1Paths() {
    return !this.level1Paths || this.level1Paths.length === 0;
  }

  get hasNoLevel2Paths() {
    return !this.level2Paths || this.level2Paths.length === 0;
  }

  get hasNoLevel3Paths() {
    return !this.level3Paths || this.level3Paths.length === 0;
  }

  @wire(getEscalationPaths)
  wiredPaths(result) {
    this.wiredPathsResult = result;
    this.isLoading = true;
    if (result.data) {
      this.paths = result.data.map((path) => ({
        id: path.Id,
        userId: path.User__c,
        userName: path.User__r ? path.User__r.Name : "",
        userEmail: path.User__r ? path.User__r.Email : "",
        level: Number(path.Level__c),
        role: path.Role__c,
        notificationMethod: path.Notification_Method__c,
        delayMinutes: Number(path.Escalation_Delay_Minutes__c),
        active: path.Active__c,
        badge: LEVEL_BADGES[Number(path.Level__c)],
      }));
      this.isLoading = false;
    } else if (result.error) {
      this.handleError(result.error);
      this.isLoading = false;
    }
  }

  handleNewPath() {
    this.isEditMode = false;
    this.resetFormData();
    this.isModalOpen = true;
  }

  handleEdit(event) {
    const pathId = event.currentTarget.dataset.id;
    const path = this.paths.find((p) => p.id === pathId);
    if (path) {
      this.isEditMode = true;
      this.selectedPath = path;
      this.formData = {
        id: path.id,
        userId: path.userId,
        level: path.level,
        role: path.role,
        notificationMethod: path.notificationMethod,
        delayMinutes: path.delayMinutes,
        active: path.active,
      };
      this.isModalOpen = true;
    }
  }

  handleDeleteConfirm(event) {
    const pathId = event.currentTarget.dataset.id;
    this.selectedPath = this.paths.find((p) => p.id === pathId);
    this.isDeleteModalOpen = true;
  }

  handleInputChange(event) {
    const field = event.target.dataset.field;
    let value;

    if (event.target.type === "checkbox") {
      value = event.target.checked;
    } else if (field === "level" || field === "delayMinutes") {
      value = Number(event.target.value);
    } else {
      value = event.target.value;
    }

    this.formData = { ...this.formData, [field]: value };
  }

  async handleSave() {
    if (!this.validateForm()) {
      return;
    }

    this.isLoading = true;
    try {
      const pathData = {
        User__c: this.formData.userId,
        Level__c: this.formData.level,
        Role__c: this.formData.role,
        Notification_Method__c: this.formData.notificationMethod,
        Escalation_Delay_Minutes__c: this.formData.delayMinutes,
        Active__c: this.formData.active,
      };

      if (this.isEditMode) {
        pathData.Id = this.formData.id;
        await updatePath({ path: pathData });
        this.showToast("Success", "Escalation path updated successfully", "success");
      } else {
        await createPath({ path: pathData });
        this.showToast("Success", "Escalation path created successfully", "success");
      }

      this.closeModal();
      await refreshApex(this.wiredPathsResult);
    } catch (error) {
      this.handleError(error);
    } finally {
      this.isLoading = false;
    }
  }

  async handleDelete() {
    this.isLoading = true;
    try {
      await deletePath({ pathId: this.selectedPath.id });
      this.showToast("Success", "Escalation path deleted successfully", "success");
      this.isDeleteModalOpen = false;
      await refreshApex(this.wiredPathsResult);
    } catch (error) {
      this.handleError(error);
    } finally {
      this.isLoading = false;
    }
  }

  handleModalKeydown(event) {
    if (event.key === "Escape") {
      this.closeModal();
    }
  }

  handleDeleteModalKeydown(event) {
    if (event.key === "Escape") {
      this.closeDeleteModal();
    }
  }

  closeModal() {
    this.isModalOpen = false;
    this.resetFormData();
  }

  closeDeleteModal() {
    this.isDeleteModalOpen = false;
    this.selectedPath = null;
  }

  validateForm() {
    const allValid = [
      ...this.template.querySelectorAll("lightning-input, lightning-combobox"),
    ].reduce((validSoFar, input) => {
      input.reportValidity();
      return validSoFar && input.checkValidity();
    }, true);

    if (!this.formData.userId) {
      this.showToast("Error", "Please select a user", "error");
      return false;
    }

    return allValid;
  }

  resetFormData() {
    this.formData = {
      userId: "",
      level: 1,
      role: "Team Lead",
      notificationMethod: "Both",
      delayMinutes: 15,
      active: true,
    };
    this.selectedPath = null;
  }

  showToast(title, message, variant) {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
  }

  handleError(error) {
    const message = error.body?.message || error.message || "An error occurred";
    this.showToast("Error", message, "error");
  }

  handleRefresh() {
    this.isLoading = true;
    refreshApex(this.wiredPathsResult).finally(() => {
      this.isLoading = false;
    });
  }
}
