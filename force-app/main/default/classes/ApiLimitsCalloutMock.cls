@IsTest
global class ApiLimitsCalloutMock implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type','application/json');
        res.setStatusCode(200);
        res.setBody('{"DailyApiRequests":{"Max":100000,"Remaining":75000}}');
        return res;
    }
}
