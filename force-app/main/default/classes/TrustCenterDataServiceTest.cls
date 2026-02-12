/**
 * Test class for TrustCenterDataService.
 *
 * @author Elaro Team
 * @since v1.0.0 (Spring '26)
 * @group Trust Center
 */
@IsTest(testFor=TrustCenterDataService.class)
private class TrustCenterDataServiceTest {

    @TestSetup
    static void makeData() {
        // Create test compliance controls and assessments
        // Assumes Compliance_Control__c and Compliance_Assessment__c exist

        List<Compliance_Control__c> controls = new List<Compliance_Control__c>();

        // SOC2 controls
        for (Integer i = 0; i < 10; i++) {
            controls.add(new Compliance_Control__c(
                Name = 'SOC2-CC' + i,
                Framework__c = 'SOC2',
                Status__c = (i < 9) ? 'Compliant' : 'Non_Compliant'
            ));
        }

        // HIPAA controls
        for (Integer i = 0; i < 5; i++) {
            controls.add(new Compliance_Control__c(
                Name = 'HIPAA-164.' + i,
                Framework__c = 'HIPAA',
                Status__c = 'Compliant'
            ));
        }

        insert as user controls;

        // Create assessment
        Compliance_Assessment__c assessment = new Compliance_Assessment__c(
            Name = 'SOC2 Q1 2026',
            Framework__c = 'SOC2',
            Assessment_Date__c = Date.today().addDays(-30)
        );
        insert as user assessment;
    }

    @IsTest
    static void shouldAggregateComplianceData() {
        Test.startTest();
        TrustCenterDataService service = new TrustCenterDataService();
        service.aggregateComplianceData();
        Test.stopTest();

        List<Trust_Center_View__c> views = [
            SELECT Id, Framework__c, Compliance_Percentage__c, Controls_Total__c,
                   Controls_Compliant__c, Is_Public__c
            FROM Trust_Center_View__c
            WITH USER_MODE
        ];

        Assert.isTrue(views.size() > 0, 'Should create at least one view');

        // Find SOC2 view
        Trust_Center_View__c soc2View = null;
        for (Trust_Center_View__c v : views) {
            if (v.Framework__c == 'SOC2') {
                soc2View = v;
                break;
            }
        }

        Assert.isNotNull(soc2View, 'Should create SOC2 view');
        Assert.areEqual(10, soc2View.Controls_Total__c,
            'Should count 10 total SOC2 controls');
        Assert.areEqual(9, soc2View.Controls_Compliant__c,
            'Should count 9 compliant SOC2 controls');
        Assert.areEqual(90.00, soc2View.Compliance_Percentage__c,
            'Should calculate 90% compliance');
        Assert.isTrue(soc2View.Is_Public__c,
            'Should mark as public since > 80% compliant');
    }

    @IsTest
    static void shouldMarkLowComplianceAsNotPublic() {
        // Create low compliance framework
        List<Compliance_Control__c> controls = new List<Compliance_Control__c>();
        for (Integer i = 0; i < 10; i++) {
            controls.add(new Compliance_Control__c(
                Name = 'GDPR-' + i,
                Framework__c = 'GDPR',
                Status__c = (i < 7) ? 'Non_Compliant' : 'Compliant'
            ));
        }
        insert as user controls;

        Test.startTest();
        TrustCenterDataService service = new TrustCenterDataService();
        service.aggregateComplianceData();
        Test.stopTest();

        List<Trust_Center_View__c> views = [
            SELECT Id, Framework__c, Compliance_Percentage__c, Is_Public__c
            FROM Trust_Center_View__c
            WHERE Framework__c = 'GDPR'
            WITH USER_MODE
        ];

        Assert.areEqual(1, views.size(), 'Should create GDPR view');
        Assert.areEqual(30.00, views[0].Compliance_Percentage__c,
            'Should calculate 30% compliance');
        Assert.isFalse(views[0].Is_Public__c,
            'Should mark as not public since < 80% compliant');
    }

    @IsTest
    static void shouldHandleSchedulableExecution() {
        Test.startTest();
        String cronExp = '0 0 0 * * ?'; // Daily at midnight
        String jobId = System.schedule('Trust Center Aggregation Test',
            cronExp, new TrustCenterDataService());
        Test.stopTest();

        Assert.isNotNull(jobId, 'Should schedule job successfully');

        // Verify job exists
        CronTrigger ct = [
            SELECT Id, CronExpression, State
            FROM CronTrigger
            WHERE Id = :jobId
            LIMIT 1
        ];

        Assert.areEqual(cronExp, ct.CronExpression, 'Should have correct cron expression');
    }

    @IsTest
    static void shouldDetermineCertificationStatus() {
        TrustCenterDataService service = new TrustCenterDataService();

        // Test Certified status
        String status = service.determineCertificationStatus(96.0, Date.today().addDays(-180));
        Assert.areEqual('Certified', status,
            'Should be Certified with 96% and recent audit');

        // Test Renewal Required
        status = service.determineCertificationStatus(96.0, Date.today().addDays(-400));
        Assert.areEqual('Renewal_Required', status,
            'Should be Renewal_Required with old audit');

        // Test In Progress
        status = service.determineCertificationStatus(75.0, Date.today());
        Assert.areEqual('In_Progress', status,
            'Should be In_Progress with 75%');

        // Test Not Started
        status = service.determineCertificationStatus(40.0, null);
        Assert.areEqual('Not_Started', status,
            'Should be Not_Started with low compliance');
    }

    @IsTest
    static void shouldHandleNoControls() {
        // Delete all controls
        delete as user [SELECT Id FROM Compliance_Control__c WITH USER_MODE];

        Test.startTest();
        TrustCenterDataService service = new TrustCenterDataService();
        service.aggregateComplianceData();
        Test.stopTest();

        List<Trust_Center_View__c> views = [
            SELECT Id FROM Trust_Center_View__c WITH USER_MODE
        ];

        Assert.areEqual(0, views.size(),
            'Should create no views when no controls exist');
    }
}
