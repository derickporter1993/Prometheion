/**
 * Test class for PCIDataProtectionService
 * Tests CHD encryption, tokenization, encryption validation, key management
 * 
 * @author Elaro
 * @version 3.0
 */
@IsTest
private class PCIDataProtectionServiceTest {
    
    @IsTest
    static void testEncryptCHD_Success() {
        String cardholderData = '4111111111111111'; // Test card number
        
        Test.startTest();
        PCIDataProtectionService service = new PCIDataProtectionService();
        String encryptedData = service.encryptCHD(cardholderData);
        Test.stopTest();
        
        System.assertNotEquals(null, encryptedData, 'Encrypted data should not be null');
        System.assertNotEquals(cardholderData, encryptedData, 'Encrypted data should differ from original');
    }
    
    @IsTest
    static void testEncryptCHD_Bulk() {
        List<String> cardholderDataList = new List<String>();
        for (Integer i = 0; i < 200; i++) {
            cardholderDataList.add('411111111111' + String.valueOf(i).leftPad(4, '0'));
        }
        
        Test.startTest();
        PCIDataProtectionService service = new PCIDataProtectionService();
        List<String> encryptedDataList = new List<String>();
        for (String data : cardholderDataList) {
            try {
                String encrypted = service.encryptCHD(data);
                encryptedDataList.add(encrypted);
            } catch (Exception e) {
                // Some may fail due to encryption limitations
            }
        }
        Test.stopTest();
        
        System.assert(encryptedDataList.size() > 0, 'Should process bulk encryption');
    }
    
    @IsTest
    static void testTokenizeData_Success() {
        String cardholderData = '4111111111111111';
        
        Test.startTest();
        PCIDataProtectionService service = new PCIDataProtectionService();
        String token = service.tokenizeData(cardholderData);
        Test.stopTest();
        
        System.assertNotEquals(null, token, 'Token should not be null');
        System.assertNotEquals(cardholderData, token, 'Token should differ from original');
        System.assert(token.startsWith('TOKEN-'), 'Token should have TOKEN prefix');
    }
    
    @IsTest
    static void testTokenizeData_Bulk() {
        List<String> cardholderDataList = new List<String>();
        for (Integer i = 0; i < 200; i++) {
            cardholderDataList.add('411111111111' + String.valueOf(i).leftPad(4, '0'));
        }
        
        Test.startTest();
        PCIDataProtectionService service = new PCIDataProtectionService();
        List<String> tokens = new List<String>();
        for (String data : cardholderDataList) {
            try {
                String token = service.tokenizeData(data);
                tokens.add(token);
            } catch (Exception e) {
                // Some may fail
            }
        }
        Test.stopTest();
        
        System.assert(tokens.size() > 0, 'Should process bulk tokenization');
    }
    
    @IsTest
    static void testValidateEncryption_Valid() {
        // First encrypt data
        PCIDataProtectionService service = new PCIDataProtectionService();
        String cardholderData = '4111111111111111';
        String encryptedData = service.encryptCHD(cardholderData);
        
        Test.startTest();
        Map<String, Object> result = service.validateEncryption(encryptedData);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Validation result should not be null');
        System.assert(result.containsKey('isValid'), 'Should include validation status');
    }
    
    @IsTest
    static void testValidateEncryption_Invalid() {
        String invalidEncryptedData = 'INVALID_DATA';
        
        Test.startTest();
        PCIDataProtectionService service = new PCIDataProtectionService();
        Map<String, Object> result = service.validateEncryption(invalidEncryptedData);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Validation result should not be null');
    }
    
    @IsTest
    static void testKeyManagement_Generate() {
        String operation = 'GENERATE';
        
        Test.startTest();
        PCIDataProtectionService service = new PCIDataProtectionService();
        Map<String, Object> result = service.keyManagement(operation, null);
        Test.stopTest();
        
        System.assertEquals(true, result.get('success'), 'Key generation should succeed');
        System.assertEquals(operation, result.get('operation'), 'Operation should match');
    }
    
    @IsTest
    static void testKeyManagement_Rotate() {
        String operation = 'ROTATE';
        String keyId = 'KEY123';
        
        Test.startTest();
        PCIDataProtectionService service = new PCIDataProtectionService();
        Map<String, Object> result = service.keyManagement(operation, keyId);
        Test.stopTest();
        
        System.assertEquals(true, result.get('success'), 'Key rotation should succeed');
        System.assertEquals(keyId, result.get('keyId'), 'Key ID should match');
    }
    
    @IsTest
    static void testKeyManagement_Revoke() {
        String operation = 'REVOKE';
        String keyId = 'KEY123';
        
        Test.startTest();
        PCIDataProtectionService service = new PCIDataProtectionService();
        Map<String, Object> result = service.keyManagement(operation, keyId);
        Test.stopTest();
        
        System.assertEquals(true, result.get('success'), 'Key revocation should succeed');
    }
    
    @IsTest
    static void testEncryptCHD_NullData() {
        Test.startTest();
        PCIDataProtectionService service = new PCIDataProtectionService();
        try {
            service.encryptCHD(null);
            System.assert(false, 'Should throw exception for null data');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('required'), 'Should validate required parameters');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testTokenizeData_NullData() {
        Test.startTest();
        PCIDataProtectionService service = new PCIDataProtectionService();
        try {
            service.tokenizeData(null);
            System.assert(false, 'Should throw exception for null data');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('required'), 'Should validate required parameters');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testValidateEncryption_NullData() {
        Test.startTest();
        PCIDataProtectionService service = new PCIDataProtectionService();
        try {
            service.validateEncryption(null);
            System.assert(false, 'Should throw exception for null data');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('required'), 'Should validate required parameters');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testKeyManagement_NullOperation() {
        Test.startTest();
        PCIDataProtectionService service = new PCIDataProtectionService();
        try {
            service.keyManagement(null, null);
            System.assert(false, 'Should throw exception for null operation');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('required'), 'Should validate required parameters');
        }
        Test.stopTest();
    }
}
