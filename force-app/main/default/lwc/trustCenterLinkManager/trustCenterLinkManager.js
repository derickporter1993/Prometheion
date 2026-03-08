import { LightningElement, wire } from "lwc";
import { refreshApex } from "@salesforce/apex";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getActiveLinks from "@salesforce/apex/TrustCenterController.getActiveLinks";
import createShareableLink from "@salesforce/apex/TrustCenterController.createShareableLink";
import revokeLink from "@salesforce/apex/TrustCenterController.revokeLink";
import TC_LinkManager from "@salesforce/label/c.TC_LinkManager";
import TC_CreateLink from "@salesforce/label/c.TC_CreateLink";
import TC_CopyLink from "@salesforce/label/c.TC_CopyLink";
import TC_LinkCopied from "@salesforce/label/c.TC_LinkCopied";
import TC_RevokeLink from "@salesforce/label/c.TC_RevokeLink";
import TC_LinkCreated from "@salesforce/label/c.TC_LinkCreated";
import TC_LinkRevoked from "@salesforce/label/c.TC_LinkRevoked";
import TC_ShareableLinks from "@salesforce/label/c.TC_ShareableLinks";
import TC_AccessTier from "@salesforce/label/c.TC_AccessTier";
import TC_ExpirationDate from "@salesforce/label/c.TC_ExpirationDate";
import TC_ExpirationDays from "@salesforce/label/c.TC_ExpirationDays";
import TC_AccessCount from "@salesforce/label/c.TC_AccessCount";
import TC_CreatedFor from "@salesforce/label/c.TC_CreatedFor";
import TC_Loading from "@salesforce/label/c.TC_Loading";
import TC_Error from "@salesforce/label/c.TC_Error";
import TC_ErrorGeneric from "@salesforce/label/c.TC_ErrorGeneric";
import TC_DeactivateLink from "@salesforce/label/c.TC_DeactivateLink";
import TC_AccessTierPublic from "@salesforce/label/c.TC_AccessTierPublic";
import TC_AccessTierEmailGated from "@salesforce/label/c.TC_AccessTierEmailGated";
import TC_AccessTierNDA from "@salesforce/label/c.TC_AccessTierNDA";

const ACTIONS = [
  { label: TC_CopyLink, name: "copy" },
  { label: TC_RevokeLink, name: "revoke" },
];

const COLUMNS = [
  { label: TC_CreatedFor, fieldName: "Created_For__c", type: "text" },
  { label: TC_AccessTier, fieldName: "accessTierLabel", type: "text" },
  {
    label: TC_ExpirationDate,
    fieldName: "Expiration_Date__c",
    type: "date",
    typeAttributes: {
      year: "numeric",
      month: "short",
      day: "2-digit",
    },
  },
  { label: TC_AccessCount, fieldName: "Access_Count__c", type: "number" },
  {
    type: "action",
    typeAttributes: { rowActions: ACTIONS },
  },
];

/**
 * Admin component for managing shareable Trust Center links.
 * Displays active links in a datatable with create, copy, and revoke actions.
 *
 * @author Elaro Team
 * @since v3.1.0 (Spring '26)
 * @group Trust Center
 */
export default class TrustCenterLinkManager extends LightningElement {
  label = {
    TC_LinkManager,
    TC_CreateLink,
    TC_CopyLink,
    TC_LinkCopied,
    TC_RevokeLink,
    TC_LinkCreated,
    TC_LinkRevoked,
    TC_ShareableLinks,
    TC_AccessTier,
    TC_ExpirationDate,
    TC_ExpirationDays,
    TC_AccessCount,
    TC_CreatedFor,
    TC_Loading,
    TC_Error,
    TC_ErrorGeneric,
    TC_DeactivateLink,
    TC_AccessTierPublic,
    TC_AccessTierEmailGated,
    TC_AccessTierNDA,
  };

  links = [];
  error;
  isLoading = true;
  isModalOpen = false;
  isCreating = false;
  _wiredLinksResult;

  // New link form fields
  newLinkAccessTier = "Public";
  newLinkExpirationDays = 30;
  newLinkCreatedFor = "";

  columns = COLUMNS;

  get accessTierOptions() {
    return [
      { label: this.label.TC_AccessTierPublic, value: "Public" },
      { label: this.label.TC_AccessTierEmailGated, value: "Email_Gated" },
      { label: this.label.TC_AccessTierNDA, value: "NDA_Required" },
    ];
  }

  get accessTierLabelMap() {
    return {
      Public: this.label.TC_AccessTierPublic,
      Email_Gated: this.label.TC_AccessTierEmailGated,
      NDA_Required: this.label.TC_AccessTierNDA,
    };
  }

