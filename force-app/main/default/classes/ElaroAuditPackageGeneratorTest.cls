/**
 * Tests for {@link ElaroAuditPackageGenerator} covering input validation,
 * null/empty handling, date validation, and error paths.
 *
 * @author Elaro Team
 * @since v3.1.0 (Spring '26)
 * @group Compliance Framework
 * @see ElaroAuditPackageGenerator
 */
@IsTest(testFor=ElaroAuditPackageGenerator.class)
private class ElaroAuditPackageGeneratorTest {

    @TestSetup
    static void setup() {
        // Create test data if needed by future methods
    }

    @IsTest
    static void shouldThrowWhenFrameworkIsNull() {
        Test.startTest();
        try {
            ElaroAuditPackageGenerator.generateAuditPackage(
                null, 'Test Package', Date.today().addDays(-30), Date.today()
            );
            Assert.fail('Should have thrown AuraHandledException for null framework');
        } catch (AuraHandledException e) {
            Assert.isTrue(
                e.getMessage().contains('Framework'),
                'Error should mention Framework: ' + e.getMessage()
            );
        }
        Test.stopTest();
    }

    @IsTest
    static void shouldThrowWhenFrameworkIsBlank() {
        Test.startTest();
        try {
            ElaroAuditPackageGenerator.generateAuditPackage(
                '   ', 'Test Package', Date.today().addDays(-30), Date.today()
            );
            Assert.fail('Should have thrown AuraHandledException for blank framework');
        } catch (AuraHandledException e) {
            Assert.isTrue(
                e.getMessage().contains('Framework'),
                'Error should mention Framework: ' + e.getMessage()
            );
        }
        Test.stopTest();
    }

    @IsTest
    static void shouldThrowWhenPackageNameIsNull() {
        Test.startTest();
        try {
            ElaroAuditPackageGenerator.generateAuditPackage(
                'SOC2', null, Date.today().addDays(-30), Date.today()
            );
            Assert.fail('Should have thrown AuraHandledException for null package name');
        } catch (AuraHandledException e) {
            Assert.isTrue(
                e.getMessage().contains('Package name'),
                'Error should mention Package name: ' + e.getMessage()
            );
        }
        Test.stopTest();
    }

    @IsTest
    static void shouldThrowWhenPackageNameIsBlank() {
        Test.startTest();
        try {
            ElaroAuditPackageGenerator.generateAuditPackage(
                'SOC2', '', Date.today().addDays(-30), Date.today()
            );
            Assert.fail('Should have thrown AuraHandledException for blank package name');
        } catch (AuraHandledException e) {
            Assert.isTrue(
                e.getMessage().contains('Package name'),
                'Error should mention Package name: ' + e.getMessage()
            );
        }
        Test.stopTest();
    }

    @IsTest
    static void shouldThrowWhenStartDateIsNull() {
        Test.startTest();
        try {
            ElaroAuditPackageGenerator.generateAuditPackage(
                'HIPAA', 'Test Package', null, Date.today()
            );
            Assert.fail('Should have thrown AuraHandledException for null start date');
        } catch (AuraHandledException e) {
            Assert.isTrue(
                e.getMessage().contains('date'),
                'Error should mention date: ' + e.getMessage()
            );
        }
        Test.stopTest();
    }

    @IsTest
    static void shouldThrowWhenEndDateIsNull() {
        Test.startTest();
        try {
            ElaroAuditPackageGenerator.generateAuditPackage(
                'HIPAA', 'Test Package', Date.today().addDays(-30), null
            );
            Assert.fail('Should have thrown AuraHandledException for null end date');
        } catch (AuraHandledException e) {
            Assert.isTrue(
                e.getMessage().contains('date'),
                'Error should mention date: ' + e.getMessage()
            );
        }
        Test.stopTest();
    }

    @IsTest
    static void shouldThrowWhenStartDateAfterEndDate() {
        Test.startTest();
        try {
            ElaroAuditPackageGenerator.generateAuditPackage(
                'SOC2', 'Test Package', Date.today(), Date.today().addDays(-30)
            );
            Assert.fail('Should have thrown AuraHandledException when start date is after end date');
        } catch (AuraHandledException e) {
            Assert.isTrue(
                e.getMessage().contains('Start date'),
                'Error should mention Start date: ' + e.getMessage()
            );
        }
        Test.stopTest();
    }

    @IsTest
    static void shouldThrowWhenBothDatesAreNull() {
        Test.startTest();
        try {
            ElaroAuditPackageGenerator.generateAuditPackage(
                'GDPR', 'Test Package', null, null
            );
            Assert.fail('Should have thrown AuraHandledException for null dates');
        } catch (AuraHandledException e) {
            Assert.isTrue(
                e.getMessage().contains('date'),
                'Error should mention date requirement: ' + e.getMessage()
            );
        }
        Test.stopTest();
    }
}
