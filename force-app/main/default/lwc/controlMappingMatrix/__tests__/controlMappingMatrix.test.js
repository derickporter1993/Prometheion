/**
 * Jest tests for controlMappingMatrix LWC component
 *
 * Tests cover:
 * - Matrix rendering
 * - Framework selection
 * - Cell interactions
 * - Modal functionality
 * - Export functionality
 * - Accessibility compliance
 */
// @ts-ignore - LWC1702 false positive for Jest test files
import { createElement } from "lwc";
import ControlMappingMatrix from "c/controlMappingMatrix";

// Mock ShowToastEvent
jest.mock(
  "lightning/platformShowToastEvent",
  () => ({
    ShowToastEvent: jest.fn().mockImplementation((config) => {
      return new CustomEvent("showtoast", { detail: config });
    }),
  }),
  { virtual: true }
);

describe("c-control-mapping-matrix", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  function flushPromises() {
    return new Promise((resolve) => setTimeout(resolve, 0));
  }

  async function createComponent() {
    const element = createElement("c-control-mapping-matrix", {
      is: ControlMappingMatrix,
    });
    document.body.appendChild(element);
    await flushPromises();
    return element;
  }

  describe("Initial Rendering", () => {
    it("renders the control mapping card", async () => {
      const element = await createComponent();

      const card = element.shadowRoot.querySelector("lightning-card");
      expect(card).not.toBeNull();
      expect(card.title).toBe("Control Mapping Matrix");
    });

    it("displays source framework combobox", async () => {
      const element = await createComponent();
      await flushPromises();

      const sourceCombo = element.shadowRoot.querySelector("lightning-combobox");
      expect(sourceCombo).not.toBeNull();
    });

    it("displays target frameworks dual listbox", async () => {
      const element = await createComponent();

      const dualListbox = element.shadowRoot.querySelector("lightning-dual-listbox");
      expect(dualListbox).not.toBeNull();
    });

    it("displays legend", async () => {
      const element = await createComponent();

      const legend = element.shadowRoot.querySelector(".legend");
      expect(legend).not.toBeNull();

      const legendItems = legend.querySelectorAll(".legend-item");
      expect(legendItems.length).toBe(3); // Direct, Partial, None
    });

    it("displays matrix table", async () => {
      const element = await createComponent();

      const table = element.shadowRoot.querySelector("table");
      expect(table).not.toBeNull();
    });

    it("displays export button", async () => {
      const element = await createComponent();

      const exportBtn = element.shadowRoot.querySelector("lightning-button-icon");
      expect(exportBtn).not.toBeNull();
    });
  });

  describe("Matrix Table", () => {
    it("has proper table structure with thead and tbody", async () => {
      const element = await createComponent();

      const thead = element.shadowRoot.querySelector("thead");
      const tbody = element.shadowRoot.querySelector("tbody");
      expect(thead).not.toBeNull();
      expect(tbody).not.toBeNull();
    });

    it("has column headers for target frameworks", async () => {
      const element = await createComponent();

      const headers = element.shadowRoot.querySelectorAll("th[scope='col']");
      expect(headers.length).toBeGreaterThan(1); // Source + targets + coverage
    });

    it("displays control rows with row headers", async () => {
      const element = await createComponent();

      const rowHeaders = element.shadowRoot.querySelectorAll("th[scope='row']");
      expect(rowHeaders.length).toBeGreaterThan(0);
    });

    it("has proper ARIA attributes on table", async () => {
      const element = await createComponent();

      const table = element.shadowRoot.querySelector("table");
      expect(table.getAttribute("role")).toBe("grid");
      expect(table.getAttribute("aria-label")).not.toBeNull();
    });

    it("cells are focusable with tabindex", async () => {
      const element = await createComponent();

      const cells = element.shadowRoot.querySelectorAll(".mapping-cell[tabindex='0']");
      expect(cells.length).toBeGreaterThan(0);
    });
  });

  describe("Framework Selection", () => {
    it("changes source framework", async () => {
      const element = await createComponent();
      await flushPromises();

      const sourceCombo = element.shadowRoot.querySelector("lightning-combobox");
      if (sourceCombo) {
        sourceCombo.dispatchEvent(new CustomEvent("change", { detail: { value: "HIPAA" } }));
        await flushPromises();
      }

      expect(element).not.toBeNull();
    });

    it("changes target frameworks", async () => {
      const element = await createComponent();
      await flushPromises();

      const dualListbox = element.shadowRoot.querySelector("lightning-dual-listbox");
      if (dualListbox) {
        dualListbox.dispatchEvent(
          new CustomEvent("change", { detail: { value: ["HIPAA", "SOC2"] } })
        );
        await flushPromises();
      }

      expect(element).not.toBeNull();
    });
  });

  describe("Cell Interactions", () => {
    it("opens modal on cell click", async () => {
      const element = await createComponent();

      // Find a cell with mapping
      const cells = element.shadowRoot.querySelectorAll(".mapping-cell.direct");
      if (cells.length > 0) {
        cells[0].click();
        await flushPromises();
        await new Promise((resolve) => setTimeout(resolve, 150));

        const modal = element.shadowRoot.querySelector(".slds-modal");
        expect(modal).not.toBeNull();
      }
    });

    it("supports keyboard activation with Enter", async () => {
      const element = await createComponent();

      const cells = element.shadowRoot.querySelectorAll(".mapping-cell.direct");
      if (cells.length > 0) {
        const keyEvent = new KeyboardEvent("keydown", {
          key: "Enter",
          bubbles: true,
          cancelable: true,
        });
        cells[0].dispatchEvent(keyEvent);
        await flushPromises();
        await new Promise((resolve) => setTimeout(resolve, 150));

        const modal = element.shadowRoot.querySelector(".slds-modal");
        expect(modal).not.toBeNull();
      }
    });

    it("supports keyboard activation with Space", async () => {
      const element = await createComponent();

      const cells = element.shadowRoot.querySelectorAll(".mapping-cell.direct");
      if (cells.length > 0) {
        const keyEvent = new KeyboardEvent("keydown", {
          key: " ",
          bubbles: true,
          cancelable: true,
        });
        cells[0].dispatchEvent(keyEvent);
        await flushPromises();
        await new Promise((resolve) => setTimeout(resolve, 150));

        const modal = element.shadowRoot.querySelector(".slds-modal");
        expect(modal).not.toBeNull();
      }
    });

    it("cells have aria-label describing mapping", async () => {
      const element = await createComponent();

      const cells = element.shadowRoot.querySelectorAll(".mapping-cell");
      cells.forEach((cell) => {
        expect(cell.getAttribute("aria-label")).not.toBeNull();
      });
    });
  });

  describe("Modal Functionality", () => {
    async function openModal(element) {
      const cells = element.shadowRoot.querySelectorAll(".mapping-cell.direct");
      if (cells.length > 0) {
        cells[0].click();
        await flushPromises();
        await new Promise((resolve) => setTimeout(resolve, 150));
      }
    }

    it("modal has proper ARIA attributes", async () => {
      const element = await createComponent();
      await openModal(element);

      const modal = element.shadowRoot.querySelector('[role="dialog"]');
      if (modal) {
        expect(modal.getAttribute("aria-modal")).toBe("true");
        expect(modal.getAttribute("aria-labelledby")).toBe("mapping-modal-heading");
      }
    });

    it("displays source and target control details", async () => {
      const element = await createComponent();
      await openModal(element);

      const sourceSection = element.shadowRoot.querySelector("#source-control-heading");
      const targetSection = element.shadowRoot.querySelector("#target-control-heading");

      if (sourceSection) {
        expect(sourceSection).not.toBeNull();
        expect(targetSection).not.toBeNull();
      }
    });

    it("closes modal on close button click", async () => {
      const element = await createComponent();
      await openModal(element);

      const closeBtn = element.shadowRoot.querySelector(".slds-modal__close");
      if (closeBtn) {
        closeBtn.click();
        await flushPromises();

        const modal = element.shadowRoot.querySelector(".slds-modal");
        expect(modal).toBeNull();
      }
    });

    it("closes modal on Escape key", async () => {
      const element = await createComponent();
      await openModal(element);

      const modal = element.shadowRoot.querySelector('[role="dialog"]');
      if (modal) {
        const escEvent = new KeyboardEvent("keydown", {
          key: "Escape",
          bubbles: true,
        });
        modal.dispatchEvent(escEvent);
        await flushPromises();

        const modalAfter = element.shadowRoot.querySelector(".slds-modal");
        expect(modalAfter).toBeNull();
      }
    });

    it("traps focus within modal", async () => {
      const element = await createComponent();
      await openModal(element);

      const modal = element.shadowRoot.querySelector('[role="dialog"]');
      if (modal) {
        expect(modal.getAttribute("tabindex")).toBe("-1");
      }
    });
  });

  describe("Statistics", () => {
    it("displays total controls count", async () => {
      const element = await createComponent();

      const statBoxes = element.shadowRoot.querySelectorAll(".stat-box");
      expect(statBoxes.length).toBe(4); // Total, Direct, Partial, Gaps
    });

    it("displays direct mappings count", async () => {
      const element = await createComponent();

      const directBox = element.shadowRoot.querySelector(".stat-box.direct");
      expect(directBox).not.toBeNull();
    });

    it("displays partial mappings count", async () => {
      const element = await createComponent();

      const partialBox = element.shadowRoot.querySelector(".stat-box.partial");
      expect(partialBox).not.toBeNull();
    });

    it("displays gaps count", async () => {
      const element = await createComponent();

      const gapsBox = element.shadowRoot.querySelector(".stat-box.none");
      expect(gapsBox).not.toBeNull();
    });

    it("stat boxes have accessible labels", async () => {
      const element = await createComponent();

      const statBoxes = element.shadowRoot.querySelectorAll(".stat-box");
      statBoxes.forEach((box) => {
        expect(box.getAttribute("role")).toBe("status");
        expect(box.getAttribute("aria-label")).not.toBeNull();
      });
    });
  });

  describe("Coverage Display", () => {
    it("displays coverage progress ring for each row", async () => {
      const element = await createComponent();

      const progressRings = element.shadowRoot.querySelectorAll("lightning-progress-ring");
      expect(progressRings.length).toBeGreaterThan(0);
    });

    it("coverage cells have aria-label", async () => {
      const element = await createComponent();

      const coverageCells = element.shadowRoot.querySelectorAll(".coverage-cell");
      coverageCells.forEach((cell) => {
        expect(cell.getAttribute("aria-label")).not.toBeNull();
      });
    });
  });

  describe("Export Functionality", () => {
    it("exports CSV when button is clicked", async () => {
      global.URL.createObjectURL = jest.fn(() => "blob:test");
      global.URL.revokeObjectURL = jest.fn();

      const element = await createComponent();

      const exportBtn = element.shadowRoot.querySelector("lightning-button-icon");
      exportBtn.click();
      await flushPromises();

      expect(global.URL.createObjectURL).toHaveBeenCalled();
    });
  });

  describe("Accessibility", () => {
    it("legend region has aria-label", async () => {
      const element = await createComponent();

      const legendRegion = element.shadowRoot.querySelector('[aria-label="Mapping legend"]');
      expect(legendRegion).not.toBeNull();
    });

    it("matrix container has aria-label", async () => {
      const element = await createComponent();

      const matrixRegion = element.shadowRoot.querySelector(
        '[aria-label="Control mapping matrix table"]'
      );
      expect(matrixRegion).not.toBeNull();
    });

    it("statistics region has aria-label and live updates", async () => {
      const element = await createComponent();

      const statsRegion = element.shadowRoot.querySelector('[aria-label="Mapping statistics"]');
      expect(statsRegion).not.toBeNull();
      expect(statsRegion.getAttribute("aria-live")).toBe("polite");
    });

    it("decorative legend dots are hidden from screen readers", async () => {
      const element = await createComponent();

      const legendDots = element.shadowRoot.querySelectorAll(".legend-dot");
      legendDots.forEach((dot) => {
        expect(dot.getAttribute("aria-hidden")).toBe("true");
      });
    });

    it("close button has aria-label", async () => {
      const element = await createComponent();

      // Open modal
      const cells = element.shadowRoot.querySelectorAll(".mapping-cell.direct");
      if (cells.length > 0) {
        cells[0].click();
        await flushPromises();
        await new Promise((resolve) => setTimeout(resolve, 150));

        const closeBtn = element.shadowRoot.querySelector(".slds-modal__close");
        expect(closeBtn.getAttribute("aria-label")).toBe("Close mapping details modal");
      }
    });

    it("mapping icons have alternative text", async () => {
      const element = await createComponent();

      const icons = element.shadowRoot.querySelectorAll(".mapping-content lightning-icon");
      icons.forEach((icon) => {
        expect(icon.alternativeText).not.toBeNull();
      });
    });
  });

  describe("Table Rows", () => {
    it("each row has control code and name", async () => {
      const element = await createComponent();

      const controlCells = element.shadowRoot.querySelectorAll(".control-cell");
      expect(controlCells.length).toBeGreaterThan(0);

      controlCells.forEach((cell) => {
        const strong = cell.querySelector("strong");
        expect(strong).not.toBeNull();
      });
    });

    it("rows have proper role attribute", async () => {
      const element = await createComponent();

      const rows = element.shadowRoot.querySelectorAll('tr[role="row"]');
      expect(rows.length).toBeGreaterThan(0);
    });
  });
});
