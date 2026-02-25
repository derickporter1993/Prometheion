@IsTest
/**
 * HTTP callout mock for API limits endpoint testing.
 *
 * @author Elaro Team
 * @since v3.1.0 (Spring '26)
 * @group Utilities
 */
global inherited sharing class ApiLimitsCalloutMock implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type','application/json');
        res.setStatusCode(200);
        res.setBody('{"DailyApiRequests":{"Max":100000,"Remaining":75000}}');
        return res;
    }
}
