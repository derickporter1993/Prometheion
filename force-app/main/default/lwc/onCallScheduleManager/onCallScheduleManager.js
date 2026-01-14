import { LightningElement, wire, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { refreshApex } from "@salesforce/apex";
import getCurrentOnCallUsers from "@salesforce/apex/MobileAlertPublisher.getCurrentOnCallUsers";
import getOnCallSchedules from "@salesforce/apex/OnCallScheduleController.getSchedules";
import createSchedule from "@salesforce/apex/OnCallScheduleController.createSchedule";
import updateSchedule from "@salesforce/apex/OnCallScheduleController.updateSchedule";
import deleteSchedule from "@salesforce/apex/OnCallScheduleController.deleteSchedule";

const COLUMNS = [
  { label: "Name", fieldName: "name", type: "text" },
  { label: "User", fieldName: "userName", type: "text" },
  { label: "Rotation", fieldName: "rotationName", type: "text" },
  {
    label: "Start Time",
    fieldName: "startTime",
    type: "date",
    typeAttributes: {
      year: "numeric",
      month: "short",
      day: "2-digit",
      hour: "2-digit",
      minute: "2-digit",
    },
  },
  {
    label: "End Time",
    fieldName: "endTime",
    type: "date",
    typeAttributes: {
      year: "numeric",
      month: "short",
      day: "2-digit",
      hour: "2-digit",
      minute: "2-digit",
    },
  },
  { label: "Active", fieldName: "active", type: "boolean" },
  {
    type: "action",
    typeAttributes: {
      rowActions: [
        { label: "Edit", name: "edit" },
        { label: "Delete", name: "delete" },
      ],
    },
  },
];

export default class OnCallScheduleManager extends LightningElement {
  @track schedules = [];
  @track currentOnCall = [];
  @track isLoading = true;
  @track isModalOpen = false;
  @track isDeleteModalOpen = false;
  @track selectedSchedule = null;
  @track isEditMode = false;

  columns = COLUMNS;
  wiredSchedulesResult;
  wiredOnCallResult;

  // Form fields
  @track formData = {
    name: "",
    userId: "",
    rotationName: "Primary",
    startTime: "",
    endTime: "",
    timezone: "America/New_York",
    notificationMethods: ["Mobile", "Email"],
    active: true,
  };

  get timezoneOptions() {
    return [
      { label: "Eastern (EST/EDT)", value: "America/New_York" },
      { label: "Central (CST/CDT)", value: "America/Chicago" },
      { label: "Mountain (MST/MDT)", value: "America/Denver" },
      { label: "Pacific (PST/PDT)", value: "America/Los_Angeles" },
      { label: "London (GMT/BST)", value: "Europe/London" },
      { label: "UTC", value: "UTC" },
    ];
  }

  get rotationOptions() {
    return [
      { label: "Primary", value: "Primary" },
      { label: "Secondary", value: "Secondary" },
      { label: "Weekend", value: "Weekend" },
      { label: "Holiday", value: "Holiday" },
    ];
  }

  get notificationOptions() {
    return [
      { label: "Mobile Push", value: "Mobile" },
      { label: "Email", value: "Email" },
      { label: "Slack", value: "Slack" },
    ];
  }

  get modalTitle() {
    return this.isEditMode ? "Edit On-Call Schedule" : "New On-Call Schedule";
  }

  get hasSchedules() {
    return this.schedules && this.schedules.length > 0;
  }

  get hasCurrentOnCall() {
    return this.currentOnCall && this.currentOnCall.length > 0;
  }

  @wire(getOnCallSchedules)
  wiredSchedules(result) {
    this.wiredSchedulesResult = result;
    this.isLoading = true;
    if (result.data) {
      this.schedules = result.data.map((schedule) => ({
        id: schedule.Id,
        name: schedule.Name,
        userId: schedule.User__c,
        userName: schedule.User__r ? schedule.User__r.Name : "",
        rotationName: schedule.Rotation_Name__c,
        startTime: schedule.Start_Time__c,
        endTime: schedule.End_Time__c,
        timezone: schedule.Timezone__c,
        notificationMethods: schedule.Notification_Methods__c,
        active: schedule.Active__c,
      }));
      this.isLoading = false;
    } else if (result.error) {
      this.handleError(result.error);
      this.isLoading = false;
    }
  }

  @wire(getCurrentOnCallUsers)
  wiredOnCall(result) {
    this.wiredOnCallResult = result;
    if (result.data) {
      this.currentOnCall = result.data;
    } else if (result.error) {
      console.error("Error loading on-call users:", result.error);
    }
  }

  handleNewSchedule() {
    this.isEditMode = false;
    this.resetFormData();
    this.isModalOpen = true;
  }

  handleRowAction(event) {
    const action = event.detail.action;
    const row = event.detail.row;

    switch (action.name) {
      case "edit":
        this.handleEdit(row);
        break;
      case "delete":
        this.handleDeleteConfirm(row);
        break;
      default:
        break;
    }
  }

  handleEdit(row) {
    this.isEditMode = true;
    this.selectedSchedule = row;
    this.formData = {
      id: row.id,
      name: row.name,
      userId: row.userId,
      rotationName: row.rotationName,
      startTime: row.startTime,
      endTime: row.endTime,
      timezone: row.timezone,
      notificationMethods: row.notificationMethods ? row.notificationMethods.split(";") : [],
      active: row.active,
    };
    this.isModalOpen = true;
  }

  handleDeleteConfirm(row) {
    this.selectedSchedule = row;
    this.isDeleteModalOpen = true;
  }

  handleInputChange(event) {
    const field = event.target.dataset.field;
    let value = event.target.type === "checkbox" ? event.target.checked : event.target.value;

    if (field === "notificationMethods") {
      value = event.detail.value;
    }

    this.formData = { ...this.formData, [field]: value };
  }

  async handleSave() {
    if (!this.validateForm()) {
      return;
    }

    this.isLoading = true;
    try {
      const scheduleData = {
        Name: this.formData.name,
        User__c: this.formData.userId,
        Rotation_Name__c: this.formData.rotationName,
        Start_Time__c: this.formData.startTime,
        End_Time__c: this.formData.endTime,
        Timezone__c: this.formData.timezone,
        Notification_Methods__c: this.formData.notificationMethods.join(";"),
        Active__c: this.formData.active,
      };

      if (this.isEditMode) {
        scheduleData.Id = this.formData.id;
        await updateSchedule({ schedule: scheduleData });
        this.showToast("Success", "Schedule updated successfully", "success");
      } else {
        await createSchedule({ schedule: scheduleData });
        this.showToast("Success", "Schedule created successfully", "success");
      }

      this.closeModal();
      await refreshApex(this.wiredSchedulesResult);
      await refreshApex(this.wiredOnCallResult);
    } catch (error) {
      this.handleError(error);
    } finally {
      this.isLoading = false;
    }
  }

  async handleDelete() {
    this.isLoading = true;
    try {
      await deleteSchedule({ scheduleId: this.selectedSchedule.id });
      this.showToast("Success", "Schedule deleted successfully", "success");
      this.isDeleteModalOpen = false;
      await refreshApex(this.wiredSchedulesResult);
      await refreshApex(this.wiredOnCallResult);
    } catch (error) {
      this.handleError(error);
    } finally {
      this.isLoading = false;
    }
  }

  closeModal() {
    this.isModalOpen = false;
    this.resetFormData();
  }

  closeDeleteModal() {
    this.isDeleteModalOpen = false;
    this.selectedSchedule = null;
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

    if (new Date(this.formData.startTime) >= new Date(this.formData.endTime)) {
      this.showToast("Error", "End time must be after start time", "error");
      return false;
    }

    return allValid;
  }

  resetFormData() {
    this.formData = {
      name: "",
      userId: "",
      rotationName: "Primary",
      startTime: "",
      endTime: "",
      timezone: "America/New_York",
      notificationMethods: ["Mobile", "Email"],
      active: true,
    };
    this.selectedSchedule = null;
  }

  showToast(title, message, variant) {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
  }

  handleError(error) {
    const message = error.body?.message || error.message || "An error occurred";
    this.showToast("Error", message, "error");
    console.error("Error:", error);
  }

  handleRefresh() {
    this.isLoading = true;
    Promise.all([
      refreshApex(this.wiredSchedulesResult),
      refreshApex(this.wiredOnCallResult),
    ]).finally(() => {
      this.isLoading = false;
    });
  }
}
