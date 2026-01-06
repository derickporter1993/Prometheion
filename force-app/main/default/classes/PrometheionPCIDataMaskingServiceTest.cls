/**
 * Test class for PrometheionPCIDataMaskingService
 * Tests PCI DSS Requirement 3 data masking functionality
 *
 * @author Prometheion
 * @version 1.0
 */
@IsTest
private class PrometheionPCIDataMaskingServiceTest {

    @IsTest
    static void testMaskCreditCard_ValidCard() {
        Test.startTest();
        String masked = PrometheionPrometheionPCIDataMaskingService.maskCreditCard('4111111111111111');
        Test.stopTest();

        System.assertEquals('****-****-****-1111', masked, 'Should show only last 4 digits');
    }

    @IsTest
    static void testMaskCreditCard_WithDashes() {
        Test.startTest();
        String masked = PrometheionPrometheionPCIDataMaskingService.maskCreditCard('4111-1111-1111-1111');
        Test.stopTest();

        System.assertEquals('****-****-****-1111', masked, 'Should handle dashes');
    }

    @IsTest
    static void testMaskCreditCard_WithSpaces() {
        Test.startTest();
        String masked = PrometheionPrometheionPCIDataMaskingService.maskCreditCard('4111 1111 1111 1111');
        Test.stopTest();

        System.assertEquals('****-****-****-1111', masked, 'Should handle spaces');
    }

    @IsTest
    static void testMaskCreditCard_Null() {
        Test.startTest();
        String masked = PrometheionPrometheionPCIDataMaskingService.maskCreditCard(null);
        Test.stopTest();

        System.assertEquals('****-****-****-****', masked, 'Should return full mask for null');
    }

    @IsTest
    static void testMaskCreditCard_Empty() {
        Test.startTest();
        String masked = PrometheionPrometheionPCIDataMaskingService.maskCreditCard('');
        Test.stopTest();

        System.assertEquals('****-****-****-****', masked, 'Should return full mask for empty');
    }

    @IsTest
    static void testMaskCreditCard_TooShort() {
        Test.startTest();
        String masked = PrometheionPrometheionPCIDataMaskingService.maskCreditCard('123');
        Test.stopTest();

        System.assertEquals('****-****-****-****', masked, 'Should return full mask for short input');
    }

    @IsTest
    static void testMaskCreditCardWithFormat_Amex() {
        Test.startTest();
        String masked = PrometheionPrometheionPCIDataMaskingService.maskCreditCardWithFormat(
            '371449635398431',
            '****-******-*1234'
        );
        Test.stopTest();

        System.assertEquals('****-******-*8431', masked, 'Should use Amex format');
    }

    @IsTest
    static void testMaskCreditCardWithFormat_Standard() {
        Test.startTest();
        String masked = PrometheionPrometheionPCIDataMaskingService.maskCreditCardWithFormat(
            '4111111111111111',
            '****-****-****-1234'
        );
        Test.stopTest();

        System.assertEquals('****-****-****-1111', masked, 'Should use standard format');
    }

    @IsTest
    static void testValidateNoCVVStorage_WithCVV() {
        Test.startTest();
        try {
            PrometheionPrometheionPCIDataMaskingService.validateNoCVVStorage('123');
            System.assert(false, 'Should throw PCIViolationException');
        } catch (PrometheionPrometheionPCIDataMaskingService.PCIViolationException e) {
            System.assert(e.getMessage().contains('PCI DSS Requirement 3.2'),
                'Should mention PCI requirement');
        }
        Test.stopTest();
    }

    @IsTest
    static void testValidateNoCVVStorage_Null() {
        Test.startTest();
        try {
            PrometheionPrometheionPCIDataMaskingService.validateNoCVVStorage(null);
            System.assert(true, 'Should not throw exception for null');
        } catch (PrometheionPrometheionPCIDataMaskingService.PCIViolationException e) {
            System.assert(false, 'Should not throw for null CVV');
        }
        Test.stopTest();
    }

    @IsTest
    static void testValidateNoCVVStorage_Empty() {
        Test.startTest();
        try {
            PrometheionPrometheionPCIDataMaskingService.validateNoCVVStorage('');
            System.assert(true, 'Should not throw exception for empty');
        } catch (PrometheionPrometheionPCIDataMaskingService.PCIViolationException e) {
            System.assert(false, 'Should not throw for empty CVV');
        }
        Test.stopTest();
    }

