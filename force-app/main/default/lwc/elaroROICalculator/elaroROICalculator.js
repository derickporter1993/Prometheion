import { LightningElement, api, track } from "lwc";

export default class ElaroROICalculator extends LightningElement {
  @api title = "ROI Calculator";
  @track orgSize = 500;
  @track industry = "healthcare";
  @track currentAuditSpend = 150000;
  @track currentAuditPrepHours = 600;
  @track hourlyRate = 200;

  @track roiResults = null;
  @track showResults = false;
  @track isLoading = false;
  @track hasError = false;
  @track errorMessage = "";

  get isEmpty() {
    return !this.isLoading && !this.hasError && !this.showResults;
  }

  industryOptions = [
    { label: "Healthcare", value: "healthcare" },
    { label: "Financial Services", value: "finance" },
    { label: "Government", value: "government" },
    { label: "Enterprise", value: "enterprise" },
  ];

  // Industry-specific defaults
  industryDefaults = {
    healthcare: {
      auditPrepHours: 600,
      auditSpend: 150000,
      elaroCost: 45000,
      timeReduction: 0.85,
    },
    finance: {
      auditPrepHours: 500,
      auditSpend: 120000,
      elaroCost: 35000,
      timeReduction: 0.8,
    },
    government: {
      auditPrepHours: 700,
      auditSpend: 200000,
      elaroCost: 60000,
      timeReduction: 0.85,
    },
    enterprise: {
      auditPrepHours: 400,
      auditSpend: 100000,
      elaroCost: 30000,
      timeReduction: 0.75,
    },
  };

  handleIndustryChange(event) {
    this.industry = event.detail.value;
    const defaults = this.industryDefaults[this.industry];
    this.currentAuditPrepHours = defaults.auditPrepHours;
    this.currentAuditSpend = defaults.auditSpend;
    this.calculateROI();
  }

  handleOrgSizeChange(event) {
    this.orgSize = parseInt(event.detail.value, 10);
    this.calculateROI();
  }

  handleAuditSpendChange(event) {
    this.currentAuditSpend = parseInt(event.detail.value, 10);
    this.calculateROI();
  }

  handleHoursChange(event) {
    this.currentAuditPrepHours = parseInt(event.detail.value, 10);
    this.calculateROI();
  }

  handleRateChange(event) {
    this.hourlyRate = parseInt(event.detail.value, 10);
    this.calculateROI();
  }

  calculateROI() {
    const defaults = this.industryDefaults[this.industry];
    const timeReduction = defaults.timeReduction;
    const elaroCost = defaults.elaroCost;

    // Calculate time savings (85% reduction in audit prep time)
    const timeSavings = this.currentAuditPrepHours * timeReduction;
    const timeSavingsDollars = timeSavings * this.hourlyRate;

    // Calculate audit cost reduction (30% reduction in external audit costs)
    const auditCostReduction = this.currentAuditSpend * 0.3;

    // Total annual savings
    const totalSavings = timeSavingsDollars + auditCostReduction;

    // Net benefit
    const netBenefit = totalSavings - elaroCost;

    // Payback period (weeks)
    const weeklySavings = totalSavings / 52;
    const paybackWeeks = weeklySavings > 0 ? Math.round(elaroCost / weeklySavings) : 0;

    // ROI percentage
    const roi = elaroCost > 0 ? Math.round((netBenefit / elaroCost) * 100) : 0;

    this.roiResults = {
      timeSavings: Math.round(timeSavings),
      timeSavingsDollars: Math.round(timeSavingsDollars),
      auditCostReduction: Math.round(auditCostReduction),
      totalSavings: Math.round(totalSavings),
      elaroCost: elaroCost,
      netBenefit: Math.round(netBenefit),
      paybackWeeks: paybackWeeks,
      roi: roi,
      monthlySavings: Math.round(totalSavings / 12),
    };

    this.showResults = true;
  }

  connectedCallback() {
    this.calculateROI();
  }

  get hasPositiveROI() {
    return this.roiResults && this.roiResults.roi > 0;
  }

  get hasNegativeROI() {
    return !this.hasPositiveROI;
  }

  get roiClass() {
    return this.hasPositiveROI ? "roi-positive" : "roi-negative";
  }

  // Formatted getters for template expressions (LWC doesn't allow method calls in templates)
  get formattedTimeSavingsDollars() {
    return this.roiResults ? this.roiResults.timeSavingsDollars.toLocaleString() : "0";
  }

  get formattedAuditCostReduction() {
    return this.roiResults ? this.roiResults.auditCostReduction.toLocaleString() : "0";
  }

  get formattedTotalSavings() {
    return this.roiResults ? this.roiResults.totalSavings.toLocaleString() : "0";
  }

  get formattedMonthlySavings() {
    return this.roiResults ? this.roiResults.monthlySavings.toLocaleString() : "0";
  }

  get formattedElaroCost() {
    return this.roiResults ? this.roiResults.elaroCost.toLocaleString() : "0";
  }

  get formattedNetBenefit() {
    return this.roiResults ? this.roiResults.netBenefit.toLocaleString() : "0";
  }
}
