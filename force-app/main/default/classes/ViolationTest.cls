/**
 * ViolationTest - Test coverage for Violation data class
 *
 * @author Elaro
 * @version 1.0
 */
@IsTest
private class ViolationTest {

    @IsTest
    static void testViolationInstantiation() {
        Test.startTest();

        Violation v = new Violation();

        Test.stopTest();

        System.assertNotEquals(null, v, 'Violation should be instantiated');
    }

    @IsTest
    static void testViolationPropertyAssignment() {
        Violation v = new Violation();

        Test.startTest();

        v.title = 'Test Violation';
        v.description = 'This is a test violation description';
        v.severity = 'High';
        v.remediation = 'Fix the issue by updating configuration';
        v.entityId = '001XXXXXXXXXXXX';
        v.riskScore = 8.5;

        Test.stopTest();

        System.assertEquals('Test Violation', v.title, 'Title should be set');
        System.assertEquals('This is a test violation description', v.description, 'Description should be set');
        System.assertEquals('High', v.severity, 'Severity should be set');
        System.assertEquals('Fix the issue by updating configuration', v.remediation, 'Remediation should be set');
        System.assertEquals('001XXXXXXXXXXXX', v.entityId, 'EntityId should be set');
        System.assertEquals(8.5, v.riskScore, 'RiskScore should be set');
    }

    @IsTest
    static void testViolationNullValues() {
        Violation v = new Violation();

        Test.startTest();

        // All properties should be null by default
        System.assertEquals(null, v.title, 'Title should be null by default');
        System.assertEquals(null, v.description, 'Description should be null by default');
        System.assertEquals(null, v.severity, 'Severity should be null by default');
        System.assertEquals(null, v.remediation, 'Remediation should be null by default');
        System.assertEquals(null, v.entityId, 'EntityId should be null by default');
        System.assertEquals(null, v.riskScore, 'RiskScore should be null by default');

        Test.stopTest();
    }

    @IsTest
    static void testViolationInList() {
        List<Violation> violations = new List<Violation>();

        Test.startTest();

        for (Integer i = 0; i < 5; i++) {
            Violation v = new Violation();
            v.title = 'Violation ' + i;
            v.severity = Math.mod(i, 2) == 0 ? 'High' : 'Medium';
            v.riskScore = i * 2;
            violations.add(v);
        }

        Test.stopTest();

        System.assertEquals(5, violations.size(), 'Should have 5 violations');
        System.assertEquals('Violation 0', violations[0].title, 'First violation title should match');
        System.assertEquals('High', violations[0].severity, 'First violation severity should be High');
    }

    @IsTest
    static void testViolationSerialization() {
        Violation v = new Violation();
        v.title = 'Serialization Test';
        v.description = 'Testing JSON serialization';
        v.severity = 'Critical';
        v.remediation = 'Immediate action required';
        v.entityId = '00DXXXXXXXXXXXX';
        v.riskScore = 10.0;

        Test.startTest();

        String jsonString = JSON.serialize(v);
        Violation deserialized = (Violation) JSON.deserialize(jsonString, Violation.class);

        Test.stopTest();

        System.assertEquals(v.title, deserialized.title, 'Title should survive serialization');
        System.assertEquals(v.severity, deserialized.severity, 'Severity should survive serialization');
        System.assertEquals(v.riskScore, deserialized.riskScore, 'RiskScore should survive serialization');
    }
}
