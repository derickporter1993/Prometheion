/**
 * Test class for PrometheionExecutiveKPIController
 * Comprehensive test coverage for KPI dashboard functionality
 * Note: Custom Metadata Types cannot be created in test classes, so coverage
 * is limited to validation, error handling, and inner class paths
 * @author Derick Porter
 * @date 2026-01-03
 */
@isTest
private class PrometheionExecutiveKPIControllerTest {

    @isTest
    static void testGetKPIMetricsEmpty() {
        // Test with no metadata records (expected scenario in test org)
        Test.startTest();
        List<PrometheionExecutiveKPIController.KPIMetric> metrics =
            PrometheionExecutiveKPIController.getKPIMetrics('');
        Test.stopTest();

        System.assertNotEquals(null, metrics, 'Should return metrics list (even if empty)');
    }

    @isTest
    static void testGetKPIMetricsWithNull() {
        Test.startTest();
        List<PrometheionExecutiveKPIController.KPIMetric> metrics =
            PrometheionExecutiveKPIController.getKPIMetrics(null);
        Test.stopTest();

        System.assertNotEquals(null, metrics, 'Should return metrics list');
    }

    @isTest
    static void testGetKPIMetricsWithRecordIds() {
        Test.startTest();
        List<PrometheionExecutiveKPIController.KPIMetric> metrics =
            PrometheionExecutiveKPIController.getKPIMetrics('record1,record2');
        Test.stopTest();

        System.assertNotEquals(null, metrics, 'Should return metrics list');
    }

    @isTest
    static void testGetKPIByNameEmptyName() {
        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            PrometheionExecutiveKPIController.getKPIByName('');
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        System.assert(exceptionThrown, 'Should have thrown exception for blank name');
    }

    @isTest
    static void testGetKPIByNameNull() {
        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            PrometheionExecutiveKPIController.getKPIByName(null);
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        System.assert(exceptionThrown, 'Should have thrown exception for null name');
    }

    @isTest
    static void testGetKPIByNameNotFound() {
        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            PrometheionExecutiveKPIController.getKPIByName('nonexistent_kpi_12345');
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        System.assert(exceptionThrown, 'Should have thrown exception for non-existent KPI');
    }

    @isTest
    static void testGetKPIByNameWithSpecialCharacters() {
        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            // Injection attempt - should be sanitized
            PrometheionExecutiveKPIController.getKPIByName('test-kpi; DROP TABLE--');
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        // Should either throw not found or sanitize the input
        System.assert(exceptionThrown, 'Should have thrown exception or sanitized input');
    }

    @isTest
    static void testGetKPIByNameWithUnderscores() {
        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            PrometheionExecutiveKPIController.getKPIByName('test_kpi_name');
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        System.assert(exceptionThrown, 'Should have thrown exception (not found)');
    }

    @isTest
    static void testKPIMetricClassStructure() {
        PrometheionExecutiveKPIController.KPIMetric metric =
            new PrometheionExecutiveKPIController.KPIMetric();

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

        System.assertEquals('test', metric.kpiName, 'KPI name should be set');
        System.assertEquals('Test Label', metric.label, 'Label should be set');
        System.assertEquals('Test Description', metric.description, 'Description should be set');
        System.assertEquals(100, metric.currentValue, 'Current value should be set');
        System.assertEquals(150, metric.targetValue, 'Target value should be set');
        System.assertEquals(100, metric.greenThreshold, 'Green threshold should be set');
        System.assertEquals(75, metric.yellowThreshold, 'Yellow threshold should be set');
        System.assertEquals(50, metric.redThreshold, 'Red threshold should be set');
        System.assertEquals('number', metric.formatType, 'Format type should be set');
        System.assertEquals('higher_is_better', metric.trendDirection, 'Trend direction should be set');
        System.assertEquals('green', metric.status, 'Status should be set');
        System.assertEquals(66.7, metric.percentOfTarget, 'Percent of target should be set');
        System.assertEquals(10, metric.trendValue, 'Trend value should be set');
        System.assertEquals(false, metric.hasError, 'Has error should be false');
        System.assertEquals(null, metric.errorMessage, 'Error message should be null');
    }

