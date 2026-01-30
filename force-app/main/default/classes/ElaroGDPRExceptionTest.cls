/**
 * ElaroGDPRExceptionTest - Test coverage for GDPR exception class
 *
 * @author Elaro
 * @version 1.0
 */
@IsTest
private class ElaroGDPRExceptionTest {

    @IsTest
    static void testExceptionWithMessage() {
        String errorMessage = 'GDPR data erasure failed for contact';

        Test.startTest();

        try {
            throw new ElaroGDPRException(errorMessage);
        } catch (ElaroGDPRException e) {
            System.assertEquals(errorMessage, e.getMessage(), 'Exception message should match');
        }

        Test.stopTest();
    }

    @IsTest
    static void testExceptionWithCause() {
        Exception cause = new DmlException('Original DML error');
        String errorMessage = 'GDPR operation failed';

        Test.startTest();

        try {
            throw new ElaroGDPRException(errorMessage, cause);
        } catch (ElaroGDPRException e) {
            System.assertEquals(errorMessage, e.getMessage(), 'Exception message should match');
            System.assertEquals(cause, e.getCause(), 'Cause should be preserved');
        }

        Test.stopTest();
    }

    @IsTest
    static void testExceptionInstantiation() {
        Test.startTest();

        ElaroGDPRException e = new ElaroGDPRException();

        Test.stopTest();

        System.assertNotEquals(null, e, 'Exception should be instantiated');
    }

    @IsTest
    static void testExceptionInTryCatch() {
        Boolean exceptionCaught = false;

        Test.startTest();

        try {
            // Simulate a GDPR operation that fails
            simulateGDPRFailure();
        } catch (ElaroGDPRException e) {
            exceptionCaught = true;
            System.assert(e.getMessage().contains('Contact not found'), 'Message should indicate contact not found');
        }

        Test.stopTest();

        System.assert(exceptionCaught, 'Exception should have been caught');
    }

    @IsTest
    static void testExceptionTypeCheck() {
        Test.startTest();

        ElaroGDPRException gdprEx = new ElaroGDPRException('Test');

        Test.stopTest();

        System.assert(gdprEx instanceof Exception, 'Should be an Exception');
        System.assert(gdprEx instanceof ElaroGDPRException, 'Should be a ElaroGDPRException');
    }

    @IsTest
    static void testExceptionStackTrace() {
        Test.startTest();

        try {
            throw new ElaroGDPRException('Stack trace test');
        } catch (ElaroGDPRException e) {
            String stackTrace = e.getStackTraceString();
            System.assertNotEquals(null, stackTrace, 'Stack trace should not be null');
            System.assert(stackTrace.length() > 0, 'Stack trace should have content');
        }

        Test.stopTest();
    }

    @IsTest
    static void testExceptionChaining() {
        Test.startTest();

        try {
            try {
                throw new QueryException('Record not found');
            } catch (QueryException qe) {
                throw new ElaroGDPRException('GDPR lookup failed', qe);
            }
        } catch (ElaroGDPRException e) {
            System.assertEquals('GDPR lookup failed', e.getMessage(), 'Outer message should match');
            System.assertNotEquals(null, e.getCause(), 'Should have a cause');
            System.assert(e.getCause() instanceof QueryException, 'Cause should be QueryException');
        }

        Test.stopTest();
    }

    // Helper method to simulate GDPR failure
    private static void simulateGDPRFailure() {
        throw new ElaroGDPRException('Contact not found for erasure request');
    }
}
