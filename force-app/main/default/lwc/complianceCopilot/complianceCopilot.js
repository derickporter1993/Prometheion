import { LightningElement, track, wire } from 'lwc';
import askCopilot from '@salesforce/apex/PrometheionComplianceCopilot.askCopilot';
import getQuickCommands from '@salesforce/apex/PrometheionComplianceCopilot.getQuickCommands';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// Custom Labels
import WELCOME from '@salesforce/label/c.Copilot_Welcome';
import WELCOME_SUBTITLE from '@salesforce/label/c.Copilot_Welcome_Subtitle';
import QUICK_COMMANDS from '@salesforce/label/c.Prometheion_Quick_Commands';
import ASK_QUESTION from '@salesforce/label/c.Prometheion_Ask_Question';
import INPUT_PLACEHOLDER from '@salesforce/label/c.Prometheion_Input_Placeholder';
import SEND from '@salesforce/label/c.Prometheion_Send';
import CLEAR_CHAT from '@salesforce/label/c.Prometheion_Clear_Chat';
import EVIDENCE from '@salesforce/label/c.Prometheion_Evidence';
import RISK_SCORE from '@salesforce/label/c.Prometheion_Risk_Score';
import ERROR_TITLE from '@salesforce/label/c.Prometheion_Error_Title';
import INFO_TITLE from '@salesforce/label/c.Prometheion_Info_Title';
import AUTO_FIX_COMING from '@salesforce/label/c.Prometheion_Auto_Fix_Coming';
import EXPORT_COMING from '@salesforce/label/c.Prometheion_Export_Coming';
import PROCESSING_ERROR from '@salesforce/label/c.Prometheion_Processing_Error';

// Debounce delay in milliseconds
const DEBOUNCE_DELAY = 300;

export default class ComplianceCopilot extends LightningElement {
    @track query = '';
    @track messages = [];
    @track isLoading = false;
    @track quickCommands = [];
    @track showQuickCommands = true;

    // Expose labels to template
    labels = {
        welcome: WELCOME,
        welcomeSubtitle: WELCOME_SUBTITLE,
        quickCommands: QUICK_COMMANDS,
        askQuestion: ASK_QUESTION,
        inputPlaceholder: INPUT_PLACEHOLDER,
        send: SEND,
        clearChat: CLEAR_CHAT,
        evidence: EVIDENCE
    };

    // Debounce timer
    _debounceTimer;

    @wire(getQuickCommands)
    wiredQuickCommands({ error, data }) {
        if (data) {
            this.quickCommands = data;
        } else if (error) {
            console.error('Error loading quick commands:', error);
        }
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

    /**
     * Debounced submit to prevent rapid-fire requests
     */
    handleSubmitDebounced() {
        // Clear any existing timer
        if (this._debounceTimer) {
            clearTimeout(this._debounceTimer);
        }

        // Set new timer
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this._debounceTimer = setTimeout(() => {
            this.handleSubmit();
        }, DEBOUNCE_DELAY);
    }

    handleSubmit() {
        // Prevent submission if already loading or empty query
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
        this.showQuickCommands = false;

        askCopilot({ query: userMessage })
            .then((response) => {
                this.isLoading = false;
                this.addMessage('assistant', response.answer, response);
            })
            .catch((error) => {
                this.isLoading = false;
                const errorMessage = this.extractErrorMessage(error);
                this.showToast(ERROR_TITLE, errorMessage, 'error');
                this.addMessage('assistant', PROCESSING_ERROR);
            });
    }

    /**
     * Extract user-friendly error message from error object
     */
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

        // Scroll to bottom after message is added
        this.scrollToBottom();
    }

    /**
     * Scroll chat container to bottom
     */
    scrollToBottom() {
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        setTimeout(() => {
            const chatContainer = this.template.querySelector('.chat-container');
            if (chatContainer) {
                chatContainer.scrollTop = chatContainer.scrollHeight;
            }
        }, 100);
    }

    handleActionClick(event) {
        const actionType = event.currentTarget.dataset.actionType;
        // const nodeId = event.currentTarget.dataset.nodeId; // Available for future use

        if (actionType === 'AUTO_FIX') {
            this.showToast(INFO_TITLE, AUTO_FIX_COMING, 'info');
        } else if (actionType === 'EXPORT') {
            this.showToast(INFO_TITLE, EXPORT_COMING, 'info');
        }
    }

    clearChat() {
        this.messages = [];
        this.showQuickCommands = true;
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

    get hasMessages() {
        return this.messages && this.messages.length > 0;
    }

    get messageList() {
        return this.messages.map((msg) => ({
            ...msg,
            isUser: msg.role === 'user',
            isAssistant: msg.role === 'assistant',
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
                formattedRiskScore: ev.riskScore
                    ? RISK_SCORE.replace('{0}', String(ev.riskScore))
                    : null
            }))
        }));
    }

    /**
     * Cleanup on disconnect
     */
    disconnectedCallback() {
        if (this._debounceTimer) {
            clearTimeout(this._debounceTimer);
        }
    }
}
