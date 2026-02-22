# Winter ’26 / Spring ’26 Code Review Findings

## Finding 1 — BUG — Missing explicit sharing declaration (auto-fail)
**File:** `./force-app/main/default/classes/ElaroClaudeAPIMock.cls`

**Quoted code:**
```apex
@isTest
public class ElaroClaudeAPIMock implements HttpCalloutMock {
```

**Why this is a BUG:** Concrete Apex classes must explicitly declare `with sharing`, `without sharing`, or `inherited sharing` per the review standard. This class omits the sharing model.

**Complete corrected code block:**
```apex
@IsTest
public inherited sharing class ElaroClaudeAPIMock implements HttpCalloutMock {

    public enum ResponseType {
        SUCCESS,
        ERROR,
        RATE_LIMITED,
        TIMEOUT
    }

    private ResponseType responseType;
    private Integer statusCode;
    private String responseBody;

    public ElaroClaudeAPIMock() {
        this.responseType = ResponseType.SUCCESS;
        configureResponse();
    }

    public ElaroClaudeAPIMock(ResponseType responseType) {
        this.responseType = responseType;
        configureResponse();
    }

    public ElaroClaudeAPIMock(Integer statusCode, String responseBody) {
        this.statusCode = statusCode;
        this.responseBody = responseBody;
    }

    public HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(this.statusCode);
        res.setBody(this.responseBody);
        return res;
    }

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
```

## Finding 2 — BUG — Missing explicit sharing declaration (auto-fail)
**File:** `./force-app/main/default/classes/ApiLimitsCalloutMock.cls`

**Quoted code:**
```apex
global class ApiLimitsCalloutMock implements HttpCalloutMock {
```

**Why this is a BUG:** Concrete Apex class has no explicit sharing declaration.

**Complete corrected code block:**
```apex
@IsTest
global inherited sharing class ApiLimitsCalloutMock implements HttpCalloutMock {
    global HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type','application/json');
        res.setStatusCode(200);
        res.setBody('{"DailyApiRequests":{"Max":100000,"Remaining":75000}}');
        return res;
    }
}
```

## Finding 3 — SUGGESTION — Legacy `@future` async pattern should be migrated to Queueable
**File:** `./force-app/main/default/classes/MultiOrgManager.cls`

**Quoted code:**
```apex
@future(callout=true)
public static void syncPolicies(List<String> policyIds) {
```

**Why this is a SUGGESTION:** Works, but Spring ’26 best practice is Queueable + optional Finalizer for retries/monitoring.

**Complete corrected code block:**
```apex
@AuraEnabled
public static Id enqueuePolicySync(List<String> policyIds) {
    return System.enqueueJob(new MultiOrgManagerPolicySyncQueueable(policyIds));
}

public inherited sharing class MultiOrgManagerPolicySyncQueueable implements Queueable, Database.AllowsCallouts {
    private final List<String> policyIds;

    public MultiOrgManagerPolicySyncQueueable(List<String> policyIds) {
        this.policyIds = policyIds == null ? new List<String>() : policyIds.deepClone();
    }

    public void execute(QueueableContext context) {
        List<Elaro_Connected_Org__c> activeOrgs = [
            SELECT Id, Instance_URL__c, Org_Id__c
            FROM Elaro_Connected_Org__c
            WHERE Is_Active__c = true AND Connection_Status__c = 'Connected'
            WITH USER_MODE
        ];

        List<Compliance_Policy__mdt> policies = [
            SELECT DeveloperName, Label, MasterLabel, Description__c, Framework__c
            FROM Compliance_Policy__mdt
            WHERE Id IN :policyIds OR DeveloperName IN :policyIds
            WITH USER_MODE
        ];

        for (Elaro_Connected_Org__c org : activeOrgs) {
            MultiOrgManager.syncPoliciesToOrg(org, policies);
        }
    }
}
```

## Finding 4 — SUGGESTION — Test coverage threshold requires org execution evidence
**File:** `Org-level (not statically derivable from source files)`

**Quoted code:**
```text
N/A (requires org test run artifacts)
```

**Why this is a SUGGESTION:** Static analysis cannot prove org-wide coverage >= 75%; this must be verified in a target org.

**Complete corrected code block:**
```bash
sf apex run test --code-coverage --result-format human --wait 60
sf apex get test --test-run-id <TEST_RUN_ID> --code-coverage --result-format human
```
