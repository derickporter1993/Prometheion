/**
 * Tests for OrchestrationService covering full-scan orchestration,
 * single-framework scans, progress tracking, scan persistence,
 * and error handling across the orchestration integration layer.
 *
 * @author Elaro Team
 * @since v1.0.0 (Spring '26)
 * @group Command Center
 * @see OrchestrationService
 */
@IsTest
private class OrchestrationServiceTest {

    @TestSetup
    static void makeData() {
        // Create compliance gaps across frameworks for gap-count assertions
        List<Compliance_Gap__c> gaps = new List<Compliance_Gap__c>();
        gaps.add(new Compliance_Gap__c(
            Framework__c = 'SOC2',
            Policy_Reference__c = 'SOC2_CC6.1',
            Gap_Description__c = 'MFA not enforced',
            Severity__c = 'CRITICAL',
            Status__c = 'OPEN',
            Detected_Date__c = Datetime.now()
        ));
        gaps.add(new Compliance_Gap__c(
            Framework__c = 'HIPAA',
            Policy_Reference__c = 'HIPAA_164.312',
            Gap_Description__c = 'PHI encryption gap',
            Severity__c = 'HIGH',
            Status__c = 'IN_PROGRESS',
            Detected_Date__c = Datetime.now().addDays(-2)
        ));
        gaps.add(new Compliance_Gap__c(
            Framework__c = 'SOC2',
            Policy_Reference__c = 'SOC2_CC7.2',
            Gap_Description__c = 'Verified gap should not count',
            Severity__c = 'MEDIUM',
            Status__c = 'VERIFIED',
            Detected_Date__c = Datetime.now().addDays(-30),
            Actual_Remediation_Date__c = Date.today().addDays(-10)
        ));
        insert as user gaps;

        // Create a baseline Compliance_Score__c so getScanProgress has data
        Compliance_Score__c score = new Compliance_Score__c(
            Org_ID__c = UserInfo.getOrganizationId(),
            Entity_Type__c = 'Organization',
            Entity_Id__c = UserInfo.getOrganizationId(),
            Risk_Score__c = 4.5,
            Framework_Scores__c = '{"SOC2": 70, "HIPAA": 55}',
            Calculated_At__c = Datetime.now()
        );
        insert as user score;
    }

    // ═══════════════════════════════════════════════════════════════
    // triggerFullScan
    // ═══════════════════════════════════════════════════════════════

    @IsTest
    static void shouldTriggerFullScanSuccessfully() {
        Test.startTest();
        OrchestrationService service = new OrchestrationService();
        OrchestrationService.ScanResult result = service.triggerFullScan();
        Test.stopTest();

        Assert.isNotNull(result, 'Scan result should not be null');
        Assert.isNotNull(result.scanId, 'Scan ID should be generated');
        Assert.isTrue(result.scanId.startsWith('SCAN-'), 'Scan ID should start with SCAN- prefix');
        Assert.isNotNull(result.startedAt, 'Start time should be set');
        Assert.isNotNull(result.completedAt, 'Completed time should be set');
        Assert.isTrue(
            result.status == OrchestrationService.STATUS_COMPLETED
            || result.status == OrchestrationService.STATUS_PARTIAL
            || result.status == OrchestrationService.STATUS_FAILED,
            'Status should be a terminal state, got: ' + result.status
        );
        Assert.isNotNull(result.frameworkResults, 'Framework results should not be null');
        Assert.isFalse(result.frameworkResults.isEmpty(),
            'Should have at least one framework result');
    }

    // ═══════════════════════════════════════════════════════════════
    // triggerScan (specific frameworks)
    // ═══════════════════════════════════════════════════════════════

    @IsTest
    static void shouldTriggerScanForSpecificFrameworks() {
        List<String> frameworks = new List<String>{ 'SOC2', 'HIPAA' };

        Test.startTest();
        OrchestrationService service = new OrchestrationService();
        OrchestrationService.ScanResult result = service.triggerScan(frameworks);
        Test.stopTest();

        Assert.isNotNull(result, 'Scan result should not be null');
        Assert.areEqual(2, result.requestedFrameworks.size(),
            'Should have 2 requested frameworks');
        Assert.areEqual(2, result.frameworkResults.size(),
            'Should have 2 framework results');
    }

