/**
 * Test class for DataResidencyService
 * Tests data residency compliance and regional validation
 * @group Tests
 * @see DataResidencyService
 */
@IsTest(testFor=DataResidencyService.class)
private class DataResidencyServiceTest {

    @TestSetup
    static void setup() {
        Elaro_Evidence_Item__c item = new Elaro_Evidence_Item__c(
            Evidence_Type__c = 'Login',
            Evidence_Date__c = Date.today(),
            Description__c = 'Test evidence for international transfer',
            Status__c = 'COLLECTED'
        );
        insert as user item;
    }

    @isTest
    static void testGetResidencyConfig() {
        Test.startTest();
        DataResidencyService.ResidencyConfig config = DataResidencyService.getResidencyConfig();
        Test.stopTest();

        Assert.areNotEqual(null, config, 'Config should not be null');
        Assert.areNotEqual(null, config.orgInstance, 'Org instance should be set');
        Assert.areNotEqual(null, config.primaryRegion, 'Primary region should be set');
        Assert.isTrue(config.allowedRegions.size() > 0, 'Allowed regions should be populated');
    }

    @isTest
    static void testValidateDataLocationAllowed() {
        Test.startTest();
        DataResidencyService.ValidationResult result = DataResidencyService.validateDataLocation('001000000000001AAA', 'US');
        Test.stopTest();

        Assert.areNotEqual(null, result, 'Result should not be null');
        Assert.areNotEqual(null, result.targetRegion, 'Target region should be set');
    }

    @isTest
    static void testValidateDataLocationEU() {
        Test.startTest();
        DataResidencyService.ValidationResult result = DataResidencyService.validateDataLocation('001000000000001AAA', 'EU');
        Test.stopTest();

        Assert.areNotEqual(null, result, 'Result should not be null');
        Assert.areEqual('EU', result.targetRegion, 'Target region should be EU');
    }

    @isTest
    static void testValidateDataLocationAPAC() {
        Test.startTest();
        DataResidencyService.ValidationResult result = DataResidencyService.validateDataLocation('001000000000001AAA', 'APAC');
        Test.stopTest();

        Assert.areNotEqual(null, result, 'Result should not be null');
    }

    @isTest
    static void testGetLocationSummary() {
        Test.startTest();
        DataResidencyService.LocationSummary summary = DataResidencyService.getLocationSummary();
        Test.stopTest();

        Assert.areNotEqual(null, summary, 'Summary should not be null');
        Assert.isTrue(summary.totalRecords >= 0, 'Total records should be non-negative');
        Assert.areNotEqual(null, summary.primaryRegion, 'Primary region should be set');
    }

    @isTest
    static void testCheckGDPRCompliance() {
        Test.startTest();
        DataResidencyService.GDPRComplianceStatus status = DataResidencyService.checkGDPRCompliance();
        Test.stopTest();

        Assert.areNotEqual(null, status, 'Status should not be null');
        Assert.areNotEqual(null, status.transferMechanism, 'Transfer mechanism should be set');
        Assert.isTrue(status.euDataSubjectsCount >= 0, 'EU data subjects count should be non-negative');
    }

    @isTest
    static void testValidateInvalidRegion() {
        Test.startTest();
        DataResidencyService.ValidationResult result = DataResidencyService.validateDataLocation('001000000000001AAA', 'INVALID');
        Test.stopTest();

        Assert.areEqual(false, result.isAllowed, 'Invalid region should not be allowed');
    }
}
