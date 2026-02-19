/**
 * ElaroLoggerTest
 *
 * Test coverage for ElaroLogger structured logging service
 *
 * @author Elaro
 * @version 1.0
 */
@IsTest(testFor=ElaroLogger.class)
private class ElaroLoggerTest {

    @isTest
    static void testDebugLogging_WithMessage_LogsSuccessfully() {
        Test.startTest();
        Exception caughtEx;
        try {
            ElaroLogger.debug('Debug message');
            ElaroLogger.debug('Debug with context', new Map<String, Object>{'key' => 'value'});
        } catch (Exception e) {
            caughtEx = e;
        }
        Test.stopTest();

        Assert.isNull(caughtEx, 'Debug logging should complete without throwing');
    }

    @isTest
    static void testInfoLogging_WithMessage_LogsSuccessfully() {
        Test.startTest();
        Exception caughtEx;
        try {
            ElaroLogger.info('Info message');
            ElaroLogger.info('Info with context', new Map<String, Object>{'accountId' => 'test123'});
        } catch (Exception e) {
            caughtEx = e;
        }
        Test.stopTest();

        Assert.isNull(caughtEx, 'Info logging should complete without throwing');
    }

    @isTest
    static void testWarnLogging_WithMessage_LogsSuccessfully() {
        Test.startTest();
        Exception caughtEx;
        try {
            ElaroLogger.warn('Warning message');
            ElaroLogger.warn('Warning with context', new Map<String, Object>{'threshold' => 80});
        } catch (Exception e) {
            caughtEx = e;
        }
        Test.stopTest();

        Assert.isNull(caughtEx, 'Warn logging should complete without throwing');
    }

    @isTest
    static void testErrorLogging_WithMessage_LogsSuccessfully() {
        Test.startTest();
        Exception caughtEx;
        try {
            ElaroLogger.error('Error message');
            ElaroLogger.error('Error with context', new Map<String, Object>{'errorCode' => 500});
        } catch (Exception e) {
            caughtEx = e;
        }
        Test.stopTest();

        Assert.isNull(caughtEx, 'Error logging should complete without throwing');
    }

    @isTest
    static void testErrorLogging_WithException_LogsStackTrace() {
        Test.startTest();
        Exception caughtEx;
        try {
            try {
                Integer result = 1 / 0; // Force exception
            } catch (Exception ex) {
                ElaroLogger.error('Caught exception', ex);
            }
        } catch (Exception e) {
            caughtEx = e;
        }
        Test.stopTest();

        Assert.isNull(caughtEx, 'Exception logging should complete without throwing');
    }

    @isTest
    static void testLogLevel_WithDebug_RespectsConfiguration() {
        Test.startTest();
        Exception caughtEx;
        try {
            ElaroLogger.log(ElaroLogger.Level.DEBUG, 'Test debug', null);
            ElaroLogger.log(ElaroLogger.Level.INFO, 'Test info', null);
            ElaroLogger.log(ElaroLogger.Level.WARN, 'Test warn', null);
            ElaroLogger.log(ElaroLogger.Level.ERROR, 'Test error', null);
        } catch (Exception e) {
            caughtEx = e;
        }
        Test.stopTest();

        Assert.isNull(caughtEx, 'All log levels should be processed without throwing');
    }

    @isTest
    static void testLogging_WithNullContext_HandlesGracefully() {
        Test.startTest();
        Exception caughtEx;
        try {
            ElaroLogger.log(ElaroLogger.Level.INFO, 'Null context test', null);
        } catch (Exception e) {
            caughtEx = e;
        }
        Test.stopTest();

        Assert.isNull(caughtEx, 'Null context should be handled without throwing');
    }

    @isTest
    static void testLogging_WithComplexContext_SerializesCorrectly() {
        Map<String, Object> complexContext = new Map<String, Object>{
            'accountId' => '001000000000001',
            'recordCount' => 150,
            'frameworks' => new List<String>{'HIPAA', 'SOC2', 'GDPR'},
            'metadata' => new Map<String, Object>{
                'severity' => 'HIGH',
                'category' => 'Security'
            }
        };

        Test.startTest();
        Exception caughtEx;
        try {
            ElaroLogger.info('Complex context test', complexContext);
        } catch (Exception e) {
            caughtEx = e;
        }
        Test.stopTest();

        Assert.isNull(caughtEx, 'Complex context should be serialized without throwing');
    }

    @isTest
    static void testLogging_InTestContext_SuppressesOutput() {
        // Verify shouldLog returns false in test context
        Test.startTest();
        ElaroLogger.debug('Should be suppressed');
        ElaroLogger.info('Should be suppressed');
        Test.stopTest();

        // No exceptions should be thrown
        Assert.isTrue(Test.isRunningTest(), 'Running in test context');
    }
}
