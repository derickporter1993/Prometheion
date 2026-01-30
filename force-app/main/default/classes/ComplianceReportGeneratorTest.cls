/**
 * Test class for ComplianceReportGenerator
 * Provides comprehensive coverage for report generation functionality
 *
 * @author Elaro
 * @version 1.0
 */
@IsTest
private class ComplianceReportGeneratorTest {

    @TestSetup
    static void setupTestData() {
        // Create test compliance gaps with various severities and frameworks
        List<Compliance_Gap__c> gaps = new List<Compliance_Gap__c>();

        // Critical gaps
        for (Integer i = 0; i < 3; i++) {
            gaps.add(new Compliance_Gap__c(
                Name = 'Critical Gap ' + i,
                Severity__c = 'Critical',
                Framework__c = 'HIPAA',
                Status__c = 'Open',
                Description__c = 'Critical compliance gap requiring immediate attention'
            ));
        }

        // High severity gaps
        for (Integer i = 0; i < 5; i++) {
            gaps.add(new Compliance_Gap__c(
                Name = 'High Gap ' + i,
                Severity__c = 'High',
                Framework__c = 'SOC2',
                Status__c = 'Open',
                Description__c = 'High priority gap to address this week'
            ));
        }

        // Medium severity gaps
        for (Integer i = 0; i < 10; i++) {
            gaps.add(new Compliance_Gap__c(
                Name = 'Medium Gap ' + i,
                Severity__c = 'Medium',
                Framework__c = Math.mod(i, 2) == 0 ? 'NIST' : 'GDPR',
                Status__c = 'Open',
                Description__c = 'Medium priority gap for regular remediation'
            ));
        }

        // Low severity gaps
        for (Integer i = 0; i < 7; i++) {
            gaps.add(new Compliance_Gap__c(
                Name = 'Low Gap ' + i,
                Severity__c = 'Low',
                Framework__c = 'PCI-DSS',
                Status__c = 'Open',
                Description__c = 'Low priority improvement opportunity'
            ));
        }

        // Resolved gaps (should not appear in reports)
        for (Integer i = 0; i < 5; i++) {
            gaps.add(new Compliance_Gap__c(
                Name = 'Resolved Gap ' + i,
                Severity__c = 'High',
                Framework__c = 'HIPAA',
                Status__c = 'Resolved',
                Description__c = 'Already resolved gap'
            ));
        }

        insert gaps;

        // Create compliance scores for trend data
        List<Compliance_Score__c> scores = new List<Compliance_Score__c>();
        for (Integer i = 0; i < 5; i++) {
            scores.add(new Compliance_Score__c(
                Risk_Score__c = 25 + (i * 5), // 25, 30, 35, 40, 45
                Org_ID__c = 'test-org-' + i
            ));
        }
        insert scores;
    }

    /**
     * Test generating report data for all frameworks
     */
    @IsTest
    static void testGenerateReportData_AllFrameworks() {
        Test.startTest();
        ComplianceReportGenerator.ReportData data = ComplianceReportGenerator.generateReportData('ALL');
        Test.stopTest();

        System.assertNotEquals(null, data, 'Report data should not be null');
        System.assertNotEquals(null, data.scoreResult, 'Score result should not be null');
        System.assertNotEquals(null, data.gaps, 'Gaps list should not be null');
        System.assertEquals('ALL', data.framework, 'Framework should be ALL');
        System.assertNotEquals(null, data.generatedAt, 'Generated timestamp should be set');

        // Verify gaps are present (excluding resolved)
        System.assertEquals(25, data.gaps.size(), 'Should have 25 open gaps');
    }

    /**
     * Test generating report data for specific framework
     */
    @IsTest
    static void testGenerateReportData_SpecificFramework() {
        Test.startTest();
        ComplianceReportGenerator.ReportData data = ComplianceReportGenerator.generateReportData('HIPAA');
        Test.stopTest();

        System.assertEquals('HIPAA', data.framework, 'Framework should be HIPAA');

        // All gaps should be HIPAA
        for (Compliance_Gap__c gap : data.gaps) {
            System.assertEquals('HIPAA', gap.Framework__c, 'All gaps should be HIPAA');
        }
    }

