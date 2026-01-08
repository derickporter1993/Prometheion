import { LightningElement, track, wire } from 'lwc';
import askCopilot from '@salesforce/apex/PrometheionComplianceCopilot.askCopilot';
import getQuickCommands from '@salesforce/apex/PrometheionComplianceCopilot.getQuickCommands';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// Debounce delay in milliseconds
const DEBOUNCE_DELAY = 300;

export default class PrometheionCopilot extends LightningElement {
    @track query = '';
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
                isTrendDown: cmd.icon === 'utility:trending_down',
                isFlow: cmd.icon === 'utility:flow',
                isFile: cmd.icon === 'utility:file',
                isUser: cmd.icon === 'utility:user',
                isShield: cmd.icon === 'utility:shield',
                isWarning: cmd.icon === 'utility:warning'
            }));
        } else if (error) {
            const errorMessage = this.extractErrorMessage(error);
            this.showToast('Error', errorMessage, 'error');
            // Set default commands if wire fails
            this.quickCommands = this.getDefaultQuickCommands();
        }
    }

    getDefaultQuickCommands() {
        return [
            { command: 'Why did my score drop?', icon: 'utility:trending_down', isTrendDown: true },
            { command: 'Show me risky Flows', icon: 'utility:flow', isFlow: true },
            { command: 'Generate HIPAA evidence', icon: 'utility:file', isFile: true },
            { command: 'Who has elevated access?', icon: 'utility:user', isUser: true },
            { command: 'SOC2 compliance status', icon: 'utility:shield', isShield: true },
            { command: 'Show recent violations', icon: 'utility:warning', isWarning: true }
        ];
    }

    get showWelcome() {
        return !this.hasMessages && !this.isLoading;
    }

    get hasMessages() {
        return this.messages && this.messages.length > 0;
    }

    get messageList() {
        return this.messages.map((msg) => ({
            ...msg,
            isUser: msg.role === 'user',
            isAssistant: msg.role === 'assistant',
            containerClass: 'message-wrapper',
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
                riskClass: this.getRiskClass(ev.riskScore)
            }))
        }));
    }

    getRiskClass(riskScore) {
        if (!riskScore) return 'risk-badge risk-low';
        if (riskScore >= 7) return 'risk-badge risk-high';
        if (riskScore >= 5) return 'risk-badge risk-medium';
        return 'risk-badge risk-low';
    }

    handleQueryChange(event) {
        this.query = event.target.value;
    }

    handleKeyPress(event) {
        if (event.key === 'Enter' && !event.shiftKey) {
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
        this.query = '';
        this.addMessage('user', userMessage);
        this.isLoading = true;

        askCopilot({ query: userMessage })
            .then((response) => {
                this.isLoading = false;
                this.addMessage('assistant', response.answer, response);
                this.scrollToBottom();
            })
            .catch((error) => {
                this.isLoading = false;
                const errorMessage = this.extractErrorMessage(error);
                this.showToast('Error', errorMessage, 'error');
                this.addMessage(
                    'assistant',
                    'I encountered an error processing your request. Please try again.'
                );
            });
    }

    extractErrorMessage(error) {
        if (error.body && error.body.message) {
            return error.body.message;
        }
        if (error.message) {
            return error.message;
        }
        return 'An unexpected error occurred. Please try again.';
    }

    handleQuickCommand(event) {
        const command = event.currentTarget.dataset.command;
        this.query = command;
        this.handleSubmit();
    }

    addMessage(role, content, copilotResponse = null) {
        this.messages = [
            ...this.messages,
            {
                id: Date.now(),
                role: role,
                content: content,
                timestamp: new Date(),
                copilotResponse: copilotResponse
            }
        ];
    }

    scrollToBottom() {
        setTimeout(() => {
            const chatContainer = this.template.querySelector('.chat-container');
            if (chatContainer) {
                chatContainer.scrollTop = chatContainer.scrollHeight;
            }
        }, 100);
    }

    handleActionClick(event) {
        const actionType = event.currentTarget.dataset.actionType;

        if (actionType === 'AUTO_FIX') {
            this.showToast('Coming Soon', 'Auto-fix functionality will be available in the next release.', 'info');
        } else if (actionType === 'EXPORT') {
            this.showToast('Coming Soon', 'Export functionality will be available in the next release.', 'info');
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
                variant: variant
            })
        );
    }

    disconnectedCallback() {
        if (this._debounceTimer) {
            clearTimeout(this._debounceTimer);
        }
    }
}
