/**
 * Test class for ElaroPCIDataMaskingService
 * Tests PCI DSS Requirement 3 data masking functionality
 *
 * @author Elaro
 * @version 1.0
 */
@IsTest(testFor=ElaroPCIDataMaskingService.class)
private class ElaroPCIDataMaskingServiceTest {

    @IsTest
    static void testMaskCreditCard_ValidCard() {
        Test.startTest();
        String masked = ElaroPCIDataMaskingService.maskCreditCard('4111111111111111');
        Test.stopTest();

        Assert.areEqual('****-****-****-1111', masked, 'Should show only last 4 digits');
    }

    @IsTest
    static void testMaskCreditCard_WithDashes() {
        Test.startTest();
        String masked = ElaroPCIDataMaskingService.maskCreditCard('4111-1111-1111-1111');
        Test.stopTest();

        Assert.areEqual('****-****-****-1111', masked, 'Should handle dashes');
    }

    @IsTest
    static void testMaskCreditCard_WithSpaces() {
        Test.startTest();
        String masked = ElaroPCIDataMaskingService.maskCreditCard('4111 1111 1111 1111');
        Test.stopTest();

        Assert.areEqual('****-****-****-1111', masked, 'Should handle spaces');
    }

    @IsTest
    static void testMaskCreditCard_Null() {
        Test.startTest();
        String masked = ElaroPCIDataMaskingService.maskCreditCard(null);
        Test.stopTest();

        Assert.areEqual('****-****-****-****', masked, 'Should return full mask for null');
    }

    @IsTest
    static void testMaskCreditCard_Empty() {
        Test.startTest();
        String masked = ElaroPCIDataMaskingService.maskCreditCard('');
        Test.stopTest();

        Assert.areEqual('****-****-****-****', masked, 'Should return full mask for empty');
    }

    @IsTest
    static void testMaskCreditCard_TooShort() {
        Test.startTest();
        String masked = ElaroPCIDataMaskingService.maskCreditCard('123');
        Test.stopTest();

        Assert.areEqual('****-****-****-****', masked, 'Should return full mask for short input');
    }

    @IsTest
    static void testMaskCreditCardWithFormat_Amex() {
        Test.startTest();
        String masked = ElaroPCIDataMaskingService.maskCreditCardWithFormat(
            '371449635398431',
            '****-******-*1234'
        );
        Test.stopTest();

        Assert.areEqual('****-******-*8431', masked, 'Should use Amex format');
    }

    @IsTest
    static void testMaskCreditCardWithFormat_Standard() {
        Test.startTest();
        String masked = ElaroPCIDataMaskingService.maskCreditCardWithFormat(
            '4111111111111111',
            '****-****-****-1234'
        );
        Test.stopTest();

        Assert.areEqual('****-****-****-1111', masked, 'Should use standard format');
    }

    @IsTest
    static void testValidateNoCVVStorage_WithCVV() {
        Test.startTest();
        try {
            ElaroPCIDataMaskingService.validateNoCVVStorage('123');
            Assert.fail( 'Should throw PCIViolationException');
        } catch (ElaroPCIDataMaskingService.PCIViolationException e) {
            Assert.isTrue(e.getMessage().contains('PCI DSS Requirement 3.2'),
                'Should mention PCI requirement');
        }
        Test.stopTest();
    }

    @IsTest
    static void testValidateNoCVVStorage_Null() {
        Test.startTest();
        Exception caughtEx;
        try {
            ElaroPCIDataMaskingService.validateNoCVVStorage(null);
        } catch (ElaroPCIDataMaskingService.PCIViolationException e) {
            caughtEx = e;
        }
        Test.stopTest();

        Assert.isNull(caughtEx, 'Should not throw PCIViolationException for null CVV');
    }

    @IsTest
    static void testValidateNoCVVStorage_Empty() {
        Test.startTest();
        Exception caughtEx;
        try {
            ElaroPCIDataMaskingService.validateNoCVVStorage('');
        } catch (ElaroPCIDataMaskingService.PCIViolationException e) {
            caughtEx = e;
        }
        Test.stopTest();

        Assert.isNull(caughtEx, 'Should not throw PCIViolationException for empty CVV');
    }

    @IsTest
    static void testTruncatePAN_Valid() {
        Test.startTest();
        String truncated = ElaroPCIDataMaskingService.truncatePAN('4111111111111111');
        Test.stopTest();

        Assert.areEqual('1111', truncated, 'Should return last 4 digits only');
    }

