/**
 * ElaroSecurityUtils
 * 
 * Centralized security utilities for CRUD/FLS checks and access control
 * 
 * @author Elaro
 * @version 1.0
 * @since v3.1.0 (Spring '26)
 * @group Utilities
 */
public with sharing class ElaroSecurityUtils {
    
    /**
     * DML Operation enum
     */
    public enum DmlOperation {
        DML_INSERT,
        DML_UPDATE,
        DML_DELETE,
        DML_UPSERT
    }
    
    /**
     * Custom Security Exception
     */
    public class SecurityException extends Exception {}
    
    /**
     * Check if user has read access to SObject type
     */
    public static Boolean hasReadAccess(String sObjectType) {
        Schema.DescribeSObjectResult describe = Schema.getGlobalDescribe().get(sObjectType)?.getDescribe();
        return describe != null && describe.isAccessible();
    }
    
    /**
     * Check if user has create access to SObject type
     */
    public static Boolean hasCreateAccess(String sObjectType) {
        Schema.DescribeSObjectResult describe = Schema.getGlobalDescribe().get(sObjectType)?.getDescribe();
        return describe != null && describe.isCreateable();
    }
    
    /**
     * Check if user has update access to SObject type
     */
    public static Boolean hasUpdateAccess(String sObjectType) {
        Schema.DescribeSObjectResult describe = Schema.getGlobalDescribe().get(sObjectType)?.getDescribe();
        return describe != null && describe.isUpdateable();
    }
    
    /**
     * Check if user has delete access to SObject type
     */
    public static Boolean hasDeleteAccess(String sObjectType) {
        Schema.DescribeSObjectResult describe = Schema.getGlobalDescribe().get(sObjectType)?.getDescribe();
        return describe != null && describe.isDeletable();
    }
    
    /**
     * Check if user has read access to a specific field
     */
    public static Boolean hasFieldReadAccess(String sObjectType, String fieldName) {
        try {
            Schema.SObjectType objType = Schema.getGlobalDescribe().get(sObjectType);
            if (objType == null) {
                return false;
            }
            
            Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
            Schema.DescribeFieldResult fieldDescribe = objDescribe.fields.getMap().get(fieldName)?.getDescribe();
            
            return fieldDescribe != null && fieldDescribe.isAccessible();
        } catch (Exception e) {
            ElaroLogger.error('Error checking field access', e);
            return false;
        }
    }
    
    /**
     * Check if user has create/update access to a specific field
     */
    public static Boolean hasFieldWriteAccess(String sObjectType, String fieldName) {
        try {
            Schema.SObjectType objType = Schema.getGlobalDescribe().get(sObjectType);
            if (objType == null) {
                return false;
            }
            
            Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
            Schema.DescribeFieldResult fieldDescribe = objDescribe.fields.getMap().get(fieldName)?.getDescribe();
            
            return fieldDescribe != null && fieldDescribe.isCreateable() && fieldDescribe.isUpdateable();
        } catch (Exception e) {
            ElaroLogger.error('Error checking field write access', e);
            return false;
        }
    }
    
    /**
     * Strip inaccessible fields from a list of SObjects
     * Returns a new list with only accessible fields
     */
    public static List<SObject> stripInaccessibleFields(AccessType accessType, List<SObject> records) {
        if (records == null || records.isEmpty()) {
            return new List<SObject>();
        }
        
        try {
            SObjectAccessDecision decision = Security.stripInaccessible(accessType, records);
            return decision.getRecords();
        } catch (Exception e) {
            ElaroLogger.error('Error stripping inaccessible fields', e);
            throw new SecurityException('Access denied: ' + e.getMessage());
        }
    }
    
    /**
     * Validate CRUD access before DML operations
     */
    public static void validateCRUDAccess(String sObjectType, DmlOperation operation) {
        Boolean hasAccess = false;
        
        if (operation == DmlOperation.DML_INSERT) {
            hasAccess = hasCreateAccess(sObjectType);
        } else if (operation == DmlOperation.DML_UPDATE) {
            hasAccess = hasUpdateAccess(sObjectType);
        } else if (operation == DmlOperation.DML_DELETE) {
            hasAccess = hasDeleteAccess(sObjectType);
        } else if (operation == DmlOperation.DML_UPSERT) {
            hasAccess = hasCreateAccess(sObjectType) && hasUpdateAccess(sObjectType);
        }
        
        if (!hasAccess) {
            throw new SecurityException('Insufficient CRUD access for ' + operation + ' on ' + sObjectType);
        }
    }
    
    /**
     * Validate field-level security for a list of fields
     */
    public static void validateFLSAccess(String sObjectType, List<String> fieldNames, Boolean requireWrite) {
        for (String fieldName : fieldNames) {
            Boolean hasAccess = requireWrite 
                ? hasFieldWriteAccess(sObjectType, fieldName)
                : hasFieldReadAccess(sObjectType, fieldName);
            
            if (!hasAccess) {
                throw new SecurityException('Insufficient FLS access for field ' + sObjectType + '.' + fieldName);
            }
        }
    }
    
    /**
     * Build a safe SOQL query with WITH USER_MODE
     */
    public static String buildSecureQuery(String baseQuery) {
        // Remove existing WITH USER_MODE if present
        String cleaned = baseQuery.replaceAll('(?i)\\s+WITH\\s+SECURITY_ENFORCED', '');
        return cleaned + ' WITH USER_MODE';
    }

    /**
     * Compares two strings in constant time to prevent timing attacks.
     *
     * Uses bitwise XOR accumulation to ensure comparison time is independent
     * of where strings differ, preventing attackers from using timing analysis
     * to deduce secret values byte-by-byte.
     *
     * SECURITY: This method MUST be used for all secret comparisons including
     * API keys, webhook secrets, HMAC signatures, and authentication tokens.
     * Never use String.equals() or == for secret comparison.
     *
     * @param expected The expected secret value
     * @param provided The provided value to validate
     * @return True if strings match exactly, false otherwise
     * @see ElaroScoreCallback.validateHmacSignature for HMAC usage example
     * @example
     * String webhookSecret = settings.Webhook_Secret__c;
     * String providedSecret = request.headers.get('X-Webhook-Secret');
     * if (!ElaroSecurityUtils.compareSecrets(webhookSecret, providedSecret)) {
     *     throw new SecurityException('Invalid webhook secret');
     * }
     */
    public static Boolean compareSecrets(String expected, String provided) {
        // Handle null inputs - never allow null to match
        if (expected == null || provided == null) {
            return false;
        }

        // Length check - fail fast only on length mismatch (safe to expose length)
        if (expected.length() != provided.length()) {
            return false;
        }

        // Constant-time comparison using XOR accumulation
        // Any difference sets at least one bit in result
        Integer result = 0;
        for (Integer i = 0; i < expected.length(); i++) {
            result |= expected.charAt(i) ^ provided.charAt(i);
        }

        // Return true only if all characters matched (result == 0)
        return result == 0;
    }
}