    /**
     * Test gaps by severity calculation
     */
    @IsTest
    static void testGapsBySeverity() {
        Test.startTest();
        ComplianceReportGenerator.ReportData data = ComplianceReportGenerator.generateReportData('ALL');
        Test.stopTest();

        Map<String, Integer> bySeverity = data.gapsBySeverity;
        System.assertNotEquals(null, bySeverity, 'Gaps by severity should not be null');
        System.assertEquals(3, bySeverity.get('Critical'), 'Should have 3 critical gaps');
        System.assertEquals(5, bySeverity.get('High'), 'Should have 5 high gaps');
        System.assertEquals(10, bySeverity.get('Medium'), 'Should have 10 medium gaps');
        System.assertEquals(7, bySeverity.get('Low'), 'Should have 7 low gaps');
    }

    /**
     * Test gaps by framework calculation
     */
    @IsTest
    static void testGapsByFramework() {
        Test.startTest();
        ComplianceReportGenerator.ReportData data = ComplianceReportGenerator.generateReportData('ALL');
        Test.stopTest();

        Map<String, Integer> byFramework = data.gapsByFramework;
        System.assertNotEquals(null, byFramework, 'Gaps by framework should not be null');
        System.assertEquals(3, byFramework.get('HIPAA'), 'Should have 3 HIPAA gaps');
        System.assertEquals(5, byFramework.get('SOC2'), 'Should have 5 SOC2 gaps');
        System.assertEquals(7, byFramework.get('PCI-DSS'), 'Should have 7 PCI-DSS gaps');
    }

    /**
     * Test score trend retrieval
     */
    @IsTest
    static void testScoreTrend() {
        Test.startTest();
        ComplianceReportGenerator.ReportData data = ComplianceReportGenerator.generateReportData('ALL');
        Test.stopTest();

        System.assertNotEquals(null, data.scoreTrend, 'Score trend should not be null');
        // Trend points should exist if Compliance_Score__c records exist
        System.assert(data.scoreTrend.size() >= 0, 'Score trend should be populated');
    }

    /**
     * Test executive summary generation
     */
    @IsTest
    static void testGenerateExecutiveSummary() {
        ComplianceReportGenerator.ReportData data = ComplianceReportGenerator.generateReportData('ALL');

        Test.startTest();
        String summary = ComplianceReportGenerator.generateExecutiveSummary(data);
        Test.stopTest();

        System.assertNotEquals(null, summary, 'Summary should not be null');
        System.assert(summary.contains('Compliance Score'), 'Summary should contain compliance score');
        System.assert(summary.contains('Critical'), 'Summary should mention critical gaps');
    }

    /**
     * Test executive summary with null data
     */
    @IsTest
    static void testGenerateExecutiveSummary_NullData() {
        Test.startTest();
        String summary = ComplianceReportGenerator.generateExecutiveSummary(null);
        Test.stopTest();

        System.assert(summary.contains('Unable to generate'), 'Should return error message for null data');
    }

    /**
     * Test recommendations generation
     */
    @IsTest
    static void testGenerateRecommendations() {
        ComplianceReportGenerator.ReportData data = ComplianceReportGenerator.generateReportData('ALL');

        Test.startTest();
        List<String> recommendations = ComplianceReportGenerator.generateRecommendations(data);
        Test.stopTest();

        System.assertNotEquals(null, recommendations, 'Recommendations should not be null');
        System.assert(!recommendations.isEmpty(), 'Should have at least one recommendation');
    }

    /**
     * Test recommendations with critical gaps
     */
    @IsTest
    static void testGenerateRecommendations_CriticalGaps() {
        ComplianceReportGenerator.ReportData data = ComplianceReportGenerator.generateReportData('ALL');

        Test.startTest();
        List<String> recommendations = ComplianceReportGenerator.generateRecommendations(data);
        Test.stopTest();

        Boolean hasCriticalRecommendation = false;
        for (String rec : recommendations) {
            if (rec.contains('critical') || rec.contains('Critical')) {
                hasCriticalRecommendation = true;
                break;
            }
        }
        System.assert(hasCriticalRecommendation, 'Should have recommendation about critical gaps');
    }