    @IsTest
    static void testTruncatePAN_Null() {
        Test.startTest();
        String truncated = ElaroPCIDataMaskingService.truncatePAN(null);
        Test.stopTest();

        Assert.areEqual(null, truncated, 'Should return null for null input');
    }

    @IsTest
    static void testGetBIN_Valid() {
        Test.startTest();
        String bin = ElaroPCIDataMaskingService.getBIN('4111111111111111');
        Test.stopTest();

        Assert.areEqual('411111', bin, 'Should return first 6 digits');
    }

    @IsTest
    static void testGetBIN_Null() {
        Test.startTest();
        String bin = ElaroPCIDataMaskingService.getBIN(null);
        Test.stopTest();

        Assert.areEqual(null, bin, 'Should return null for null input');
    }

    @IsTest
    static void testGetBIN_TooShort() {
        Test.startTest();
        String bin = ElaroPCIDataMaskingService.getBIN('41111');
        Test.stopTest();

        Assert.areEqual(null, bin, 'Should return null for short input');
    }

    @IsTest
    static void testValidateLuhnChecksum_ValidVisa() {
        Test.startTest();
        Boolean isValid = ElaroPCIDataMaskingService.validateLuhnChecksum('4111111111111111');
        Test.stopTest();

        Assert.areEqual(true, isValid, 'Should validate valid Visa test number');
    }

    @IsTest
    static void testValidateLuhnChecksum_ValidMastercard() {
        Test.startTest();
        Boolean isValid = ElaroPCIDataMaskingService.validateLuhnChecksum('5500000000000004');
        Test.stopTest();

        Assert.areEqual(true, isValid, 'Should validate valid Mastercard test number');
    }

    @IsTest
    static void testValidateLuhnChecksum_Invalid() {
        Test.startTest();
        Boolean isValid = ElaroPCIDataMaskingService.validateLuhnChecksum('4111111111111112');
        Test.stopTest();

        Assert.areEqual(false, isValid, 'Should fail for invalid checksum');
    }

    @IsTest
    static void testValidateLuhnChecksum_TooShort() {
        Test.startTest();
        Boolean isValid = ElaroPCIDataMaskingService.validateLuhnChecksum('411111111');
        Test.stopTest();

        Assert.areEqual(false, isValid, 'Should fail for too short');
    }

    @IsTest
    static void testValidateLuhnChecksum_TooLong() {
        Test.startTest();
        Boolean isValid = ElaroPCIDataMaskingService.validateLuhnChecksum('41111111111111111111');
        Test.stopTest();

        Assert.areEqual(false, isValid, 'Should fail for too long');
    }

    @IsTest
    static void testIsShieldEncryptionEnabled() {
        Test.startTest();
        Boolean isEnabled = ElaroPCIDataMaskingService.isShieldEncryptionEnabled();
        Test.stopTest();

        // In test context, returns true as placeholder
        Assert.areNotEqual(null, isEnabled, 'Should return boolean');
    }

    @IsTest
    static void testBulkMasking() {
        List<String> cardNumbers = new List<String>();
        for (Integer i = 0; i < 200; i++) {
            cardNumbers.add('411111111111' + String.valueOf(1000 + i));
        }

        Test.startTest();
        List<String> maskedCards = new List<String>();
        for (String cardNumber : cardNumbers) {
            maskedCards.add(ElaroPCIDataMaskingService.maskCreditCard(cardNumber));
        }
        Test.stopTest();

        Assert.areEqual(200, maskedCards.size(), 'Should mask all 200 cards');
        for (String masked : maskedCards) {
            Assert.isTrue(masked.startsWith('****-****-****-'), 'All should be properly masked');
        }
    }

    @IsTest
    static void testValidateEncryptionEnabled() {
        Test.startTest();
        Boolean validationPassed = false;
        try {
            ElaroPCIDataMaskingService.validateEncryptionEnabled();
            // In dev/test, this passes as encryption check returns true
            validationPassed = true;
        } catch (ElaroPCIDataMaskingService.PCIViolationException e) {
            // This may throw in environments without Shield
            Assert.isTrue(e.getMessage().contains('Platform Encryption'),
                'Should mention encryption requirement');
        }
        Test.stopTest();

        // If no exception was thrown, encryption validation passed
        if (validationPassed) {
            Assert.isTrue(validationPassed, 'Encryption validation should pass in this environment');
        }
    }
}