    @IsTest
    static void shouldRejectNullFrameworksList() {
        Test.startTest();
        try {
            OrchestrationService service = new OrchestrationService();
            service.triggerScan(null);
            Assert.fail('Should throw OrchestrationException for null frameworks');
        } catch (OrchestrationService.OrchestrationException e) {
            Assert.isTrue(e.getMessage().contains('At least one framework'),
                'Error should mention minimum framework requirement');
        }
        Test.stopTest();
    }

    @IsTest
    static void shouldRejectEmptyFrameworksList() {
        Test.startTest();
        try {
            OrchestrationService service = new OrchestrationService();
            service.triggerScan(new List<String>());
            Assert.fail('Should throw OrchestrationException for empty frameworks');
        } catch (OrchestrationService.OrchestrationException e) {
            Assert.isTrue(e.getMessage().contains('At least one framework'),
                'Error should mention minimum framework requirement');
        }
        Test.stopTest();
    }

    @IsTest
    static void shouldRejectUnsupportedFramework() {
        List<String> frameworks = new List<String>{ 'SOC2', 'INVALID_FW' };

        Test.startTest();
        try {
            OrchestrationService service = new OrchestrationService();
            service.triggerScan(frameworks);
            Assert.fail('Should throw OrchestrationException for unsupported framework');
        } catch (OrchestrationService.OrchestrationException e) {
            Assert.isTrue(e.getMessage().contains('Unsupported framework'),
                'Error should mention unsupported framework');
        }
        Test.stopTest();
    }

    // ═══════════════════════════════════════════════════════════════
    // scanSingleFramework
    // ═══════════════════════════════════════════════════════════════

    @IsTest
    static void shouldScanSingleFrameworkSuccessfully() {
        Test.startTest();
        OrchestrationService service = new OrchestrationService();
        OrchestrationService.FrameworkScanResult fsr = service.scanSingleFramework('SOC2');
        Test.stopTest();

        Assert.isNotNull(fsr, 'Framework scan result should not be null');
        Assert.areEqual('SOC2', fsr.framework, 'Framework should be SOC2');
        Assert.isNotNull(fsr.scannedAt, 'Scanned timestamp should be set');
        Assert.isNotNull(fsr.status, 'Status should be set');

        // SOC2 has active gaps (OPEN status) -- VERIFIED gaps should not count
        Assert.isTrue(fsr.activeGapCount >= 1,
            'Should have at least 1 active gap for SOC2, got: ' + fsr.activeGapCount);
    }

    @IsTest
    static void shouldRejectBlankFrameworkOnSingleScan() {
        Test.startTest();
        try {
            OrchestrationService service = new OrchestrationService();
            service.scanSingleFramework('');
            Assert.fail('Should throw OrchestrationException for blank framework');
        } catch (OrchestrationService.OrchestrationException e) {
            Assert.isTrue(e.getMessage().contains('required'),
                'Error should mention framework is required');
        }
        Test.stopTest();
    }

    @IsTest
    static void shouldRejectUnsupportedFrameworkOnSingleScan() {
        Test.startTest();
        try {
            OrchestrationService service = new OrchestrationService();
            service.scanSingleFramework('NONEXISTENT');
            Assert.fail('Should throw OrchestrationException for unsupported framework');
        } catch (OrchestrationService.OrchestrationException e) {
            Assert.isTrue(e.getMessage().contains('Unsupported'),
                'Error should mention unsupported framework');
        }
        Test.stopTest();
    }

    // ═══════════════════════════════════════════════════════════════
    // getScanProgress
    // ═══════════════════════════════════════════════════════════════

    @IsTest
    static void shouldReturnScanProgressWithExistingScore() {
        Test.startTest();
        OrchestrationService service = new OrchestrationService();
        OrchestrationService.ScanProgress progress = service.getScanProgress('SCAN-123');
        Test.stopTest();

        Assert.isNotNull(progress, 'Scan progress should not be null');
        Assert.areEqual('SCAN-123', progress.scanId, 'Scan ID should match');
        Assert.areEqual(OrchestrationService.STATUS_COMPLETED, progress.status,
            'Status should be COMPLETED when score records exist');
        Assert.areEqual(100, progress.completionPercentage,
            'Completion should be 100% when score exists');
        Assert.isNotNull(progress.completedAt, 'Completed timestamp should be set');
        Assert.isNotNull(progress.frameworkStatuses,
            'Framework statuses should be populated');
    }

