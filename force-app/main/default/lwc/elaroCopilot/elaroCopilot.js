import { LightningElement, track, wire } from "lwc";
import askCopilot from "@salesforce/apex/ElaroComplianceCopilot.askCopilot";
import getQuickCommands from "@salesforce/apex/ElaroComplianceCopilot.getQuickCommands";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

// Debounce delay in milliseconds
const DEBOUNCE_DELAY = 300;

export default class ElaroCopilot extends LightningElement {
  @track query = "";
  @track messages = [];
  @track isLoading = false;
  @track quickCommands = [];

  // Debounce timer
  _debounceTimer;

  @wire(getQuickCommands)
  wiredQuickCommands({ error, data }) {
    if (data) {
      // Add icon type flags for template rendering
      this.quickCommands = data.map((cmd) => ({
        ...cmd,
        isTrendDown: cmd.icon === "utility:trending_down",
        isFlow: cmd.icon === "utility:flow",
        isFile: cmd.icon === "utility:file",
        isUser: cmd.icon === "utility:user",
        isShield: cmd.icon === "utility:shield",
        isWarning: cmd.icon === "utility:warning",
        ariaLabel: `Quick command: ${cmd.command}`,
      }));
    } else if (error) {
      // Set default commands if wire fails
      this.quickCommands = this.getDefaultQuickCommands();
    }
  }

  getDefaultQuickCommands() {
    const commands = [
      { command: "Why did my score drop?", icon: "utility:trending_down", isTrendDown: true },
      { command: "Show me risky Flows", icon: "utility:flow", isFlow: true },
      { command: "Generate HIPAA evidence", icon: "utility:file", isFile: true },
      { command: "Who has elevated access?", icon: "utility:user", isUser: true },
      { command: "SOC2 compliance status", icon: "utility:shield", isShield: true },
      { command: "Show recent violations", icon: "utility:warning", isWarning: true },
    ];
    return commands.map((cmd) => ({
      ...cmd,
      ariaLabel: `Quick command: ${cmd.command}`,
    }));
  }

  get showWelcome() {
    return !this.hasMessages && !this.isLoading;
  }

  get hasMessages() {
    return this.messages && this.messages.length > 0;
  }

  get messageList() {
    return this.messages.map((msg) => {
      const isUser = msg.role === "user";
      const isAssistant = msg.role === "assistant";
      return {
        ...msg,
        isUser,
        isAssistant,
        containerClass: "message-wrapper",
        ariaLabel: isUser ? `You said: ${msg.content}` : `Elaro responded: ${msg.content}`,
        hasEvidence:
          msg.copilotResponse &&
          msg.copilotResponse.evidence &&
          msg.copilotResponse.evidence.length > 0,
        hasActions:
          msg.copilotResponse &&
          msg.copilotResponse.actions &&
          msg.copilotResponse.actions.length > 0,
        evidenceList: msg.copilotResponse?.evidence?.map((ev) => ({
          ...ev,
          riskClass: this.getRiskClass(ev.riskScore),
          ariaLabel: `${ev.entityType}: ${ev.description}${ev.riskScore ? `, Risk score ${ev.riskScore} out of 10` : ""}`,
          entityTypeAriaLabel: `Entity type: ${ev.entityType}`,
          riskAriaLabel: ev.riskScore ? `Risk score: ${ev.riskScore} out of 10` : "",
          frameworkAriaLabel: ev.framework ? `Framework: ${ev.framework}` : "",
        })),
        copilotResponse: msg.copilotResponse
          ? {
              ...msg.copilotResponse,
              actions: msg.copilotResponse.actions?.map((action) => ({
                ...action,
                ariaLabel: action.canAutoFix
                  ? `${action.label} - Auto-fix available`
                  : action.label,
              })),
            }
          : null,
      };
    });
  }

  getRiskClass(riskScore) {
    if (!riskScore) return "risk-badge risk-low";
    if (riskScore >= 7) return "risk-badge risk-high";
    if (riskScore >= 5) return "risk-badge risk-medium";
    return "risk-badge risk-low";
  }

  handleQueryChange(event) {
    this.query = event.target.value;
  }

  handleKeyPress(event) {
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault();
      this.handleSubmitDebounced();
    }
  }

  handleSubmitDebounced() {
    if (this._debounceTimer) {
      clearTimeout(this._debounceTimer);
    }

    this._debounceTimer = setTimeout(() => {
      this.handleSubmit();
    }, DEBOUNCE_DELAY);
  }

  handleSubmit() {
    if (this.isLoading) {
      return;
    }

    if (!this.query || this.query.trim().length === 0) {
      return;
    }

    const userMessage = this.query.trim();
    this.query = "";
    this.addMessage("user", userMessage);
    this.isLoading = true;

    askCopilot({ query: userMessage })
      .then((response) => {
        this.isLoading = false;
        this.addMessage("assistant", response.answer, response);
        this.scrollToBottom();
      })
      .catch((error) => {
        this.isLoading = false;
        const errorMessage = this.extractErrorMessage(error);
        this.showToast("Error", errorMessage, "error");
        this.addMessage(
          "assistant",
          "I encountered an error processing your request. Please try again."
        );
      });
  }

  extractErrorMessage(error) {
    // Safely extract error message with null guards
    if (error?.body?.message) {
      return error.body.message;
    }
    if (error?.message) {
      return error.message;
    }
    if (typeof error === "string") {
      return error;
    }
    return "An unexpected error occurred. Please try again.";
  }

  handleQuickCommand(event) {
    const command = event.currentTarget.dataset.command;
    this.query = command;
    this.handleSubmit();
  }

  handleQuickCommandKeydown(event) {
    if (event.key === "Enter" || event.key === " ") {
      event.preventDefault();
      this.handleQuickCommand(event);
    }
  }

  addMessage(role, content, copilotResponse = null) {
    this.messages = [
      ...this.messages,
      {
        id: Date.now(),
        role: role,
        content: content,
        timestamp: new Date(),
        copilotResponse: copilotResponse,
      },
    ];
  }

  scrollToBottom() {
    setTimeout(() => {
      const chatContainer = this.template.querySelector(".chat-container");
      if (chatContainer) {
        chatContainer.scrollTop = chatContainer.scrollHeight;
      }
    }, 100);
  }

  handleActionClick(event) {
    const actionType = event.currentTarget.dataset.actionType;

    if (actionType === "AUTO_FIX") {
      this.showToast(
        "Coming Soon",
        "Auto-fix functionality will be available in the next release.",
        "info"
      );
    } else if (actionType === "EXPORT") {
      this.showToast(
        "Coming Soon",
        "Export functionality will be available in the next release.",
        "info"
      );
    }
  }

  clearChat() {
    this.messages = [];
  }

  showToast(title, message, variant) {
    this.dispatchEvent(
      new ShowToastEvent({
        title: title,
        message: message,
        variant: variant,
      })
    );
  }

  disconnectedCallback() {
    if (this._debounceTimer) {
      clearTimeout(this._debounceTimer);
    }
  }
}
