/**
 * HTTP Callout Mock for Claude API
 * Provides mock responses for Anthropic Claude API testing
 * @group Utilities
 * @author Elaro Team
 */
@IsTest
public inherited sharing class ElaroClaudeAPIMock implements HttpCalloutMock {
    
    // ═══════════════════════════════════════════════════════════════
    // RESPONSE TYPES
    // ═══════════════════════════════════════════════════════════════
    
    public enum ResponseType {
        SUCCESS,
        ERROR,
        RATE_LIMITED,
        TIMEOUT
    }
    
    private ResponseType responseType;
    private Integer statusCode;
    private String responseBody;
    
    // ═══════════════════════════════════════════════════════════════
    // CONSTRUCTORS
    // ═══════════════════════════════════════════════════════════════
    
    /**
     * Default constructor - returns successful response
 * @since v3.1.0 (Spring '26)
 */
    public ElaroClaudeAPIMock() {
        this.responseType = ResponseType.SUCCESS;
        configureResponse();
    }
    
    /**
     * Constructor with specific response type
     * @param responseType The type of response to return
     */
    public ElaroClaudeAPIMock(ResponseType responseType) {
        this.responseType = responseType;
        configureResponse();
    }
    
    /**
     * Constructor with custom status code and body
     * @param statusCode HTTP status code
     * @param responseBody JSON response body
     */
    public ElaroClaudeAPIMock(Integer statusCode, String responseBody) {
        this.statusCode = statusCode;
        this.responseBody = responseBody;
    }
    
    // ═══════════════════════════════════════════════════════════════
    // HTTP CALLOUT MOCK IMPLEMENTATION
    // ═══════════════════════════════════════════════════════════════
    
    /**
     * Implements HttpCalloutMock interface
     * @param req The HTTP request
     * @return Mock HTTP response
     */
    public HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(this.statusCode);
        res.setBody(this.responseBody);
        return res;
    }
    
    // ═══════════════════════════════════════════════════════════════
    // RESPONSE CONFIGURATION
    // ═══════════════════════════════════════════════════════════════
    
    private void configureResponse() {
        switch on this.responseType {
            when SUCCESS {
                this.statusCode = 200;
                this.responseBody = createSuccessResponse();
            }
            when ERROR {
                this.statusCode = 400;
                this.responseBody = createErrorResponse();
            }
            when RATE_LIMITED {
                this.statusCode = 429;
                this.responseBody = createRateLimitResponse();
            }
            when TIMEOUT {
                this.statusCode = 504;
                this.responseBody = createTimeoutResponse();
            }
        }
    }
    
    // ═══════════════════════════════════════════════════════════════
    // MOCK RESPONSE BUILDERS
    // ═══════════════════════════════════════════════════════════════
    
    /**
     * Create successful Claude API response
     * @return JSON string with compliance recommendation
     */
    private static String createSuccessResponse() {
        Map<String, Object> response = new Map<String, Object>{
            'id' => 'msg_' + String.valueOf(Datetime.now().getTime()),
            'type' => 'message',
            'role' => 'assistant',
            'content' => new List<Map<String, Object>>{
                new Map<String, Object>{
                    'type' => 'text',
                    'text' => JSON.serialize(new Map<String, Object>{
                        'recommendation' => 'Review user access patterns for potential unauthorized activity.',
                        'severity' => 'HIGH',
                        'relatedControls' => new List<String>{'164.312(b)', 'CC6.1'},
                        'suggestedActions' => new List<String>{
                            'Enable additional authentication factors',
                            'Review login patterns for anomalies'
                        },
                        'confidence' => 85
                    })
                }
            },
            'model' => 'claude-sonnet-4-20250514',
            'stop_reason' => 'end_turn',
            'usage' => new Map<String, Integer>{
                'input_tokens' => 150,
                'output_tokens' => 250
            }
        };
        return JSON.serialize(response);
    }
    
    /**
     * Create error response
     * @return JSON string with error details
     */
    private static String createErrorResponse() {
        Map<String, Object> error = new Map<String, Object>{
            'type' => 'error',
            'error' => new Map<String, String>{
                'type' => 'invalid_request_error',
                'message' => 'Invalid request format'
            }
        };
        return JSON.serialize(error);
    }
    
    /**
     * Create rate limit response
     * @return JSON string with rate limit error
     */
    private static String createRateLimitResponse() {
        Map<String, Object> error = new Map<String, Object>{
            'type' => 'error',
            'error' => new Map<String, String>{
                'type' => 'rate_limit_error',
                'message' => 'Rate limit exceeded. Please try again later.'
            }
        };
        return JSON.serialize(error);
    }
    
    /**
     * Create timeout response
     * @return JSON string with timeout error
     */
    private static String createTimeoutResponse() {
        Map<String, Object> error = new Map<String, Object>{
            'type' => 'error',
            'error' => new Map<String, String>{
                'type' => 'timeout_error',
                'message' => 'Request timed out. The model took too long to respond.'
            }
        };
        return JSON.serialize(error);
    }
    
    // ═══════════════════════════════════════════════════════════════
    // STATIC FACTORY METHODS
    // ═══════════════════════════════════════════════════════════════
    
    /**
     * Create mock for successful response
     * @return Configured mock instance
     */
    public static ElaroClaudeAPIMock success() {
        return new ElaroClaudeAPIMock(ResponseType.SUCCESS);
    }
    
    /**
     * Create mock for error response
     * @return Configured mock instance
     */
    public static ElaroClaudeAPIMock error() {
        return new ElaroClaudeAPIMock(ResponseType.ERROR);
    }
    
    /**
     * Create mock for rate limit response
     * @return Configured mock instance
     */
    public static ElaroClaudeAPIMock rateLimited() {
        return new ElaroClaudeAPIMock(ResponseType.RATE_LIMITED);
    }
    
    /**
     * Create mock for timeout response
     * @return Configured mock instance
     */
    public static ElaroClaudeAPIMock timeout() {
        return new ElaroClaudeAPIMock(ResponseType.TIMEOUT);
    }
}
