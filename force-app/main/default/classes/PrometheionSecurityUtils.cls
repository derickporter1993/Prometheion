/**
 * PrometheionSecurityUtils
 * 
 * Centralized security utilities for CRUD/FLS checks and access control
 * 
 * @author Prometheion
 * @version 1.0
 */
public with sharing class PrometheionSecurityUtils {
    
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
            if (objType == null) return false;
            
            Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
            Schema.DescribeFieldResult fieldDescribe = objDescribe.fields.getMap().get(fieldName)?.getDescribe();
            
            return fieldDescribe != null && fieldDescribe.isAccessible();
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error checking field access: ' + e.getMessage());
            return false;
        }
    }
    
    /**
     * Check if user has create/update access to a specific field
     */
    public static Boolean hasFieldWriteAccess(String sObjectType, String fieldName) {
        try {
            Schema.SObjectType objType = Schema.getGlobalDescribe().get(sObjectType);
            if (objType == null) return false;
            
            Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
            Schema.DescribeFieldResult fieldDescribe = objDescribe.fields.getMap().get(fieldName)?.getDescribe();
            
            return fieldDescribe != null && fieldDescribe.isCreateable() && fieldDescribe.isUpdateable();
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error checking field write access: ' + e.getMessage());
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
            System.debug(LoggingLevel.ERROR, 'Error stripping inaccessible fields: ' + e.getMessage());
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
     * Build a safe SOQL query with WITH SECURITY_ENFORCED
     */
    public static String buildSecureQuery(String baseQuery) {
        // Remove existing WITH SECURITY_ENFORCED if present
        String cleaned = baseQuery.replaceAll('(?i)\\s+WITH\\s+SECURITY_ENFORCED', '');
        return cleaned + ' WITH SECURITY_ENFORCED';
    }
}
