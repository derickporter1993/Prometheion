/**
 * HTTP Callout Mock for Claude API.
 * Provides mock responses for Anthropic Claude API testing.
 *
 * @group Utilities
 * @author Elaro Team
 */
@IsTest
public inherited sharing class ElaroClaudeAPIMock implements HttpCalloutMock {

    private static final String CONTENT_TYPE_HEADER = 'Content-Type';
    private static final String APPLICATION_JSON = 'application/json';
    private static final Integer STATUS_OK = 200;
    private static final Integer STATUS_BAD_REQUEST = 400;
    private static final Integer STATUS_TOO_MANY_REQUESTS = 429;
    private static final Integer STATUS_GATEWAY_TIMEOUT = 504;

    public enum ResponseType {
        SUCCESS,
        ERROR,
        RATE_LIMITED,
        TIMEOUT
    }

    private ResponseType responseType;
    private Integer statusCode;
    private String responseBody;

    /**
     * Default constructor that returns a successful response.
     */
    public ElaroClaudeAPIMock() {
        this(ResponseType.SUCCESS);
    }

    /**
     * Constructor with specific response type.
     *
     * @param responseType The type of response to return
     */
    public ElaroClaudeAPIMock(ResponseType responseType) {
        this.responseType = responseType;
        configureResponse();
    }

    /**
     * Constructor with custom status code and body.
     *
     * @param statusCode HTTP status code
     * @param responseBody JSON response body
     */
    public ElaroClaudeAPIMock(Integer statusCode, String responseBody) {
        this.statusCode = statusCode;
        this.responseBody = responseBody;
    }

    /**
     * Implements HttpCalloutMock interface.
     *
     * @param req The HTTP request
     * @return Mock HTTP response
     */
    public HttpResponse respond(HttpRequest req) {
        HttpResponse response = new HttpResponse();
        response.setHeader(CONTENT_TYPE_HEADER, APPLICATION_JSON);
        response.setStatusCode(this.statusCode);
        response.setBody(this.responseBody);
        return response;
    }

    private void configureResponse() {
        switch on this.responseType {
            when SUCCESS {
                this.statusCode = STATUS_OK;
                this.responseBody = createSuccessResponse();
            }
            when ERROR {
                this.statusCode = STATUS_BAD_REQUEST;
                this.responseBody = createErrorResponse('invalid_request_error', 'Invalid request format');
            }
            when RATE_LIMITED {
                this.statusCode = STATUS_TOO_MANY_REQUESTS;
                this.responseBody = createErrorResponse('rate_limit_error', 'Rate limit exceeded. Please try again later.');
            }
            when TIMEOUT {
                this.statusCode = STATUS_GATEWAY_TIMEOUT;
                this.responseBody = createErrorResponse('timeout_error', 'Request timed out. The model took too long to respond.');
            }
        }
    }

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

    private static String createErrorResponse(String errorType, String message) {
        Map<String, Object> error = new Map<String, Object>{
            'type' => 'error',
            'error' => new Map<String, String>{
                'type' => errorType,
                'message' => message
            }
        };
        return JSON.serialize(error);
    }

    public static ElaroClaudeAPIMock success() {
        return new ElaroClaudeAPIMock(ResponseType.SUCCESS);
    }

    public static ElaroClaudeAPIMock error() {
        return new ElaroClaudeAPIMock(ResponseType.ERROR);
    }

    public static ElaroClaudeAPIMock rateLimited() {
        return new ElaroClaudeAPIMock(ResponseType.RATE_LIMITED);
    }

    public static ElaroClaudeAPIMock timeout() {
        return new ElaroClaudeAPIMock(ResponseType.TIMEOUT);
    }
}