    @IsTest
    static void shouldReturnPendingWhenNoScoreRecords() {
        delete as user [SELECT Id FROM Compliance_Score__c WITH USER_MODE];

        Test.startTest();
        OrchestrationService service = new OrchestrationService();
        OrchestrationService.ScanProgress progress = service.getScanProgress('SCAN-000');
        Test.stopTest();

        Assert.areEqual(OrchestrationService.STATUS_PENDING, progress.status,
            'Status should be PENDING when no score records exist');
        Assert.areEqual(0, progress.completionPercentage,
            'Completion should be 0% with no score records');
    }

    // ═══════════════════════════════════════════════════════════════
    // getLastScanTimestamp
    // ═══════════════════════════════════════════════════════════════

    @IsTest
    static void shouldReturnLastScanTimestamp() {
        Test.startTest();
        OrchestrationService service = new OrchestrationService();
        Datetime lastScan = service.getLastScanTimestamp();
        Test.stopTest();

        Assert.isNotNull(lastScan, 'Last scan timestamp should not be null when scores exist');
    }

    @IsTest
    static void shouldReturnNullTimestampWhenNoScores() {
        delete as user [SELECT Id FROM Compliance_Score__c WITH USER_MODE];

        Test.startTest();
        OrchestrationService service = new OrchestrationService();
        Datetime lastScan = service.getLastScanTimestamp();
        Test.stopTest();

        Assert.isNull(lastScan, 'Last scan timestamp should be null when no scores exist');
    }

    // ═══════════════════════════════════════════════════════════════
    // Scan persistence
    // ═══════════════════════════════════════════════════════════════

    @IsTest
    static void shouldPersistScanResultsAsComplianceScore() {
        // Count existing scores
        Integer existingCount = [SELECT COUNT() FROM Compliance_Score__c WITH USER_MODE];

        Test.startTest();
        OrchestrationService service = new OrchestrationService();
        service.triggerScan(new List<String>{ 'SOC2' });
        Test.stopTest();

        Integer newCount = [SELECT COUNT() FROM Compliance_Score__c WITH USER_MODE];
        Assert.isTrue(newCount > existingCount,
            'Should have created a new Compliance_Score__c record');

        // Verify the latest score has Framework_Scores__c JSON
        Compliance_Score__c latest = [
            SELECT Framework_Scores__c, Risk_Score__c
            FROM Compliance_Score__c
            WITH USER_MODE
            ORDER BY Calculated_At__c DESC
            LIMIT 1
        ];
        Assert.isNotNull(latest.Framework_Scores__c,
            'Framework_Scores__c should be populated');
        Assert.isTrue(latest.Framework_Scores__c.contains('SOC2'),
            'Framework_Scores__c should contain SOC2');
    }

    // ═══════════════════════════════════════════════════════════════
    // DTO defaults
    // ═══════════════════════════════════════════════════════════════

    @IsTest
    static void shouldInitializeScanResultDefaults() {
        OrchestrationService.ScanResult result = new OrchestrationService.ScanResult();

        Assert.areEqual(OrchestrationService.STATUS_PENDING, result.status,
            'Default status should be PENDING');
        Assert.isNotNull(result.frameworkResults,
            'Framework results list should be initialized');
        Assert.isTrue(result.frameworkResults.isEmpty(),
            'Framework results should be empty by default');
        Assert.areEqual(false, result.isAsync, 'isAsync should default to false');
        Assert.areEqual(0, result.overallComplianceScore,
            'Overall compliance score should default to 0');
    }

    @IsTest
    static void shouldInitializeFrameworkScanResultDefaults() {
        OrchestrationService.FrameworkScanResult fsr = new OrchestrationService.FrameworkScanResult();

        Assert.areEqual(0, fsr.violationCount, 'Violation count should default to 0');
        Assert.areEqual(0, fsr.activeGapCount, 'Active gap count should default to 0');
    }

    @IsTest
    static void shouldInitializeScanProgressDefaults() {
        OrchestrationService.ScanProgress progress = new OrchestrationService.ScanProgress();

        Assert.areEqual(0, progress.completionPercentage,
            'Completion percentage should default to 0');
        Assert.isNotNull(progress.frameworkStatuses,
            'Framework statuses map should be initialized');
    }

    @IsTest
    static void shouldCreateOrchestrationException() {
        OrchestrationService.OrchestrationException ex =
            new OrchestrationService.OrchestrationException('Test error');

        Assert.areEqual('Test error', ex.getMessage(),
            'Exception message should be set correctly');
    }
}
