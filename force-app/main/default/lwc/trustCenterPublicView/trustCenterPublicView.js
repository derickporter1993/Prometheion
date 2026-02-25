import { LightningElement } from "lwc";
import getPublicData from "@salesforce/apex/TrustCenterGuestController.getPublicData";
import TC_PublicViewTitle from "@salesforce/label/c.TC_PublicViewTitle";
import TC_ComplianceStatus from "@salesforce/label/c.TC_ComplianceStatus";
import TC_NoFrameworks from "@salesforce/label/c.TC_NoFrameworks";
import TC_Loading from "@salesforce/label/c.TC_Loading";
import TC_Error from "@salesforce/label/c.TC_Error";
import TC_ErrorGeneric from "@salesforce/label/c.TC_ErrorGeneric";
import TC_InvalidLink from "@salesforce/label/c.TC_InvalidLink";
import TC_ExpiredLink from "@salesforce/label/c.TC_ExpiredLink";
import TC_InvalidToken from "@salesforce/label/c.TC_InvalidToken";

/**
 * Public-facing Trust Center view for Sites/Guest users.
 * Validates link token from URL and displays public compliance badges.
 *
 * SECURITY: This component only calls TrustCenterGuestController which
 * validates tokens and only returns Is_Public__c = true records.
 * No sensitive data is exposed through this component.
 *
 * @author Elaro Team
 * @since v3.1.0 (Spring '26)
 * @group Trust Center
 */
export default class TrustCenterPublicView extends LightningElement {
  label = {
    TC_PublicViewTitle,
    TC_ComplianceStatus,
    TC_NoFrameworks,
    TC_Loading,
    TC_Error,
    TC_ErrorGeneric,
    TC_InvalidLink,
    TC_ExpiredLink,
    TC_InvalidToken,
  };

  views = [];
  isLoading = true;
  isValid = false;
  errorMessage = "";

  connectedCallback() {
    this._loadPublicData();
  }

  get hasError() {
    return !this.isLoading && !this.isValid;
  }

  get isValidButEmpty() {
    return this.isValid && (!this.views || this.views.length === 0);
  }

  get displayErrorMessage() {
    return this.errorMessage || this.label.TC_InvalidToken;
  }

  async _loadPublicData() {
    this.isLoading = true;
    try {
      const token = this._extractTokenFromUrl();

      if (!token) {
        this.isValid = false;
        this.errorMessage = this.label.TC_InvalidLink;
        this.isLoading = false;
        return;
      }

      const response = await getPublicData({ token });

      if (response.isValid) {
        this.isValid = true;
        this.views = response.views || [];
        this.errorMessage = "";
      } else {
        this.isValid = false;
        this.errorMessage = response.errorMessage || this.label.TC_InvalidToken;
      }
    } catch (err) {
      this.isValid = false;
      this.errorMessage = err?.body?.message || this.label.TC_ErrorGeneric;
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * Extracts the token parameter from the current page URL.
   * Supports both standard URL params and Lightning Community URL patterns.
   *
   * @returns {string|null} Token value or null if not found
   */
  _extractTokenFromUrl() {
    try {
      const UrlSearchParams = window.URLSearchParams;
      const urlParams = new UrlSearchParams(window.location.search);
      const token = urlParams.get("token");
      if (token) {
        return token;
      }

      // Fallback: check hash-based routing (Lightning Communities)
      const hash = window.location.hash;
      if (hash && hash.includes("token=")) {
        const hashParams = new UrlSearchParams(hash.substring(hash.indexOf("?")));
        return hashParams.get("token");
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}
