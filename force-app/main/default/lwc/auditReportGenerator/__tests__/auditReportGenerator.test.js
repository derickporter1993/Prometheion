/**
 * Jest tests for auditReportGenerator LWC component
 *
 * Tests cover:
 * - Report generation
 * - PDF export
 * - Form validation
 * - Error handling
 */

import { createElement } from "lwc";
import AuditReportGenerator from "c/auditReportGenerator";
import generateAuditReport from "@salesforce/apex/AuditReportController.generateAuditReport";
import exportReportAsPDF from "@salesforce/apex/AuditReportController.exportReportAsPDF";

jest.mock(
  "@salesforce/apex/AuditReportController.generateAuditReport",
  () => ({ default: jest.fn() }),
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/AuditReportController.exportReportAsPDF",
  () => ({ default: jest.fn() }),
  { virtual: true }
);

describe("c-audit-report-generator", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  async function createComponent() {
    const element = createElement("c-audit-report-generator", {
      is: AuditReportGenerator,
    });
    document.body.appendChild(element);
    await Promise.resolve();
    return element;
  }

  // Helper to flush all pending promises
  async function flushPromises() {
    await Promise.resolve();
    await Promise.resolve();
    await Promise.resolve();
  }

  // Helper to find date inputs by label
  function findInputByLabel(element, labelText) {
    const inputs = element.shadowRoot.querySelectorAll("lightning-input");
    return Array.from(inputs).find((input) => input.label === labelText);
  }

  // Helper to find button by label
  function findButtonByLabel(element, labelText) {
    const buttons = element.shadowRoot.querySelectorAll("lightning-button");
    return Array.from(buttons).find((btn) => btn.label === labelText);
  }

  describe("Rendering", () => {
    it("renders the component with lightning-card", async () => {
      const element = await createComponent();
      await flushPromises();

      const card = element.shadowRoot.querySelector("lightning-card");
      expect(card).not.toBeNull();
      expect(card.title).toBe("Audit Report Generator");
    });

    it("renders framework combobox", async () => {
      const element = await createComponent();
      await flushPromises();

      const combobox = element.shadowRoot.querySelector("lightning-combobox");
      expect(combobox).not.toBeNull();
      expect(combobox.label).toBe("Framework");
    });

    it("renders start and end date inputs", async () => {
      const element = await createComponent();
      await flushPromises();

      const startDateInput = findInputByLabel(element, "Start Date");
      const endDateInput = findInputByLabel(element, "End Date");

      expect(startDateInput).not.toBeNull();
      expect(endDateInput).not.toBeNull();
    });

    it("renders generate report button", async () => {
      const element = await createComponent();
      await flushPromises();

      const generateButton = findButtonByLabel(element, "Generate Report");
      expect(generateButton).not.toBeNull();
    });
  });

  describe("Form Input Handlers", () => {
    it("handles framework change via combobox", async () => {
      const element = await createComponent();
      await flushPromises();

      const combobox = element.shadowRoot.querySelector("lightning-combobox");
      combobox.dispatchEvent(
        new CustomEvent("change", {
          detail: { value: "SOC2" },
        })
      );

      await flushPromises();

      // Verify the combobox value is updated by checking the DOM
      expect(combobox.value).toBe("SOC2");
    });

    it("handles start date change via input", async () => {
      const element = await createComponent();
      await flushPromises();

      const startDateInput = findInputByLabel(element, "Start Date");
      expect(startDateInput).not.toBeNull();

      startDateInput.dispatchEvent(
        new CustomEvent("change", {
          detail: { value: "2025-01-01" },
        })
      );

      await flushPromises();

      // After input change, value should be reflected
      expect(startDateInput.value).toBe("2025-01-01");
    });

    it("handles end date change via input", async () => {
      const element = await createComponent();
      await flushPromises();

      const endDateInput = findInputByLabel(element, "End Date");
      expect(endDateInput).not.toBeNull();

      endDateInput.dispatchEvent(
        new CustomEvent("change", {
          detail: { value: "2025-03-31" },
        })
      );

      await flushPromises();

      expect(endDateInput.value).toBe("2025-03-31");
    });
  });

  describe("Report Generation", () => {
    it("generates report successfully and displays summary", async () => {
      const mockReportData = {
        framework: "SOC2",
        startDate: "2025-01-01",
        endDate: "2025-03-31",
        evaluation: {
          overallScore: 85,
          status: "Compliant",
        },
        totalGaps: 5,
        openGaps: 2,
        totalEvidence: 150,
        sections: [],
      };

      generateAuditReport.mockResolvedValue(mockReportData);

      const element = await createComponent();
      await flushPromises();

      // Set form values via DOM events
      const combobox = element.shadowRoot.querySelector("lightning-combobox");
      combobox.dispatchEvent(new CustomEvent("change", { detail: { value: "SOC2" } }));

      const startDateInput = findInputByLabel(element, "Start Date");
      const endDateInput = findInputByLabel(element, "End Date");

      startDateInput.dispatchEvent(new CustomEvent("change", { detail: { value: "2025-01-01" } }));
      endDateInput.dispatchEvent(new CustomEvent("change", { detail: { value: "2025-03-31" } }));

      await flushPromises();

      // Click generate button
      const generateButton = findButtonByLabel(element, "Generate Report");
      generateButton.click();

      await flushPromises();

      expect(generateAuditReport).toHaveBeenCalledWith({
        framework: "SOC2",
        startDate: "2025-01-01",
        endDate: "2025-03-31",
      });

      // Check that report summary is displayed
      const summaryHeading = element.shadowRoot.querySelector(".slds-text-heading_medium");
      expect(summaryHeading).not.toBeNull();
      expect(summaryHeading.textContent).toBe("Report Summary");

      // Check that Export PDF button appears after report generation
      const exportButton = findButtonByLabel(element, "Export PDF");
      expect(exportButton).not.toBeNull();
    });

    it("shows error message when required fields missing", async () => {
      const element = await createComponent();
      await flushPromises();

      // Clear the default framework value
      const combobox = element.shadowRoot.querySelector("lightning-combobox");
      combobox.dispatchEvent(new CustomEvent("change", { detail: { value: "" } }));

      await flushPromises();

      // Click generate without filling required fields
      const generateButton = findButtonByLabel(element, "Generate Report");
      generateButton.click();

      await flushPromises();

      // Check for error message in DOM
      const errorDiv = element.shadowRoot.querySelector(".slds-text-color_error");
      expect(errorDiv).not.toBeNull();
      expect(errorDiv.textContent).toContain("Please select framework and date range");

      expect(generateAuditReport).not.toHaveBeenCalled();
    });

    it("shows error message when generation fails", async () => {
      const error = {
        body: { message: "Generation failed" },
        message: "Generation failed",
      };

      generateAuditReport.mockRejectedValue(error);

      const element = await createComponent();
      await flushPromises();

      // Set form values
      const combobox = element.shadowRoot.querySelector("lightning-combobox");
      combobox.dispatchEvent(new CustomEvent("change", { detail: { value: "SOC2" } }));

      const startDateInput = findInputByLabel(element, "Start Date");
      const endDateInput = findInputByLabel(element, "End Date");

      startDateInput.dispatchEvent(new CustomEvent("change", { detail: { value: "2025-01-01" } }));
      endDateInput.dispatchEvent(new CustomEvent("change", { detail: { value: "2025-03-31" } }));

      await flushPromises();

      // Click generate button
      const generateButton = findButtonByLabel(element, "Generate Report");
      generateButton.click();

      await flushPromises();

      // Check for error message in DOM
      const errorDiv = element.shadowRoot.querySelector(".slds-text-color_error");
      expect(errorDiv).not.toBeNull();
      expect(errorDiv.textContent).toContain("Generation failed");
    });

    it("shows loading spinner during generation", async () => {
      // Use a promise that we can control
      let resolveGenerate;
      generateAuditReport.mockImplementation(
        () =>
          new Promise((resolve) => {
            resolveGenerate = resolve;
          })
      );

      const element = await createComponent();
      await flushPromises();

      // Set form values
      const combobox = element.shadowRoot.querySelector("lightning-combobox");
      combobox.dispatchEvent(new CustomEvent("change", { detail: { value: "SOC2" } }));

      const startDateInput = findInputByLabel(element, "Start Date");
      const endDateInput = findInputByLabel(element, "End Date");

      startDateInput.dispatchEvent(new CustomEvent("change", { detail: { value: "2025-01-01" } }));
      endDateInput.dispatchEvent(new CustomEvent("change", { detail: { value: "2025-03-31" } }));

      await flushPromises();

      // Click generate button
      const generateButton = findButtonByLabel(element, "Generate Report");
      generateButton.click();

      await Promise.resolve();

      // Check for spinner while loading
      const spinner = element.shadowRoot.querySelector("lightning-spinner");
      expect(spinner).not.toBeNull();

      // Resolve the promise to complete
      resolveGenerate({
        evaluation: { overallScore: 85, status: "OK" },
        totalGaps: 0,
        openGaps: 0,
        totalEvidence: 0,
      });
      await flushPromises();
    });
  });

  describe("PDF Export", () => {
    it("exports report as PDF successfully", async () => {
      const mockReportData = {
        framework: "SOC2",
        evaluation: { overallScore: 85, status: "OK" },
        totalGaps: 0,
        openGaps: 0,
        totalEvidence: 0,
        sections: [],
      };

      generateAuditReport.mockResolvedValue(mockReportData);
      exportReportAsPDF.mockResolvedValue("069xx0000000001");

      const element = await createComponent();
      await flushPromises();

      // Set form values and generate report first
      const combobox = element.shadowRoot.querySelector("lightning-combobox");
      combobox.dispatchEvent(new CustomEvent("change", { detail: { value: "SOC2" } }));

      const startDateInput = findInputByLabel(element, "Start Date");
      const endDateInput = findInputByLabel(element, "End Date");

      startDateInput.dispatchEvent(new CustomEvent("change", { detail: { value: "2025-01-01" } }));
      endDateInput.dispatchEvent(new CustomEvent("change", { detail: { value: "2025-03-31" } }));

      await flushPromises();

      // Generate report first
      const generateButton = findButtonByLabel(element, "Generate Report");
      generateButton.click();

      await flushPromises();

      // Mock window.open
      const openSpy = jest.spyOn(window, "open").mockImplementation(() => {});

      // Now click Export PDF
      const exportButton = findButtonByLabel(element, "Export PDF");
      expect(exportButton).not.toBeNull();
      exportButton.click();

      await flushPromises();

      expect(exportReportAsPDF).toHaveBeenCalledWith({
        report: mockReportData,
      });

      openSpy.mockRestore();
    });

    it("shows Export PDF button after report generation", async () => {
      const mockReportData = {
        framework: "SOC2",
        evaluation: { overallScore: 85, status: "OK" },
        totalGaps: 0,
        openGaps: 0,
        totalEvidence: 0,
      };
      generateAuditReport.mockResolvedValue(mockReportData);

      const element = await createComponent();
      await flushPromises();

      // Set form values
      const combobox = element.shadowRoot.querySelector("lightning-combobox");
      combobox.dispatchEvent(new CustomEvent("change", { detail: { value: "SOC2" } }));

      const startDateInput = findInputByLabel(element, "Start Date");
      const endDateInput = findInputByLabel(element, "End Date");

      startDateInput.dispatchEvent(new CustomEvent("change", { detail: { value: "2025-01-01" } }));
      endDateInput.dispatchEvent(new CustomEvent("change", { detail: { value: "2025-03-31" } }));

      await flushPromises();

      // Generate first to show export button
      const generateButton = findButtonByLabel(element, "Generate Report");
      generateButton.click();
      await flushPromises();

      // Export button should exist now
      const exportButton = findButtonByLabel(element, "Export PDF");
      expect(exportButton).not.toBeNull();
    });

    it("handles PDF export error", async () => {
      const mockReportData = {
        framework: "SOC2",
        evaluation: { overallScore: 85, status: "OK" },
        totalGaps: 0,
        openGaps: 0,
        totalEvidence: 0,
        sections: [],
      };

      const error = {
        body: { message: "Export failed" },
        message: "Export failed",
      };

      generateAuditReport.mockResolvedValue(mockReportData);
      exportReportAsPDF.mockRejectedValue(error);

      const element = await createComponent();
      await flushPromises();

      // Set form values
      const combobox = element.shadowRoot.querySelector("lightning-combobox");
      combobox.dispatchEvent(new CustomEvent("change", { detail: { value: "SOC2" } }));

      const startDateInput = findInputByLabel(element, "Start Date");
      const endDateInput = findInputByLabel(element, "End Date");

      startDateInput.dispatchEvent(new CustomEvent("change", { detail: { value: "2025-01-01" } }));
      endDateInput.dispatchEvent(new CustomEvent("change", { detail: { value: "2025-03-31" } }));

      await flushPromises();

      // Generate report first
      const generateButton = findButtonByLabel(element, "Generate Report");
      generateButton.click();

      await flushPromises();

      // Click Export PDF
      const exportButton = findButtonByLabel(element, "Export PDF");
      exportButton.click();

      await flushPromises();

      // Check for error message in DOM
      const errorDiv = element.shadowRoot.querySelector(".slds-text-color_error");
      expect(errorDiv).not.toBeNull();
      expect(errorDiv.textContent).toContain("Export failed");
    });
  });
});
