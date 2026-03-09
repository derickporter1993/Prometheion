/**
 * Test class for ElaroExecutiveKPIController
 * Comprehensive test coverage for KPI dashboard functionality
 * Note: Custom Metadata Types cannot be created in test classes, so coverage
 * is limited to validation, error handling, and inner class paths
 * @author Derick Porter
 * @date 2026-01-03
 */
@IsTest
private class ElaroExecutiveKPIControllerTest {

    @isTest
    static void testGetKPIMetricsEmpty() {
        // Test with no metadata records (expected scenario in test org)
        Test.startTest();
        List<ElaroExecutiveKPIController.KPIMetric> metrics =
            ElaroExecutiveKPIController.getKPIMetrics('');
        Test.stopTest();

        Assert.areNotEqual(null, metrics, 'Should return metrics list (even if empty)');
    }

    @isTest
    static void testGetKPIMetricsWithNull() {
        Test.startTest();
        List<ElaroExecutiveKPIController.KPIMetric> metrics =
            ElaroExecutiveKPIController.getKPIMetrics(null);
        Test.stopTest();

        Assert.areNotEqual(null, metrics, 'Should return metrics list');
    }

    @isTest
    static void testGetKPIMetricsWithRecordIds() {
        Test.startTest();
        List<ElaroExecutiveKPIController.KPIMetric> metrics =
            ElaroExecutiveKPIController.getKPIMetrics('record1,record2');
        Test.stopTest();

        Assert.areNotEqual(null, metrics, 'Should return metrics list');
    }

    @isTest
    static void testGetKPIByNameEmptyName() {
        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            ElaroExecutiveKPIController.getKPIByName('');
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        Assert.isTrue(exceptionThrown, 'Should have thrown exception for blank name');
    }

    @isTest
    static void testGetKPIByNameNull() {
        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            ElaroExecutiveKPIController.getKPIByName(null);
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        Assert.isTrue(exceptionThrown, 'Should have thrown exception for null name');
    }

    @isTest
    static void testGetKPIByNameNotFound() {
        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            ElaroExecutiveKPIController.getKPIByName('nonexistent_kpi_12345');
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        Assert.isTrue(exceptionThrown, 'Should have thrown exception for non-existent KPI');
    }

    @isTest
    static void testGetKPIByNameWithSpecialCharacters() {
        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            // Injection attempt - should be sanitized
            ElaroExecutiveKPIController.getKPIByName('test-kpi; DROP TABLE--');
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        // Should either throw not found or sanitize the input
        Assert.isTrue(exceptionThrown, 'Should have thrown exception or sanitized input');
    }

    @isTest
    static void testGetKPIByNameWithUnderscores() {
        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            ElaroExecutiveKPIController.getKPIByName('test_kpi_name');
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        Assert.isTrue(exceptionThrown, 'Should have thrown exception (not found)');
    }

    @isTest
    static void testKPIMetricClassStructure() {
        ElaroExecutiveKPIController.KPIMetric metric =
            new ElaroExecutiveKPIController.KPIMetric();

        metric.kpiName = 'test';
        metric.label = 'Test Label';
        metric.description = 'Test Description';
        metric.currentValue = 100;
        metric.targetValue = 150;
        metric.greenThreshold = 100;
        metric.yellowThreshold = 75;
        metric.redThreshold = 50;
        metric.formatType = 'number';
        metric.trendDirection = 'higher_is_better';
        metric.status = 'green';
        metric.percentOfTarget = 66.7;
        metric.trendValue = 10;
        metric.hasError = false;
        metric.errorMessage = null;

        Assert.areEqual('test', metric.kpiName, 'KPI name should be set');
        Assert.areEqual('Test Label', metric.label, 'Label should be set');
        Assert.areEqual('Test Description', metric.description, 'Description should be set');
        Assert.areEqual(100, metric.currentValue, 'Current value should be set');
        Assert.areEqual(150, metric.targetValue, 'Target value should be set');
        Assert.areEqual(100, metric.greenThreshold, 'Green threshold should be set');
        Assert.areEqual(75, metric.yellowThreshold, 'Yellow threshold should be set');
        Assert.areEqual(50, metric.redThreshold, 'Red threshold should be set');
        Assert.areEqual('number', metric.formatType, 'Format type should be set');
        Assert.areEqual('higher_is_better', metric.trendDirection, 'Trend direction should be set');
        Assert.areEqual('green', metric.status, 'Status should be set');
        Assert.areEqual(66.7, metric.percentOfTarget, 'Percent of target should be set');
        Assert.areEqual(10, metric.trendValue, 'Trend value should be set');
        Assert.areEqual(false, metric.hasError, 'Has error should be false');
        Assert.areEqual(null, metric.errorMessage, 'Error message should be null');
    }

