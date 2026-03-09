/**
 * Test class for {@link BoardGovernanceService}. Validates report creation,
 * content updates, approval workflow, and period-based retrieval.
 *
 * @author Elaro Team
 * @since v3.1.0 (Spring '26)
 * @group SEC Cybersecurity
 * @see BoardGovernanceService
 */
@IsTest
private class BoardGovernanceServiceTest {

    @TestSetup
    static void makeData() {
        Board_Governance_Report__c report = new Board_Governance_Report__c(
            Report_Period__c = 'FY2025',
            Report_Type__c = '10-K',
            Status__c = 'Draft'
        );
        insert as user report;
    }

    /**
     * Verify createReport produces a record with Draft status.
     */
    @IsTest
    static void testCreateReport_success() {
        Test.startTest();
        Board_Governance_Report__c report = BoardGovernanceService.createReport('FY2026', 'Annual');
        Test.stopTest();

        Assert.isNotNull(report.Id, 'Report should have been inserted');

        Board_Governance_Report__c queried = [
            SELECT Report_Period__c, Report_Type__c, Status__c
            FROM Board_Governance_Report__c
            WHERE Id = :report.Id
            WITH USER_MODE
        ];
        Assert.areEqual('FY2026', queried.Report_Period__c, 'Report period should match');
        Assert.areEqual('Annual', queried.Report_Type__c, 'Report type should match');
        Assert.areEqual('Draft', queried.Status__c, 'Initial status should be Draft');
    }

    /**
     * Verify updateReportContent updates all section fields from the map.
     */
    @IsTest
    static void testUpdateReportContent_updatesAllSections() {
        Board_Governance_Report__c report = [
            SELECT Id FROM Board_Governance_Report__c WHERE Report_Period__c = 'FY2025' LIMIT 1
        ];

        Map<String, String> sections = new Map<String, String>{
            BoardGovernanceService.SECTION_GOVERNANCE => 'Our cybersecurity governance framework includes quarterly board briefings.',
            BoardGovernanceService.SECTION_RISK_MANAGEMENT => 'We employ a risk-based approach aligned with NIST CSF.',
            BoardGovernanceService.SECTION_STRATEGY => 'Our strategy integrates cybersecurity into enterprise risk management.',
            BoardGovernanceService.SECTION_BOARD_OVERSIGHT => 'The Audit Committee oversees cybersecurity risks on behalf of the full board.',
            BoardGovernanceService.SECTION_MANAGEMENT_ROLE => 'The CISO reports directly to the CEO with quarterly board presentations.'
        };

        Test.startTest();
        BoardGovernanceService.updateReportContent(report.Id, sections);
        Test.stopTest();

        Board_Governance_Report__c updated = [
            SELECT Governance_Description__c, Risk_Management_Description__c,
                Strategy_Description__c, Board_Oversight_Description__c,
                Management_Role_Description__c
            FROM Board_Governance_Report__c
            WHERE Id = :report.Id
            WITH USER_MODE
        ];

        Assert.isTrue(
            updated.Governance_Description__c.contains('cybersecurity governance'),
            'Governance description should be updated'
        );
        Assert.isTrue(
            updated.Risk_Management_Description__c.contains('NIST CSF'),
            'Risk management description should be updated'
        );
        Assert.isTrue(
            updated.Strategy_Description__c.contains('enterprise risk management'),
            'Strategy description should be updated'
        );
        Assert.isTrue(
            updated.Board_Oversight_Description__c.contains('Audit Committee'),
            'Board oversight description should be updated'
        );
        Assert.isTrue(
            updated.Management_Role_Description__c.contains('CISO'),
            'Management role description should be updated'
        );
    }

    /**
     * Verify approveReport sets approval fields correctly.
     */
    @IsTest
    static void testApproveReport_setsApprovalFields() {
        Board_Governance_Report__c report = [
            SELECT Id FROM Board_Governance_Report__c WHERE Report_Period__c = 'FY2025' LIMIT 1
        ];

        Test.startTest();
        BoardGovernanceService.approveReport(report.Id);
        Test.stopTest();

        Board_Governance_Report__c approved = [
            SELECT Status__c, Approved_Date__c, Approved_By__c
            FROM Board_Governance_Report__c
            WHERE Id = :report.Id
            WITH USER_MODE
        ];

        Assert.areEqual('Approved', approved.Status__c, 'Status should be Approved');
        Assert.areEqual(Date.today(), approved.Approved_Date__c, 'Approved date should be today');
        Assert.areEqual(
            UserInfo.getUserId(),
            approved.Approved_By__c,
            'Approved by should be current user'
        );
    }

    /**
     * Verify getReportsByPeriod filters correctly by period.
     */
    @IsTest
    static void testGetReportsByPeriod_filtersCorrectly() {
        // Create a report for a different period
        Board_Governance_Report__c otherReport = new Board_Governance_Report__c(
            Report_Period__c = 'FY2024',
            Report_Type__c = '10-K',
            Status__c = 'Draft'
        );
        insert as user otherReport;

        Test.startTest();
        List<Board_Governance_Report__c> fy2025Reports = BoardGovernanceService.getReportsByPeriod('FY2025');
        List<Board_Governance_Report__c> fy2024Reports = BoardGovernanceService.getReportsByPeriod('FY2024');
        List<Board_Governance_Report__c> emptyResults = BoardGovernanceService.getReportsByPeriod('FY2023');
        Test.stopTest();

        Assert.areEqual(1, fy2025Reports.size(), 'Should return 1 report for FY2025');
        Assert.areEqual(1, fy2024Reports.size(), 'Should return 1 report for FY2024');
        Assert.isTrue(emptyResults.isEmpty(), 'Should return no reports for FY2023');
    }

    /**
     * Verify approveReport throws exception when report is already approved.
     */
    @IsTest
    static void testApproveReport_alreadyApproved_throwsException() {
        Board_Governance_Report__c report = [
            SELECT Id FROM Board_Governance_Report__c WHERE Report_Period__c = 'FY2025' LIMIT 1
        ];
        BoardGovernanceService.approveReport(report.Id);

        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            BoardGovernanceService.approveReport(report.Id);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            Assert.isTrue(
                e.getMessage().contains('already approved'),
                'Exception should mention already approved'
            );
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'Should throw exception when approving an already approved report');
    }

    /**
     * Verify updateReportContent throws exception on approved report.
     */
    @IsTest
    static void testUpdateReportContent_approvedReport_throwsException() {
        Board_Governance_Report__c report = [
            SELECT Id FROM Board_Governance_Report__c WHERE Report_Period__c = 'FY2025' LIMIT 1
        ];
        BoardGovernanceService.approveReport(report.Id);

        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            BoardGovernanceService.updateReportContent(report.Id, new Map<String, String>{
                BoardGovernanceService.SECTION_GOVERNANCE => 'Attempted update'
            });
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            Assert.isTrue(
                e.getMessage().contains('approved'),
                'Exception should mention approved status restriction'
            );
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'Should throw exception when modifying approved report');
    }
}
