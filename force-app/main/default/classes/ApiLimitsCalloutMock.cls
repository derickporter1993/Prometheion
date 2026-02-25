/**
 * HTTP callout mock for API limits endpoint testing.
 *
 * @author Elaro Team
 * @since v3.1.0 (Spring '26)
 * @group Utilities
 */
@IsTest
global inherited sharing class ApiLimitsCalloutMock implements HttpCalloutMock {

    private static final String CONTENT_TYPE_HEADER = 'Content-Type';
    private static final String APPLICATION_JSON = 'application/json';
    private static final Integer HTTP_STATUS_OK = 200;
    private static final String API_LIMITS_RESPONSE =
        '{"DailyApiRequests":{"Max":100000,"Remaining":75000}}';

    global HttpResponse respond(HttpRequest req) {
        HttpResponse response = new HttpResponse();
        response.setHeader(CONTENT_TYPE_HEADER, APPLICATION_JSON);
        response.setStatusCode(HTTP_STATUS_OK);
        response.setBody(API_LIMITS_RESPONSE);
        return response;
    }
}
