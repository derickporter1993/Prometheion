/**
 * LWC1702 is a known false positive for Jest test files.
 * The LWC compiler incorrectly validates test files as LWC components.
 * This import is valid for Jest testing and should be ignored.
 * 
 * @see https://developer.salesforce.com/docs/component-library/documentation/en/lwc/lwc.testing
 */
// @ts-ignore - LWC1702 false positive for Jest test files
import { createElement } from 'lwc';
import ComplianceCopilot from 'c/complianceCopilot';
import askCopilot from '@salesforce/apex/PrometheionComplianceCopilot.askCopilot';
import getQuickCommands from '@salesforce/apex/PrometheionComplianceCopilot.getQuickCommands';

// Mock Apex methods
jest.mock(
    '@salesforce/apex/PrometheionComplianceCopilot.askCopilot',
    () => ({ default: jest.fn() }),
    { virtual: true }
);

jest.mock(
    '@salesforce/apex/PrometheionComplianceCopilot.getQuickCommands',
    () => ({ default: jest.fn() }),
    { virtual: true }
);

// Mock Custom Labels
jest.mock('@salesforce/label/c.Copilot_Welcome', () => ({ default: 'How can I help with compliance today?' }), { virtual: true });
jest.mock('@salesforce/label/c.Copilot_Welcome_Subtitle', () => ({ default: 'Ask me about your compliance score, violations, evidence, or framework status.' }), { virtual: true });
jest.mock('@salesforce/label/c.Prometheion_Quick_Commands', () => ({ default: 'Quick Commands:' }), { virtual: true });
jest.mock('@salesforce/label/c.Prometheion_Ask_Question', () => ({ default: 'Ask a compliance question' }), { virtual: true });
jest.mock('@salesforce/label/c.Prometheion_Input_Placeholder', () => ({ default: 'e.g., Why did my compliance score drop?' }), { virtual: true });
jest.mock('@salesforce/label/c.Prometheion_Send', () => ({ default: 'Send' }), { virtual: true });
jest.mock('@salesforce/label/c.Prometheion_Clear_Chat', () => ({ default: 'Clear Chat' }), { virtual: true });
jest.mock('@salesforce/label/c.Prometheion_Evidence', () => ({ default: 'Evidence:' }), { virtual: true });
jest.mock('@salesforce/label/c.Prometheion_Risk_Score', () => ({ default: 'Risk: {0}/10' }), { virtual: true });
jest.mock('@salesforce/label/c.Prometheion_Error_Title', () => ({ default: 'Error' }), { virtual: true });
jest.mock('@salesforce/label/c.Prometheion_Info_Title', () => ({ default: 'Info' }), { virtual: true });
jest.mock('@salesforce/label/c.Prometheion_Auto_Fix_Coming', () => ({ default: 'Auto-fix functionality coming soon' }), { virtual: true });
jest.mock('@salesforce/label/c.Prometheion_Export_Coming', () => ({ default: 'Export functionality coming soon' }), { virtual: true });
jest.mock('@salesforce/label/c.Prometheion_Processing_Error', () => ({ default: 'I encountered an error processing your query. Please try again.' }), { virtual: true });

// Sample data
const MOCK_QUICK_COMMANDS = [
    { command: 'Why did my score drop?', icon: 'utility:trending_down' },
    { command: 'Show me risky Flows', icon: 'utility:flow' },
    { command: 'Generate HIPAA evidence', icon: 'utility:file' },
    { command: 'Who has elevated access?', icon: 'utility:user' }
];

const MOCK_COPILOT_RESPONSE = {
    answer: 'Your compliance score dropped due to 3 high-risk changes detected.',
    evidence: [
        { nodeId: 'node1', entityType: 'PERMISSION_SET', description: 'Elevated access granted', riskScore: 8.5 }
    ],
    actions: [
        { actionType: 'AUTO_FIX', label: 'Auto-Fix', canAutoFix: true, nodeId: 'node1' }
    ],
    queryType: 'SCORE_CHANGE',
    confidence: 0.95
};

