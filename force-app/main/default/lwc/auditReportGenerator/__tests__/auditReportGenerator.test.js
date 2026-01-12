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

  describe("Rendering", () => {
    it("renders the component", async () => {
      const element = await createComponent();
      await Promise.resolve();

      expect(element).not.toBeNull();
    });
  });

  describe("Form Input Handlers", () => {
    it("handles framework change", async () => {
      const element = await createComponent();
      await Promise.resolve();

      const event = new CustomEvent("change", {
        detail: { value: "SOC2" },
      });

      element.handleFrameworkChange(event);

      expect(element.selectedFramework).toBe("SOC2");
    });

    it("handles start date change", async () => {
      const element = await createComponent();
      await Promise.resolve();

      const event = new CustomEvent("change", {
        detail: { value: "2025-01-01" },
      });

      element.handleStartDateChange(event);

      expect(element.startDate).toBe("2025-01-01");
    });

    it("handles end date change", async () => {
      const element = await createComponent();
      await Promise.resolve();

      const event = new CustomEvent("change", {
        detail: { value: "2025-03-31" },
      });

      element.handleEndDateChange(event);

      expect(element.endDate).toBe("2025-03-31");
    });
  });

  describe("Report Generation", () => {
    it("generates report successfully", async () => {
      const mockReportData = {
        framework: "SOC2",
        startDate: "2025-01-01",
        endDate: "2025-03-31",
        sections: [],
      };

      generateAuditReport.mockResolvedValue(mockReportData);

      const element = await createComponent();
      await Promise.resolve();

      element.selectedFramework = "SOC2";
      element.startDate = "2025-01-01";
      element.endDate = "2025-03-31";

      element.handleGenerateReport();
      await Promise.resolve();
      await Promise.resolve();

      expect(generateAuditReport).toHaveBeenCalledWith({
        framework: "SOC2",
        startDate: "2025-01-01",
        endDate: "2025-03-31",
      });
      expect(element.reportData).toEqual(mockReportData);
      expect(element.loading).toBe(false);
    });

    it("validates required fields before generation", async () => {
      const element = await createComponent();
      await Promise.resolve();

      element.selectedFramework = "";
      element.startDate = "";
      element.endDate = "";

      element.handleGenerateReport();

      expect(element.error).toContain("Please select framework and date range");
      expect(generateAuditReport).not.toHaveBeenCalled();
    });

    it("handles generation error", async () => {
      const error = {
        body: { message: "Generation failed" },
        message: "Generation failed",
      };

      generateAuditReport.mockRejectedValue(error);

      const element = await createComponent();
      await Promise.resolve();

      element.selectedFramework = "SOC2";
      element.startDate = "2025-01-01";
      element.endDate = "2025-03-31";

      element.handleGenerateReport();
      await Promise.resolve();
      await Promise.resolve();

      expect(element.error).toContain("Generation failed");
      expect(element.loading).toBe(false);
    });
  });

  describe("PDF Export", () => {
    it("exports report as PDF successfully", async () => {
      const mockReportData = {
        framework: "SOC2",
        sections: [],
      };

      exportReportAsPDF.mockResolvedValue("069xx0000000001");

      const element = await createComponent();
      await Promise.resolve();

      element.reportData = mockReportData;

      // Mock window.open
      const openSpy = jest.spyOn(window, "open").mockImplementation(() => {});

      element.handleExportPDF();
      await Promise.resolve();
      await Promise.resolve();

      expect(exportReportAsPDF).toHaveBeenCalledWith({
        report: mockReportData,
      });
      expect(element.loading).toBe(false);

      openSpy.mockRestore();
    });

    it("validates report data exists before export", async () => {
      const element = await createComponent();
      await Promise.resolve();

      element.reportData = null;

      element.handleExportPDF();

      expect(element.error).toContain("Please generate a report first");
      expect(exportReportAsPDF).not.toHaveBeenCalled();
    });

    it("handles PDF export error", async () => {
      const mockReportData = {
        framework: "SOC2",
        sections: [],
      };

      const error = {
        body: { message: "Export failed" },
        message: "Export failed",
      };

      exportReportAsPDF.mockRejectedValue(error);

      const element = await createComponent();
      await Promise.resolve();

      element.reportData = mockReportData;

      element.handleExportPDF();
      await Promise.resolve();
      await Promise.resolve();

      expect(element.error).toContain("Export failed");
      expect(element.loading).toBe(false);
    });
  });
});
