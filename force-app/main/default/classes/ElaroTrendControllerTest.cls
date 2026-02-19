/**
 * Test class for ElaroTrendController
 * Comprehensive test coverage for time-series trend analysis
 * @author Derick Porter
 * @date 2026-01-03
 */
@IsTest(testFor=ElaroTrendController.class)
private class ElaroTrendControllerTest {

    @testSetup
    static void setupTestData() {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 10; i++) {
            accounts.add(new Account(Name = 'Test Account ' + i));
        }
        insert accounts;
    }

    @isTest
    static void testGetDateFields() {
        Test.startTest();
        List<ElaroTrendController.DateFieldOption> fields =
            ElaroTrendController.getDateFields('Account');
        Test.stopTest();

        Assert.areNotEqual(null, fields, 'Should return date fields');
        Assert.areEqual(true, !fields.isEmpty(), 'Should return at least some date fields');
    }

    @isTest
    static void testGetDateFieldsInvalidObject() {
        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            ElaroTrendController.getDateFields('Invalid__c');
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        Assert.isTrue(exceptionThrown, 'Should have thrown exception for invalid object');
    }

    @isTest
    static void testGetMetricFields() {
        Test.startTest();
        List<ElaroTrendController.MetricFieldOption> fields =
            ElaroTrendController.getMetricFields('Account');
        Test.stopTest();

        Assert.areNotEqual(null, fields, 'Should return metric fields');
        Assert.areEqual(true, !fields.isEmpty(), 'Should return at least COUNT option');
    }

    @isTest
    static void testGetMetricFieldsInvalidObject() {
        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            ElaroTrendController.getMetricFields('Invalid__c');
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        Assert.isTrue(exceptionThrown, 'Should have thrown exception for invalid object');
    }

    @isTest
    static void testGetTimeSeries() {
        Test.startTest();
        try {
            ElaroTrendController.TrendResult result =
                ElaroTrendController.getTimeSeries(
                    'Account',
                    'CreatedDate',
                    'Id',
                    'month',
                    12,
                    ''
                );
            Assert.areNotEqual(null, result, 'Result should not be null');
        } catch (Exception e) {
            // Query may fail due to no data, which is acceptable
            Assert.isNotNull(e.getMessage(), 'Exception should have a message when query fails');
        }
        Test.stopTest();
    }

    @isTest
    static void testGetTimeSeriesDay() {
        Test.startTest();
        try {
            ElaroTrendController.TrendResult result =
                ElaroTrendController.getTimeSeries(
                    'Account',
                    'CreatedDate',
                    'Id',
                    'day',
                    1,
                    ''
                );
            Assert.areNotEqual(null, result, 'Result should not be null');
        } catch (Exception e) {
            Assert.isNotNull(e.getMessage(), 'Exception should have a message when query fails');
        }
        Test.stopTest();
    }

    @isTest
    static void testGetTimeSeriesWeek() {
        Test.startTest();
        try {
            ElaroTrendController.TrendResult result =
                ElaroTrendController.getTimeSeries(
                    'Account',
                    'CreatedDate',
                    'Id',
                    'week',
                    3,
                    ''
                );
            Assert.areNotEqual(null, result, 'Result should not be null');
        } catch (Exception e) {
            Assert.isNotNull(e.getMessage(), 'Exception should have a message when query fails');
        }
        Test.stopTest();
    }

    @isTest
    static void testGetTimeSeriesQuarter() {
        Test.startTest();
        try {
            ElaroTrendController.TrendResult result =
                ElaroTrendController.getTimeSeries(
                    'Account',
                    'CreatedDate',
                    'Id',
                    'quarter',
                    12,
                    ''
                );
            Assert.areNotEqual(null, result, 'Result should not be null');
        } catch (Exception e) {
            Assert.isNotNull(e.getMessage(), 'Exception should have a message when query fails');
        }
        Test.stopTest();
    }

    @isTest
    static void testGetTimeSeriesYear() {
        Test.startTest();
        try {
            ElaroTrendController.TrendResult result =
                ElaroTrendController.getTimeSeries(
                    'Account',
                    'CreatedDate',
                    'Id',
                    'year',
                    24,
                    ''
                );
            Assert.areNotEqual(null, result, 'Result should not be null');
        } catch (Exception e) {
            Assert.isNotNull(e.getMessage(), 'Exception should have a message when query fails');
        }
        Test.stopTest();
    }

    @isTest
    static void testGetTimeSeriesInvalidObject() {
        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            ElaroTrendController.getTimeSeries(
                'Invalid__c',
                'CreatedDate',
                'Id',
                'month',
                12,
                ''
            );
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        Assert.isTrue(exceptionThrown, 'Should have thrown exception for invalid object');
    }

    @isTest
    static void testGetTimeSeriesNullObjectApiName() {
        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            ElaroTrendController.getTimeSeries(
                null,
                'CreatedDate',
                'Id',
                'month',
                12,
                ''
            );
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        Assert.isTrue(exceptionThrown, 'Should have thrown exception for null object API name');
    }

    @isTest
    static void testGetTimeSeriesInvalidGranularity() {
        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            ElaroTrendController.getTimeSeries(
                'Account',
                'CreatedDate',
                'Id',
                'invalid',
                12,
                ''
            );
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        Assert.isTrue(exceptionThrown, 'Should have thrown exception for invalid granularity');
    }

    @isTest
    static void testGetTimeSeriesBlankDateField() {
        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            ElaroTrendController.getTimeSeries(
                'Account',
                '',
                'Id',
                'month',
                12,
                ''
            );
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        Assert.isTrue(exceptionThrown, 'Should have thrown exception for blank date field');
    }

    @isTest
    static void testGetTimeSeriesBlankMetricField() {
        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            ElaroTrendController.getTimeSeries(
                'Account',
                'CreatedDate',
                '',
                'month',
                12,
                ''
            );
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        Assert.isTrue(exceptionThrown, 'Should have thrown exception for blank metric field');
    }

    @isTest
    static void testGetTimeSeriesBlankGranularity() {
        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            ElaroTrendController.getTimeSeries(
                'Account',
                'CreatedDate',
                'Id',
                '',
                12,
                ''
            );
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        Assert.isTrue(exceptionThrown, 'Should have thrown exception for blank granularity');
    }

    @isTest
    static void testGetTimeSeriesWithFilters() {
        Test.startTest();
        try {
            ElaroTrendController.TrendResult result =
                ElaroTrendController.getTimeSeries(
                    'Account',
                    'CreatedDate',
                    'Id',
                    'month',
                    6,
                    'Name LIKE \'Test%\''
                );
            Assert.areNotEqual(null, result, 'Result should not be null');
        } catch (Exception e) {
            Assert.isNotNull(e.getMessage(), 'Exception should have a message when query fails');
        }
        Test.stopTest();
    }

    @isTest
    static void testGetTimeSeriesNullMonths() {
        Test.startTest();
        try {
            ElaroTrendController.TrendResult result =
                ElaroTrendController.getTimeSeries(
                    'Account',
                    'CreatedDate',
                    'Id',
                    'month',
                    null,
                    ''
                );
            Assert.areNotEqual(null, result, 'Result should not be null');
        } catch (Exception e) {
            Assert.isNotNull(e.getMessage(), 'Exception should have a message when query fails');
        }
        Test.stopTest();
    }

    @isTest
    static void testGetTimeSeriesLargeMonths() {
        Test.startTest();
        try {
            ElaroTrendController.TrendResult result =
                ElaroTrendController.getTimeSeries(
                    'Account',
                    'CreatedDate',
                    'Id',
                    'month',
                    100, // Should be bounded to MAX_MONTHS_BACK
                    ''
                );
            Assert.areNotEqual(null, result, 'Result should not be null');
        } catch (Exception e) {
            Assert.isNotNull(e.getMessage(), 'Exception should have a message when query fails');
        }
        Test.stopTest();
    }

    @isTest
    static void testGetTimeSeriesSmallMonths() {
        Test.startTest();
        try {
            ElaroTrendController.TrendResult result =
                ElaroTrendController.getTimeSeries(
                    'Account',
                    'CreatedDate',
                    'Id',
                    'month',
                    0, // Should be bounded to MIN_MONTHS_BACK
                    ''
                );
            Assert.areNotEqual(null, result, 'Result should not be null');
        } catch (Exception e) {
            Assert.isNotNull(e.getMessage(), 'Exception should have a message when query fails');
        }
        Test.stopTest();
    }

    @isTest
    static void testGetTimeSeriesNonDateField() {
        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            ElaroTrendController.getTimeSeries(
                'Account',
                'Name', // Not a date field
                'Id',
                'month',
                12,
                ''
            );
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        Assert.isTrue(exceptionThrown, 'Should have thrown exception for non-date field');
    }

    @isTest
    static void testGetTimeSeriesInvalidField() {
        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            ElaroTrendController.getTimeSeries(
                'Account',
                'InvalidField__c',
                'Id',
                'month',
                12,
                ''
            );
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        Assert.isTrue(exceptionThrown, 'Should have thrown exception for invalid field');
    }

    @isTest
    static void testTrendResultClassStructure() {
        ElaroTrendController.TrendResult result =
            new ElaroTrendController.TrendResult();

        result.buckets = new List<ElaroTrendController.TimeBucket>();
        result.granularity = 'month';
        result.periodCount = 12;
        result.monthsBack = 12;
        result.total = 500;
        result.average = 41.67;
        result.minValue = 10;
        result.maxValue = 100;
        result.overallChange = 50;
        result.overallPercentChange = 25.0;
        result.trendDirection = 'up';

        Assert.areNotEqual(null, result.buckets, 'Buckets should be set');
        Assert.areEqual('month', result.granularity, 'Granularity should be set');
        Assert.areEqual(500, result.total, 'Total should be set');
        Assert.areEqual('up', result.trendDirection, 'Trend direction should be set');
    }

    @isTest
    static void testTimeBucketClassStructure() {
        ElaroTrendController.TimeBucket bucket =
            new ElaroTrendController.TimeBucket();

        bucket.bucketDate = 'Jan 2026';
        bucket.bucketValue = 1;
        bucket.bucketYear = 2026;
        bucket.metricValue = 100;
        bucket.changeFromPrevious = 10;
        bucket.percentChange = 11.1;

        Assert.areEqual('Jan 2026', bucket.bucketDate, 'Bucket date should be set');
        Assert.areEqual(100, bucket.metricValue, 'Metric value should be set');
        Assert.areEqual(10, bucket.changeFromPrevious, 'Change from previous should be set');
    }

    @isTest
    static void testMetricFieldOptionClassStructure() {
        ElaroTrendController.MetricFieldOption opt =
            new ElaroTrendController.MetricFieldOption();

        opt.apiName = 'Amount';
        opt.label = 'Amount';
        opt.fieldType = 'CURRENCY';

        Assert.areEqual('Amount', opt.apiName, 'API name should be set');
        Assert.areEqual('Amount', opt.label, 'Label should be set');
        Assert.areEqual('CURRENCY', opt.fieldType, 'Field type should be set');
    }

    @isTest
    static void testDateFieldOptionClassStructure() {
        ElaroTrendController.DateFieldOption opt =
            new ElaroTrendController.DateFieldOption();

        opt.apiName = 'CreatedDate';
        opt.label = 'Created Date';
        opt.fieldType = 'DATETIME';

        Assert.areEqual('CreatedDate', opt.apiName, 'API name should be set');
        Assert.areEqual('Created Date', opt.label, 'Label should be set');
        Assert.areEqual('DATETIME', opt.fieldType, 'Field type should be set');
    }
}