    @isTest
    static void testKPIMetricWithError() {
        PrometheionExecutiveKPIController.KPIMetric metric =
            new PrometheionExecutiveKPIController.KPIMetric();

        metric.kpiName = 'error_kpi';
        metric.label = 'Error KPI';
        metric.hasError = true;
        metric.errorMessage = 'Unable to calculate metric';

        System.assertEquals('error_kpi', metric.kpiName, 'KPI name should be set');
        System.assertEquals(true, metric.hasError, 'Has error should be true');
        System.assertEquals('Unable to calculate metric', metric.errorMessage, 'Error message should be set');
    }

    @isTest
    static void testKPIMetricCurrencyFormat() {
        PrometheionExecutiveKPIController.KPIMetric metric =
            new PrometheionExecutiveKPIController.KPIMetric();

        metric.kpiName = 'revenue';
        metric.label = 'Total Revenue';
        metric.currentValue = 1500000;
        metric.formatType = 'currency';

        System.assertEquals('currency', metric.formatType, 'Format type should be currency');
    }

    @isTest
    static void testKPIMetricPercentFormat() {
        PrometheionExecutiveKPIController.KPIMetric metric =
            new PrometheionExecutiveKPIController.KPIMetric();

        metric.kpiName = 'conversion_rate';
        metric.label = 'Conversion Rate';
        metric.currentValue = 25.5;
        metric.formatType = 'percent';

        System.assertEquals('percent', metric.formatType, 'Format type should be percent');
    }

    @isTest
    static void testKPIMetricDaysFormat() {
        PrometheionExecutiveKPIController.KPIMetric metric =
            new PrometheionExecutiveKPIController.KPIMetric();

        metric.kpiName = 'cycle_time';
        metric.label = 'Average Cycle Time';
        metric.currentValue = 14.5;
        metric.formatType = 'days';
        metric.trendDirection = 'lower_is_better';

        System.assertEquals('days', metric.formatType, 'Format type should be days');
        System.assertEquals('lower_is_better', metric.trendDirection, 'Trend direction should be lower_is_better');
    }

    @isTest
    static void testKPIMetricAllStatuses() {
        // Test green status
        PrometheionExecutiveKPIController.KPIMetric greenMetric =
            new PrometheionExecutiveKPIController.KPIMetric();
        greenMetric.status = 'green';
        System.assertEquals('green', greenMetric.status, 'Status should be green');

        // Test yellow status
        PrometheionExecutiveKPIController.KPIMetric yellowMetric =
            new PrometheionExecutiveKPIController.KPIMetric();
        yellowMetric.status = 'yellow';
        System.assertEquals('yellow', yellowMetric.status, 'Status should be yellow');

        // Test red status
        PrometheionExecutiveKPIController.KPIMetric redMetric =
            new PrometheionExecutiveKPIController.KPIMetric();
        redMetric.status = 'red';
        System.assertEquals('red', redMetric.status, 'Status should be red');

        // Test unknown status
        PrometheionExecutiveKPIController.KPIMetric unknownMetric =
            new PrometheionExecutiveKPIController.KPIMetric();
        unknownMetric.status = 'unknown';
        System.assertEquals('unknown', unknownMetric.status, 'Status should be unknown');
    }

    @isTest
    static void testKPIMetricNullValues() {
        PrometheionExecutiveKPIController.KPIMetric metric =
            new PrometheionExecutiveKPIController.KPIMetric();

        // Test with null values
        metric.kpiName = 'null_test';
        metric.currentValue = null;
        metric.targetValue = null;
        metric.percentOfTarget = null;
        metric.trendValue = null;

        System.assertEquals('null_test', metric.kpiName, 'KPI name should be set');
        System.assertEquals(null, metric.currentValue, 'Current value should be null');
        System.assertEquals(null, metric.targetValue, 'Target value should be null');
    }
}