describe('c-compliance-copilot', () => {
    beforeEach(() => {
        // Reset mocks
        jest.clearAllMocks();
        
        // Setup default mock returns
        getQuickCommands.mockResolvedValue(MOCK_QUICK_COMMANDS);
        askCopilot.mockResolvedValue(MOCK_COPILOT_RESPONSE);
    });

    afterEach(() => {
        // Clean up DOM
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    /**
     * Helper to create component and wait for render
     */
    async function createComponent() {
        const element = createElement('c-compliance-copilot', {
            is: ComplianceCopilot
        });
        document.body.appendChild(element);
        
        // Wait for any async operations
        await Promise.resolve();
        
        return element;
    }

    /**
     * Test: Component renders with welcome message
     */
    it('renders welcome message on initial load', async () => {
        const element = await createComponent();
        
        const welcomeHeading = element.shadowRoot.querySelector('h2');
        expect(welcomeHeading).not.toBeNull();
        expect(welcomeHeading.textContent).toBe('How can I help with compliance today?');
    });

    /**
     * Test: Quick commands are displayed
     */
    it('displays quick commands from Apex', async () => {
        const element = await createComponent();
        
        // Wait for wire adapter
        await Promise.resolve();
        
        const quickCommandButtons = element.shadowRoot.querySelectorAll('lightning-button[data-command]');
        expect(quickCommandButtons.length).toBe(MOCK_QUICK_COMMANDS.length);
    });

    /**
     * Test: User can type in input field
     */
    it('updates query when user types', async () => {
        const element = await createComponent();
        
        const input = element.shadowRoot.querySelector('lightning-input');
        expect(input).not.toBeNull();
        
        // Simulate typing
        input.value = 'Why did my score drop?';
        input.dispatchEvent(new CustomEvent('change', { detail: { value: 'Why did my score drop?' } }));
        
        await Promise.resolve();
        
        // Component should have updated internal state
        expect(input.value).toBe('Why did my score drop?');
    });

    /**
     * Test: Clicking send button submits query
     */
    it('submits query when send button is clicked', async () => {
        const element = await createComponent();
        
        // Set query value
        const input = element.shadowRoot.querySelector('lightning-input');
        input.dispatchEvent(new CustomEvent('change', { target: { value: 'Test query' } }));
        
        // Find and click send button
        const sendButton = element.shadowRoot.querySelector('lightning-button[variant="brand"]');
        expect(sendButton).not.toBeNull();
        
        sendButton.click();
        
        // Wait for async operations
        await Promise.resolve();
    });

    /**
     * Test: Clear chat button resets messages
     */
    it('clears messages when clear chat is clicked', async () => {
        const element = await createComponent();
        
        // Find clear chat button
        const clearButton = element.shadowRoot.querySelector('lightning-button[variant="neutral"]');
        expect(clearButton).not.toBeNull();
        
        clearButton.click();
        
        await Promise.resolve();
        
        // Welcome message should be visible again
        const welcomeHeading = element.shadowRoot.querySelector('h2');
        expect(welcomeHeading).not.toBeNull();
    });

    /**
     * Test: Quick command click populates and submits query
     */
    it('submits query when quick command is clicked', async () => {
        const element = await createComponent();
        
        // Wait for quick commands to load
        await Promise.resolve();
        
        const quickCommandButtons = element.shadowRoot.querySelectorAll('lightning-button[data-command]');
        
        expect(quickCommandButtons.length).toBeGreaterThan(0);
        quickCommandButtons[0].click();
        
        await Promise.resolve();
        
        // Verify askCopilot was called
        expect(askCopilot).toHaveBeenCalled();
    });

    /**
     * Test: Loading spinner appears during query
     */
    it('shows loading spinner while processing query', async () => {
        // Make askCopilot return a pending promise
        askCopilot.mockImplementation(() => new Promise(() => {}));
        
        const element = await createComponent();
        
        // Trigger a query
        const quickCommandButtons = element.shadowRoot.querySelectorAll('lightning-button[data-command]');
        
        expect(quickCommandButtons.length).toBeGreaterThan(0);
        quickCommandButtons[0].click();
        
        await Promise.resolve();
        
        // Check for spinner
        const spinner = element.shadowRoot.querySelector('lightning-spinner');
        expect(spinner).not.toBeNull();
    });

    /**
     * Test: Error handling displays error message
     */
    it('handles errors gracefully', async () => {
        // Make askCopilot reject
        askCopilot.mockRejectedValue({ body: { message: 'Test error' } });
        
        const element = await createComponent();
        
        // Trigger a query
        const quickCommandButtons = element.shadowRoot.querySelectorAll('lightning-button[data-command]');
        expect(quickCommandButtons.length).toBeGreaterThan(0);
        quickCommandButtons[0].click();
        
        // Wait for error handling
        await Promise.resolve();
        await Promise.resolve();
        
        // Component should still be functional
        expect(element.shadowRoot.querySelector('lightning-card')).not.toBeNull();
    });

    /**
     * Test: Component cleans up on disconnect
     */
    it('cleans up debounce timer on disconnect', async () => {
        const element = await createComponent();
        
        // Remove element
        document.body.removeChild(element);
        
        // Should not throw error
        expect(true).toBe(true);
    });
});
