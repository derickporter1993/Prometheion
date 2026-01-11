/**
 * HIPAAAuditControlService
 *
 * Audit controls per HIPAA Security Rule (45 CFR 164.312(b)).
 * Handles audit log analysis, access pattern monitoring, and compliance reporting.
 *
 * @author Prometheion
 * @version 1.0
 */
public with sharing class HIPAAAuditControlService extends ComplianceServiceBase {

    private static final Integer DEFAULT_RETENTION_YEARS = 6;
    private static final Integer SUSPICIOUS_ACCESS_THRESHOLD = 100;

    /**
     * Get framework name
     */
    public override String getFrameworkName() {
        return 'HIPAA';
    }

    /**
     * Get framework score multiplier
     */
    protected override Decimal getFrameworkMultiplier() {
        return 0.95;
    }

    /**
     * Evaluate audit controls
     */
    protected override List<Violation> evaluateControls() {
        List<Violation> violations = new List<Violation>();

        // Check audit log coverage
        AuditCoverageResult coverage = evaluateAuditCoverage();
        if (!coverage.compliant) {
            for (String gap : coverage.gaps) {
                violations.add(new Violation(
                    'Audit Log Gap',
                    gap,
                    'HIGH',
                    'HIPAA-164.312(b)',
                    'Enable audit logging for all PHI access',
                    7.5
                ));
            }
        }

        // Check for suspicious access patterns
        List<SuspiciousAccess> suspicious = detectSuspiciousAccess();
        for (SuspiciousAccess access : suspicious) {
            violations.add(new Violation(
                'Suspicious PHI Access',
                'User ' + access.userName + ' accessed ' + access.accessCount + ' PHI records',
                access.riskLevel,
                'HIPAA-164.312(b)',
                'Investigate unusual access pattern',
                access.riskLevel == 'CRITICAL' ? 9.0 : 6.5
            ));
        }

        // Check audit log retention
        if (!checkRetentionCompliance()) {
            violations.add(new Violation(
                'Audit Retention Gap',
                'Audit logs may not be retained for required 6-year period',
                'MEDIUM',
                'HIPAA-164.530(j)',
                'Configure audit log archival for 6-year retention',
                5.5
            ));
        }

        return violations;
    }

    // ========== Aura-Enabled Methods ==========

    /**
     * Evaluate overall audit control compliance
     */
    @AuraEnabled(cacheable=false)
    public static AuditComplianceResult evaluateAuditCompliance() {
        HIPAAAuditControlService service = new HIPAAAuditControlService();
        AuditComplianceResult result = new AuditComplianceResult();
        result.evaluationDate = DateTime.now();

        // Evaluate all audit controls
        result.coverageResult = service.evaluateAuditCoverage();
        result.accessPatternResult = service.analyzeAccessPatterns();
        result.retentionCompliant = service.checkRetentionCompliance();

        // Calculate overall score
        Decimal coverageScore = result.coverageResult.compliant ? 100 : 70;
        Decimal patternScore = result.accessPatternResult.suspiciousCount == 0 ? 100 :
            Math.max(50, 100 - (result.accessPatternResult.suspiciousCount * 10));
        Decimal retentionScore = result.retentionCompliant ? 100 : 80;

        result.overallScore = ((coverageScore + patternScore + retentionScore) / 3).setScale(2);
        result.compliant = result.overallScore >= 80;

        return result;
    }

    /**
     * Get PHI access logs for a date range
     */
    @AuraEnabled(cacheable=true)
    public static List<PHIAccessLog> getPHIAccessLogs(Date startDate, Date endDate) {
        List<PHIAccessLog> logs = new List<PHIAccessLog>();

        // Query audit logs (using Login History and Setup Audit Trail as proxies)
        List<LoginHistory> logins = [
            SELECT Id, UserId, LoginTime, SourceIp, Status, Application, Browser
            FROM LoginHistory
            WHERE LoginTime >= :startDate AND LoginTime <= :endDate
            WITH SECURITY_ENFORCED
            ORDER BY LoginTime DESC
            LIMIT 1000
        ];

        for (LoginHistory login : logins) {
            PHIAccessLog log = new PHIAccessLog();
            log.userId = login.UserId;
            log.accessTime = login.LoginTime;
            log.sourceIp = login.SourceIp;
            log.accessType = 'Login';
            log.status = login.Status;
            log.application = login.Application;
            logs.add(log);
        }

        return logs;
    }

    /**
     * Get access statistics by user
     */
    @AuraEnabled(cacheable=true)
    public static List<UserAccessStats> getUserAccessStats(Integer days) {
        if (days == null || days <= 0) {
            days = 30;
        }

        List<UserAccessStats> stats = new List<UserAccessStats>();
        DateTime startTime = DateTime.now().addDays(-days);

        List<AggregateResult> results = [
            SELECT UserId, COUNT(Id) cnt, MAX(LoginTime) lastAccess
            FROM LoginHistory
            WHERE LoginTime >= :startTime
            WITH SECURITY_ENFORCED
            GROUP BY UserId
            ORDER BY COUNT(Id) DESC
            LIMIT 100
        ];

        Set<Id> userIds = new Set<Id>();
        Map<Id, AggregateResult> resultMap = new Map<Id, AggregateResult>();

        for (AggregateResult ar : results) {
            Id userId = (Id) ar.get('UserId');
            userIds.add(userId);
            resultMap.put(userId, ar);
        }

        Map<Id, User> users = new Map<Id, User>([
            SELECT Id, Name, Username, Profile.Name
            FROM User
            WHERE Id IN :userIds
            WITH SECURITY_ENFORCED
        ]);

        for (Id userId : userIds) {
            AggregateResult ar = resultMap.get(userId);
            User u = users.get(userId);

            UserAccessStats stat = new UserAccessStats();
            stat.userId = userId;
            stat.userName = u != null ? u.Name : 'Unknown';
            stat.profileName = u != null && u.Profile != null ? u.Profile.Name : 'Unknown';
            stat.accessCount = (Integer) ar.get('cnt');
            stat.lastAccess = (DateTime) ar.get('lastAccess');
            stat.riskLevel = stat.accessCount > SUSPICIOUS_ACCESS_THRESHOLD ? 'High' : 'Normal';

            stats.add(stat);
        }

        return stats;
    }

    /**
     * Detect suspicious access patterns
     */
    @AuraEnabled(cacheable=false)
    public static List<SuspiciousAccess> detectSuspiciousAccessPatterns() {
        HIPAAAuditControlService service = new HIPAAAuditControlService();
        return service.detectSuspiciousAccess();
    }

    /**
     * Generate audit report
     */
    @AuraEnabled
    public static Id generateAuditReport(Date startDate, Date endDate) {
        if (startDate == null) {
            startDate = Date.today().addDays(-30);
        }
        if (endDate == null) {
            endDate = Date.today();
        }

        HIPAAAuditControlService service = new HIPAAAuditControlService();

        // Build report content
        String reportContent = 'HIPAA Audit Control Report\n';
        reportContent += '=' .repeat(50) + '\n\n';
        reportContent += 'Report Period: ' + startDate.format() + ' to ' + endDate.format() + '\n';
        reportContent += 'Generated: ' + DateTime.now().format() + '\n\n';

        // Audit coverage section
        reportContent += 'AUDIT COVERAGE\n';
        reportContent += '-'.repeat(30) + '\n';
        AuditCoverageResult coverage = service.evaluateAuditCoverage();
        reportContent += 'Compliant: ' + coverage.compliant + '\n';
        reportContent += 'Objects Tracked: ' + coverage.objectsWithTracking + '/' + coverage.totalPHIObjects + '\n';
        if (!coverage.gaps.isEmpty()) {
            reportContent += 'Gaps:\n';
            for (String gap : coverage.gaps) {
                reportContent += '  - ' + gap + '\n';
            }
        }
        reportContent += '\n';

        // Access pattern section
        reportContent += 'ACCESS PATTERNS\n';
        reportContent += '-'.repeat(30) + '\n';
        List<UserAccessStats> stats = getUserAccessStats(
            startDate.daysBetween(endDate)
        );
        reportContent += 'Total Users with Access: ' + stats.size() + '\n';
        Integer highRiskUsers = 0;
        for (UserAccessStats stat : stats) {
            if (stat.riskLevel == 'High') {
                highRiskUsers++;
            }
        }
        reportContent += 'High Risk Users: ' + highRiskUsers + '\n\n';

        // Suspicious access section
        reportContent += 'SUSPICIOUS ACCESS DETECTED\n';
        reportContent += '-'.repeat(30) + '\n';
        List<SuspiciousAccess> suspicious = service.detectSuspiciousAccess();
        if (suspicious.isEmpty()) {
            reportContent += 'No suspicious access patterns detected.\n';
        } else {
            for (SuspiciousAccess sa : suspicious) {
                reportContent += '  - ' + sa.userName + ': ' + sa.reason + '\n';
            }
        }

        // Create ContentVersion
        ContentVersion cv = new ContentVersion();
        cv.Title = 'HIPAA_Audit_Report_' + DateTime.now().format('yyyy-MM-dd');
        cv.PathOnClient = cv.Title + '.txt';
        cv.VersionData = Blob.valueOf(reportContent);
        PrometheionSecurityUtils.validateCRUDAccess('ContentVersion', DmlOperation.DML_INSERT);
        insert cv;

        // Get ContentDocumentId
        cv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id WITH SECURITY_ENFORCED];

        service.logAuditEntry('HIPAA_Audit_Report_Generated', cv.ContentDocumentId,
            'Audit report generated for ' + startDate.format() + ' to ' + endDate.format());

        return cv.ContentDocumentId;
    }

    /**
     * Get audit log retention status
     */
    @AuraEnabled(cacheable=true)
    public static RetentionStatus getRetentionStatus() {
        HIPAAAuditControlService service = new HIPAAAuditControlService();

        RetentionStatus status = new RetentionStatus();
        status.requiredYears = DEFAULT_RETENTION_YEARS;
        status.compliant = service.checkRetentionCompliance();

        // Get oldest audit record
        List<SetupAuditTrail> oldest = [
            SELECT CreatedDate
            FROM SetupAuditTrail
            WITH SECURITY_ENFORCED
            ORDER BY CreatedDate ASC
            LIMIT 1
        ];

        if (!oldest.isEmpty()) {
            status.oldestRecordDate = oldest[0].CreatedDate.date();
            status.currentRetentionDays = status.oldestRecordDate.daysBetween(Date.today());
        }

        // Salesforce retains Setup Audit Trail for 180 days by default
        // Field Audit Trail can be configured for longer retention
        status.configuredRetentionDays = 180; // Default Salesforce retention
        status.recommendation = status.compliant ? 'Retention policy meets HIPAA requirements' :
            'Enable Field Audit Trail with extended retention for HIPAA compliance';

        return status;
    }

    // ========== Private Helper Methods ==========

    private AuditCoverageResult evaluateAuditCoverage() {
        AuditCoverageResult result = new AuditCoverageResult();
        result.gaps = new List<String>();

        // PHI objects that should have Field History Tracking
        Set<String> phiObjects = new Set<String>{'Contact', 'Lead', 'Account', 'Case'};
        result.totalPHIObjects = phiObjects.size();
        result.objectsWithTracking = 0;

        for (String objectName : phiObjects) {
            try {
                Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);
                if (objType != null) {
                    Map<String, Schema.SObjectField> fields = objType.getDescribe().fields.getMap();
                    Boolean hasTracking = false;

                    for (Schema.SObjectField field : fields.values()) {
                        Schema.DescribeFieldResult fieldDesc = field.getDescribe();
                        if (fieldDesc.isHistoryTracked() != null && fieldDesc.isHistoryTracked()) {
                            hasTracking = true;
                            break;
                        }
                    }

                    if (hasTracking) {
                        result.objectsWithTracking++;
                    } else {
                        result.gaps.add(objectName + ' does not have Field History Tracking enabled');
                    }
                }
            } catch (Exception e) {
                result.gaps.add('Unable to evaluate ' + objectName + ': ' + e.getMessage());
            }
        }

        result.compliant = result.gaps.isEmpty();
        return result;
    }

    private AccessPatternResult analyzeAccessPatterns() {
        AccessPatternResult result = new AccessPatternResult();

        DateTime last30Days = DateTime.now().addDays(-30);

        // Analyze login patterns
        List<AggregateResult> loginPatterns = [
            SELECT UserId, COUNT(Id) cnt
            FROM LoginHistory
            WHERE LoginTime >= :last30Days
            WITH SECURITY_ENFORCED
            GROUP BY UserId
            HAVING COUNT(Id) > :SUSPICIOUS_ACCESS_THRESHOLD
        ];

        result.suspiciousCount = loginPatterns.size();
        result.totalAccessEvents = [
            SELECT COUNT()
            FROM LoginHistory
            WHERE LoginTime >= :last30Days
            WITH SECURITY_ENFORCED
        ];

        return result;
    }

    private List<SuspiciousAccess> detectSuspiciousAccess() {
        List<SuspiciousAccess> suspicious = new List<SuspiciousAccess>();

        DateTime last7Days = DateTime.now().addDays(-7);

        // Check for high-volume access
        List<AggregateResult> highVolume = [
            SELECT UserId, COUNT(Id) cnt
            FROM LoginHistory
            WHERE LoginTime >= :last7Days
            WITH SECURITY_ENFORCED
            GROUP BY UserId
            HAVING COUNT(Id) > :SUSPICIOUS_ACCESS_THRESHOLD
        ];

        Set<Id> userIds = new Set<Id>();
        for (AggregateResult ar : highVolume) {
            userIds.add((Id) ar.get('UserId'));
        }

        Map<Id, User> users = new Map<Id, User>();
        if (!userIds.isEmpty()) {
            users = new Map<Id, User>([
                SELECT Id, Name FROM User WHERE Id IN :userIds WITH SECURITY_ENFORCED
            ]);
        }

        for (AggregateResult ar : highVolume) {
            Id userId = (Id) ar.get('UserId');
            Integer count = (Integer) ar.get('cnt');

            SuspiciousAccess sa = new SuspiciousAccess();
            sa.userId = userId;
            sa.userName = users.containsKey(userId) ? users.get(userId).Name : 'Unknown';
            sa.accessCount = count;
            sa.reason = 'High volume access: ' + count + ' events in 7 days';
            sa.riskLevel = count > SUSPICIOUS_ACCESS_THRESHOLD * 2 ? 'CRITICAL' : 'HIGH';
            sa.detectedDate = DateTime.now();

            suspicious.add(sa);
        }

        // Check for after-hours access
        List<LoginHistory> afterHours = [
            SELECT UserId, LoginTime
            FROM LoginHistory
            WHERE LoginTime >= :last7Days
            AND (HOUR_IN_DAY(LoginTime) < 6 OR HOUR_IN_DAY(LoginTime) > 22)
            WITH SECURITY_ENFORCED
            LIMIT 100
        ];

        Map<Id, Integer> afterHoursCount = new Map<Id, Integer>();
        for (LoginHistory lh : afterHours) {
            if (!afterHoursCount.containsKey(lh.UserId)) {
                afterHoursCount.put(lh.UserId, 0);
                userIds.add(lh.UserId);
            }
            afterHoursCount.put(lh.UserId, afterHoursCount.get(lh.UserId) + 1);
        }

        // Get additional user names
        if (!userIds.isEmpty()) {
            for (User u : [SELECT Id, Name FROM User WHERE Id IN :userIds WITH SECURITY_ENFORCED]) {
                if (!users.containsKey(u.Id)) {
                    users.put(u.Id, u);
                }
            }
        }

        for (Id userId : afterHoursCount.keySet()) {
            Integer count = afterHoursCount.get(userId);
            if (count >= 5) { // 5+ after-hours logins is suspicious
                SuspiciousAccess sa = new SuspiciousAccess();
                sa.userId = userId;
                sa.userName = users.containsKey(userId) ? users.get(userId).Name : 'Unknown';
                sa.accessCount = count;
                sa.reason = 'Frequent after-hours access: ' + count + ' events outside business hours';
                sa.riskLevel = 'MEDIUM';
                sa.detectedDate = DateTime.now();

                suspicious.add(sa);
            }
        }

        return suspicious;
    }

    private Boolean checkRetentionCompliance() {
        // HIPAA requires 6-year retention
        // Check if we have records going back at least 6 years
        // (In practice, this would check Field Audit Trail configuration)
        Date sixYearsAgo = Date.today().addYears(-DEFAULT_RETENTION_YEARS);

        // Salesforce default retention is 180 days for Setup Audit Trail
        // Field Audit Trail (with Shield) can be configured for longer
        // This is a simplified check
        return false; // Assume non-compliant unless Shield is configured
    }

    // ========== Inner Classes ==========

    public class AuditComplianceResult {
        @AuraEnabled public DateTime evaluationDate;
        @AuraEnabled public AuditCoverageResult coverageResult;
        @AuraEnabled public AccessPatternResult accessPatternResult;
        @AuraEnabled public Boolean retentionCompliant;
        @AuraEnabled public Decimal overallScore;
        @AuraEnabled public Boolean compliant;
    }

    public class AuditCoverageResult {
        @AuraEnabled public Boolean compliant;
        @AuraEnabled public Integer totalPHIObjects;
        @AuraEnabled public Integer objectsWithTracking;
        @AuraEnabled public List<String> gaps;
    }

    public class AccessPatternResult {
        @AuraEnabled public Integer totalAccessEvents;
        @AuraEnabled public Integer suspiciousCount;
    }

    public class PHIAccessLog {
        @AuraEnabled public Id userId;
        @AuraEnabled public DateTime accessTime;
        @AuraEnabled public String sourceIp;
        @AuraEnabled public String accessType;
        @AuraEnabled public String status;
        @AuraEnabled public String application;
    }

    public class UserAccessStats {
        @AuraEnabled public Id userId;
        @AuraEnabled public String userName;
        @AuraEnabled public String profileName;
        @AuraEnabled public Integer accessCount;
        @AuraEnabled public DateTime lastAccess;
        @AuraEnabled public String riskLevel;
    }

    public class SuspiciousAccess {
        @AuraEnabled public Id userId;
        @AuraEnabled public String userName;
        @AuraEnabled public Integer accessCount;
        @AuraEnabled public String reason;
        @AuraEnabled public String riskLevel;
        @AuraEnabled public DateTime detectedDate;
    }

    public class RetentionStatus {
        @AuraEnabled public Integer requiredYears;
        @AuraEnabled public Boolean compliant;
        @AuraEnabled public Date oldestRecordDate;
        @AuraEnabled public Integer currentRetentionDays;
        @AuraEnabled public Integer configuredRetentionDays;
        @AuraEnabled public String recommendation;
    }
}
