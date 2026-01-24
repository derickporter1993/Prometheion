/**
 * PrometheionHttpCalloutMock
 * Reusable HTTP callout mock for testing external integrations
 * 
 * Usage:
 *   Test.setMock(HttpCalloutMock.class, PrometheionHttpCalloutMock.success('{"result": "ok"}'));
 *   
 * @author Prometheion Test Infrastructure
 * @version 1.0
 */
@IsTest
public class PrometheionHttpCalloutMock implements HttpCalloutMock {
    private Integer statusCode;
    private String status;
    private String body;
    private Map<String, String> responseHeaders;
    
    /**
     * Constructor
     * @param statusCode HTTP status code (200, 401, 500, etc.)
     * @param status HTTP status text ('OK', 'Unauthorized', etc.)
     * @param body Response body (JSON, XML, or plain text)
     */
    public PrometheionHttpCalloutMock(Integer statusCode, String status, String body) {
        this.statusCode = statusCode;
        this.status = status;
        this.body = body;
        this.responseHeaders = new Map<String, String>{
            'Content-Type' => 'application/json'
        };
    }
    
    /**
     * Add custom response header
     * @param key Header name
     * @param value Header value
     * @return this (for method chaining)
     */
    public PrometheionHttpCalloutMock withHeader(String key, String value) {
        this.responseHeaders.put(key, value);
        return this;
    }
    
    /**
     * HttpCalloutMock interface implementation
     */
    public HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(this.statusCode);
        res.setStatus(this.status);
        res.setBody(this.body);
        
        for (String key : this.responseHeaders.keySet()) {
            res.setHeader(key, this.responseHeaders.get(key));
        }
        
        return res;
    }
    
    // ========== CONVENIENCE FACTORY METHODS ==========
    
    /**
     * Create a successful HTTP 200 response
     * @param body Response body
     * @return PrometheionHttpCalloutMock configured for success
     */
    public static PrometheionHttpCalloutMock success(String body) {
        return new PrometheionHttpCalloutMock(200, 'OK', body);
    }
    
    /**
     * Create a custom error response
     * @param code HTTP error code
     * @param message Error message
     * @return PrometheionHttpCalloutMock configured for error
     */
    public static PrometheionHttpCalloutMock error(Integer code, String message) {
        String errorBody = '{"error": "' + message + '"}';
        return new PrometheionHttpCalloutMock(code, 'Error', errorBody);
    }
    
    /**
     * Create HTTP 401 Unauthorized response
     * @return PrometheionHttpCalloutMock for authentication failure
     */
    public static PrometheionHttpCalloutMock unauthorized() {
        return new PrometheionHttpCalloutMock(401, 'Unauthorized', 
            '{"error": "Invalid credentials"}');
    }
    
    /**
     * Create HTTP 500 Server Error response
     * @return PrometheionHttpCalloutMock for server error
     */
    public static PrometheionHttpCalloutMock serverError() {
        return new PrometheionHttpCalloutMock(500, 'Internal Server Error',
            '{"error": "Server error occurred"}');
    }
    
    /**
     * Create HTTP 404 Not Found response
     * @return PrometheionHttpCalloutMock for not found
     */
    public static PrometheionHttpCalloutMock notFound() {
        return new PrometheionHttpCalloutMock(404, 'Not Found',
            '{"error": "Resource not found"}');
    }
    
    /**
     * Create HTTP 429 Rate Limit response
     * @return PrometheionHttpCalloutMock for rate limiting
     */
    public static PrometheionHttpCalloutMock rateLimited() {
        return new PrometheionHttpCalloutMock(429, 'Too Many Requests',
            '{"error": "Rate limit exceeded"}')
            .withHeader('Retry-After', '60');
    }
    
    // ========== SERVICE-SPECIFIC MOCK FACTORIES ==========
    
    /**
     * Create successful Claude AI API response
     * @param content Claude response content
     * @return PrometheionHttpCalloutMock for Claude API
     */
    public static PrometheionHttpCalloutMock claudeSuccess(String content) {
        String body = '{"content": [{"type": "text", "text": "' + content + '"}]}';
        return success(body);
    }
    
    /**
     * Create successful Slack webhook response
     * @return PrometheionHttpCalloutMock for Slack
     */
    public static PrometheionHttpCalloutMock slackSuccess() {
        return success('ok');
    }
    
    /**
     * Create successful PagerDuty API response
     * @param incidentId PagerDuty incident ID
     * @return PrometheionHttpCalloutMock for PagerDuty
     */
    public static PrometheionHttpCalloutMock pagerDutySuccess(String incidentId) {
        String body = '{"incident": {"id": "' + incidentId + '", "status": "triggered"}}';
        return success(body);
    }
    
    /**
     * Create successful ServiceNow API response
     * @param sysId ServiceNow system ID
     * @return PrometheionHttpCalloutMock for ServiceNow
     */
    public static PrometheionHttpCalloutMock serviceNowSuccess(String sysId) {
        String body = '{"result": {"sys_id": "' + sysId + '", "state": "1"}}';
        return success(body);
    }
}