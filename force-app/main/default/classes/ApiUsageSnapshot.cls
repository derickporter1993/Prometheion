public with sharing class ApiUsageSnapshot implements Schedulable, Queueable {
    public class LimitsResponse {
        public class DailyLimit { public Integer Max; public Integer Remaining; }
        public DailyLimit DailyApiRequests;
    }

    public void execute(QueueableContext qc) { run(); }
    public void execute(SchedulableContext sc) { run(); }

    public static void runAsync() { System.enqueueJob(new ApiUsageSnapshot()); }

    public static void run() {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:SF_Limits/services/data/v65.0/limits');
        req.setMethod('GET');
        req.setHeader('Accept','application/json');
        req.setTimeout(10000); // 10 second timeout
        HttpResponse res = new Http().send(req);
        if (res.getStatusCode() >= 300) throw new CalloutException('Limits callout failed: ' + res.getStatus());
        LimitsResponse lr = (LimitsResponse) JSON.deserialize(res.getBody(), LimitsResponse.class);
        Integer max = lr.DailyApiRequests != null ? lr.DailyApiRequests.Max : null;
        Integer remaining = lr.DailyApiRequests != null ? lr.DailyApiRequests.Remaining : null;
        if (max == null || remaining == null) return;
        Integer used = max - remaining;
        Decimal pct = (max == 0) ? 0 : (Decimal.valueOf(used) / Decimal.valueOf(max))*100;

        Datetime now = System.now();
        Datetime projected = null;
        if (used > 0) {
            Datetime midnight = Datetime.newInstance(now.date(), Time.newInstance(0,0,0,0));
            Long secs = (now.getTime() - midnight.getTime())/1000;
            Decimal pctPerSec = (pct / Math.max(1, secs));
            Decimal remainingPct = 100 - pct;
            Long secsToExhaust = (Long) (remainingPct / Math.max(0.0001, pctPerSec));
            projected = now.addSeconds((Integer)Math.min(Integer.MAX_VALUE, secsToExhaust));
        }

        if (Schema.sObjectType.API_Usage_Snapshot__c.isCreateable()) {
            insert new API_Usage_Snapshot__c(
                Taken_On__c = now,
                Daily_Used__c = used,
                Daily_Limit__c = max,
                Percent_Used__c = pct.setScale(2),
                Projected_Exhaustion__c = projected
            );
        } else {
            System.debug(LoggingLevel.ERROR, 'ApiUsageSnapshot: Insufficient permissions to create API_Usage_Snapshot__c');
        }
    }
}