    @isTest
    static void testKPIMetricWithError() {
        ElaroExecutiveKPIController.KPIMetric metric =
            new ElaroExecutiveKPIController.KPIMetric();

        metric.kpiName = 'error_kpi';
        metric.label = 'Error KPI';
        metric.hasError = true;
        metric.errorMessage = 'Unable to calculate metric';

        Assert.areEqual('error_kpi', metric.kpiName, 'KPI name should be set');
        Assert.areEqual(true, metric.hasError, 'Has error should be true');
        Assert.areEqual('Unable to calculate metric', metric.errorMessage, 'Error message should be set');
    }

    @isTest
    static void testKPIMetricCurrencyFormat() {
        ElaroExecutiveKPIController.KPIMetric metric =
            new ElaroExecutiveKPIController.KPIMetric();

        metric.kpiName = 'revenue';
        metric.label = 'Total Revenue';
        metric.currentValue = 1500000;
        metric.formatType = 'currency';

        Assert.areEqual('currency', metric.formatType, 'Format type should be currency');
    }

    @isTest
    static void testKPIMetricPercentFormat() {
        ElaroExecutiveKPIController.KPIMetric metric =
            new ElaroExecutiveKPIController.KPIMetric();

        metric.kpiName = 'conversion_rate';
        metric.label = 'Conversion Rate';
        metric.currentValue = 25.5;
        metric.formatType = 'percent';

        Assert.areEqual('percent', metric.formatType, 'Format type should be percent');
    }

    @isTest
    static void testKPIMetricDaysFormat() {
        ElaroExecutiveKPIController.KPIMetric metric =
            new ElaroExecutiveKPIController.KPIMetric();

        metric.kpiName = 'cycle_time';
        metric.label = 'Average Cycle Time';
        metric.currentValue = 14.5;
        metric.formatType = 'days';
        metric.trendDirection = 'lower_is_better';

        Assert.areEqual('days', metric.formatType, 'Format type should be days');
        Assert.areEqual('lower_is_better', metric.trendDirection, 'Trend direction should be lower_is_better');
    }

    @isTest
    static void testKPIMetricAllStatuses() {
        // Test green status
        ElaroExecutiveKPIController.KPIMetric greenMetric =
            new ElaroExecutiveKPIController.KPIMetric();
        greenMetric.status = 'green';
        Assert.areEqual('green', greenMetric.status, 'Status should be green');

        // Test yellow status
        ElaroExecutiveKPIController.KPIMetric yellowMetric =
            new ElaroExecutiveKPIController.KPIMetric();
        yellowMetric.status = 'yellow';
        Assert.areEqual('yellow', yellowMetric.status, 'Status should be yellow');

        // Test red status
        ElaroExecutiveKPIController.KPIMetric redMetric =
            new ElaroExecutiveKPIController.KPIMetric();
        redMetric.status = 'red';
        Assert.areEqual('red', redMetric.status, 'Status should be red');

        // Test unknown status
        ElaroExecutiveKPIController.KPIMetric unknownMetric =
            new ElaroExecutiveKPIController.KPIMetric();
        unknownMetric.status = 'unknown';
        Assert.areEqual('unknown', unknownMetric.status, 'Status should be unknown');
    }

    @isTest
    static void testKPIMetricNullValues() {
        ElaroExecutiveKPIController.KPIMetric metric =
            new ElaroExecutiveKPIController.KPIMetric();

        // Test with null values
        metric.kpiName = 'null_test';
        metric.currentValue = null;
        metric.targetValue = null;
        metric.percentOfTarget = null;
        metric.trendValue = null;

        Assert.areEqual('null_test', metric.kpiName, 'KPI name should be set');
        Assert.areEqual(null, metric.currentValue, 'Current value should be null');
        Assert.areEqual(null, metric.targetValue, 'Target value should be null');
    }
}