  @wire(getActiveLinks)
  wiredLinks(result) {
    this._wiredLinksResult = result;
    const { error, data } = result;
    this.isLoading = false;
    if (data) {
      this.links = data;
      this.error = undefined;
    } else if (error) {
      this.error = error;
      this.links = [];
    }
  }

  get hasError() {
    return !!this.error;
  }

  get isEmpty() {
    return !this.links || this.links.length === 0;
  }

  get emptyStateMessage() {
    return "No active shareable links. Create a link to share your compliance posture.";
  }

  get tableData() {
    const tierMap = this.accessTierLabelMap;
    return this.links.map((link) => ({
      ...link,
      accessTierLabel: tierMap[link.Access_Tier__c] ?? link.Access_Tier__c,
    }));
  }

  get errorMessage() {
    if (!this.error) {
      return "";
    }
    return this.error?.body?.message || this.error?.message || this.label.TC_ErrorGeneric;
  }

  handleOpenCreateModal() {
    this.newLinkAccessTier = "Public";
    this.newLinkExpirationDays = 30;
    this.newLinkCreatedFor = "";
    this.isModalOpen = true;
  }

  handleCloseModal() {
    this.isModalOpen = false;
  }

  handleAccessTierChange(event) {
    this.newLinkAccessTier = event.detail.value;
  }

  handleExpirationDaysChange(event) {
    this.newLinkExpirationDays = Number(event.detail.value);
  }

  handleCreatedForChange(event) {
    this.newLinkCreatedFor = event.detail.value;
  }

  async handleCreateLink() {
    this.isCreating = true;
    try {
      const newLink = await createShareableLink({
        accessTier: this.newLinkAccessTier,
        expirationDays: this.newLinkExpirationDays,
        createdFor: this.newLinkCreatedFor,
      });

      this.isModalOpen = false;

      this.dispatchEvent(
        new ShowToastEvent({
          title: this.label.TC_LinkManager,
          message: this.label.TC_LinkCreated,
          variant: "success",
        })
      );

      // Copy the new link URL to clipboard immediately
      if (newLink?.Link_Token__c) {
        this._copyTokenToClipboard(newLink.Link_Token__c);
      }

      await refreshApex(this._wiredLinksResult);
    } catch (err) {
      this.dispatchEvent(
        new ShowToastEvent({
          title: this.label.TC_Error,
          message: err?.body?.message || this.label.TC_ErrorGeneric,
          variant: "error",
        })
      );
    } finally {
      this.isCreating = false;
    }
  }

  async handleRowAction(event) {
    const actionName = event.detail.action.name;
    const row = event.detail.row;

    if (actionName === "copy") {
      this._copyTokenToClipboard(row.Link_Token__c);
    } else if (actionName === "revoke") {
      await this._revokeLink(row.Id);
    }
  }

  async _revokeLink(linkId) {
    try {
      await revokeLink({ linkId });
      this.dispatchEvent(
        new ShowToastEvent({
          title: this.label.TC_LinkManager,
          message: this.label.TC_LinkRevoked,
          variant: "success",
        })
      );
      await refreshApex(this._wiredLinksResult);
    } catch (err) {
      this.dispatchEvent(
        new ShowToastEvent({
          title: this.label.TC_Error,
          message: err?.body?.message || this.label.TC_ErrorGeneric,
          variant: "error",
        })
      );
    }
  }

  _copyTokenToClipboard(token) {
    if (!token) {
      return;
    }
    const linkUrl = `${window.location.origin}/trust-center?token=${token}`;
    if (window.navigator?.clipboard) {
      window.navigator.clipboard
        .writeText(linkUrl)
        .then(() => {
          this.dispatchEvent(
            new ShowToastEvent({
              title: this.label.TC_LinkManager,
              message: this.label.TC_LinkCopied,
              variant: "success",
            })
          );
        })
        .catch(() => {
          this._fallbackCopy(linkUrl);
        });
    } else {
      this._fallbackCopy(linkUrl);
    }
  }

  _fallbackCopy(text) {
    const textArea = document.createElement("textarea");
    textArea.value = text;
    textArea.style.position = "fixed";
    textArea.style.left = "-9999px";
    document.body.appendChild(textArea);
    textArea.focus();
    textArea.select();
    try {
      document.execCommand("copy");
      this.dispatchEvent(
        new ShowToastEvent({
          title: this.label.TC_LinkManager,
          message: this.label.TC_LinkCopied,
          variant: "success",
        })
      );
    } catch (e) {
      // Clipboard copy failed silently
    }
    document.body.removeChild(textArea);
  }
}