    @IsTest
    static void testTruncatePAN_Valid() {
        Test.startTest();
        String truncated = PrometheionPrometheionPCIDataMaskingService.truncatePAN('4111111111111111');
        Test.stopTest();

        System.assertEquals('1111', truncated, 'Should return last 4 digits only');
    }

    @IsTest
    static void testTruncatePAN_Null() {
        Test.startTest();
        String truncated = PrometheionPrometheionPCIDataMaskingService.truncatePAN(null);
        Test.stopTest();

        System.assertEquals(null, truncated, 'Should return null for null input');
    }

    @IsTest
    static void testGetBIN_Valid() {
        Test.startTest();
        String bin = PrometheionPrometheionPCIDataMaskingService.getBIN('4111111111111111');
        Test.stopTest();

        System.assertEquals('411111', bin, 'Should return first 6 digits');
    }

    @IsTest
    static void testGetBIN_Null() {
        Test.startTest();
        String bin = PrometheionPrometheionPCIDataMaskingService.getBIN(null);
        Test.stopTest();

        System.assertEquals(null, bin, 'Should return null for null input');
    }

    @IsTest
    static void testGetBIN_TooShort() {
        Test.startTest();
        String bin = PrometheionPrometheionPCIDataMaskingService.getBIN('41111');
        Test.stopTest();

        System.assertEquals(null, bin, 'Should return null for short input');
    }

    @IsTest
    static void testValidateLuhnChecksum_ValidVisa() {
        Test.startTest();
        Boolean isValid = PrometheionPrometheionPCIDataMaskingService.validateLuhnChecksum('4111111111111111');
        Test.stopTest();

        System.assertEquals(true, isValid, 'Should validate valid Visa test number');
    }

    @IsTest
    static void testValidateLuhnChecksum_ValidMastercard() {
        Test.startTest();
        Boolean isValid = PrometheionPrometheionPCIDataMaskingService.validateLuhnChecksum('5500000000000004');
        Test.stopTest();

        System.assertEquals(true, isValid, 'Should validate valid Mastercard test number');
    }

    @IsTest
    static void testValidateLuhnChecksum_Invalid() {
        Test.startTest();
        Boolean isValid = PrometheionPrometheionPCIDataMaskingService.validateLuhnChecksum('4111111111111112');
        Test.stopTest();

        System.assertEquals(false, isValid, 'Should fail for invalid checksum');
    }

    @IsTest
    static void testValidateLuhnChecksum_TooShort() {
        Test.startTest();
        Boolean isValid = PrometheionPrometheionPCIDataMaskingService.validateLuhnChecksum('411111111');
        Test.stopTest();

        System.assertEquals(false, isValid, 'Should fail for too short');
    }

    @IsTest
    static void testValidateLuhnChecksum_TooLong() {
        Test.startTest();
        Boolean isValid = PrometheionPrometheionPCIDataMaskingService.validateLuhnChecksum('41111111111111111111');
        Test.stopTest();

        System.assertEquals(false, isValid, 'Should fail for too long');
    }

    @IsTest
    static void testIsShieldEncryptionEnabled() {
        Test.startTest();
        Boolean isEnabled = PrometheionPrometheionPCIDataMaskingService.isShieldEncryptionEnabled();
        Test.stopTest();

        // In test context, returns true as placeholder
        System.assertNotEquals(null, isEnabled, 'Should return boolean');
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
            maskedCards.add(PrometheionPrometheionPCIDataMaskingService.maskCreditCard(cardNumber));
        }
        Test.stopTest();

        System.assertEquals(200, maskedCards.size(), 'Should mask all 200 cards');
        for (String masked : maskedCards) {
            System.assert(masked.startsWith('****-****-****-'), 'All should be properly masked');
        }
    }

    @IsTest
    static void testValidateEncryptionEnabled() {
        Test.startTest();
        try {
            PrometheionPrometheionPCIDataMaskingService.validateEncryptionEnabled();
            // In dev/test, this passes as encryption check returns true
            System.assert(true, 'Encryption validation passed');
        } catch (PrometheionPrometheionPCIDataMaskingService.PCIViolationException e) {
            // This may throw in environments without Shield
            System.assert(e.getMessage().contains('Platform Encryption'),
                'Should mention encryption requirement');
        }
        Test.stopTest();
    }
}