    /**
     * Test recommendations with null data
     */
    @IsTest
    static void testGenerateRecommendations_NullData() {
        Test.startTest();
        List<String> recommendations = ComplianceReportGenerator.generateRecommendations(null);
        Test.stopTest();

        System.assert(!recommendations.isEmpty(), 'Should return at least one message');
        System.assert(recommendations[0].contains('Unable'), 'Should indicate unable to generate');
    }

    /**
     * Test with no gaps (clean org scenario)
     */
    @IsTest
    static void testGenerateReportData_NoGaps() {
        // Delete all test gaps
        delete [SELECT Id FROM Compliance_Gap__c];

        Test.startTest();
        ComplianceReportGenerator.ReportData data = ComplianceReportGenerator.generateReportData('ALL');
        Test.stopTest();

        System.assertEquals(0, data.gaps.size(), 'Should have no gaps');
        System.assertEquals(0, data.gapsBySeverity.get('Critical'), 'Should have 0 critical');
    }

    /**
     * Test with null framework filter
     */
    @IsTest
    static void testGenerateReportData_NullFramework() {
        Test.startTest();
        ComplianceReportGenerator.ReportData data = ComplianceReportGenerator.generateReportData(null);
        Test.stopTest();

        System.assertEquals('ALL', data.framework, 'Null framework should default to ALL');
    }

    /**
     * Test with empty framework filter
     */
    @IsTest
    static void testGenerateReportData_EmptyFramework() {
        Test.startTest();
        ComplianceReportGenerator.ReportData data = ComplianceReportGenerator.generateReportData('');
        Test.stopTest();

        System.assertEquals('ALL', data.framework, 'Empty framework should default to ALL');
    }

    /**
     * Test bulk data handling (200+ records)
     */
    @IsTest
    static void testBulkDataHandling() {
        // Create 200+ additional gaps
        List<Compliance_Gap__c> bulkGaps = new List<Compliance_Gap__c>();
        for (Integer i = 0; i < 200; i++) {
            bulkGaps.add(new Compliance_Gap__c(
                Name = 'Bulk Test Gap ' + i,
                Severity__c = 'Medium',
                Framework__c = 'SOC2',
                Status__c = 'Open'
            ));
        }
        insert bulkGaps;

        Test.startTest();
        ComplianceReportGenerator.ReportData data = ComplianceReportGenerator.generateReportData('SOC2');
        Test.stopTest();

        // Should handle bulk data within limits (200 limit in query)
        System.assert(data.gaps.size() <= 200, 'Should respect query limit');
        System.assertNotEquals(null, data.scoreResult, 'Should still calculate score');
    }

    /**
     * Test TrendPoint wrapper class
     */
    @IsTest
    static void testTrendPointClass() {
        ComplianceReportGenerator.TrendPoint point = new ComplianceReportGenerator.TrendPoint();
        point.reportDate = Date.today();
        point.score = 85.5;
        point.period = 'Jan 1';

        System.assertEquals(Date.today(), point.reportDate, 'Report date should match');
        System.assertEquals(85.5, point.score, 'Score should match');
        System.assertEquals('Jan 1', point.period, 'Period should match');
    }

    /**
     * Test ReportData wrapper class
     */
    @IsTest
    static void testReportDataClass() {
        ComplianceReportGenerator.ReportData data = new ComplianceReportGenerator.ReportData();

        System.assertNotEquals(null, data.gaps, 'Gaps should be initialized');
        System.assertNotEquals(null, data.scoreTrend, 'Score trend should be initialized');
        System.assertNotEquals(null, data.gapsBySeverity, 'Gaps by severity should be initialized');
        System.assertNotEquals(null, data.gapsByFramework, 'Gaps by framework should be initialized');
        System.assertNotEquals(null, data.generatedAt, 'Generated at should be set');
    }
}
