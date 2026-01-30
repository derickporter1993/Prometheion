/**
 * ElaroFrameworkEngine
 * 
 * Maps Salesforce metadata to compliance framework requirements
 * 
 * @author Elaro
 * @version 1.0
 */
public with sharing class ElaroFrameworkEngine {
    
    /**
     * Framework requirement structure
     */
    public class FrameworkRequirement {
        public String code;
        public String description;
        public String entityType;
        public Map<String, Object> metadata;
        
        public FrameworkRequirement(String code, String description, String entityType) {
            this.code = code;
            this.description = description;
            this.entityType = entityType;
            this.metadata = new Map<String, Object>();
        }
    }
    
    /**
     * Get framework requirements for a specific framework
     * @param framework Framework name
     * @return List of framework requirements
     */
    public static List<FrameworkRequirement> getFrameworkRequirements(String framework) {
        if (String.isBlank(framework)) {
            return new List<FrameworkRequirement>();
        }
        
        List<FrameworkRequirement> requirements = new List<FrameworkRequirement>();
        
        switch on framework {
            when 'SOC2' {
                requirements.add(new FrameworkRequirement('SOC2-CC6.1', 
                    'Logical and physical access controls', 'PERMISSION_SET'));
                requirements.add(new FrameworkRequirement('SOC2-CC6.2', 
                    'Prior authorization for access', 'PERMISSION_SET'));
                requirements.add(new FrameworkRequirement('SOC2-CC6.6', 
                    'Access removal for terminated users', 'USER'));
            }
            when 'HIPAA' {
                requirements.add(new FrameworkRequirement('HIPAA-164.308', 
                    'Administrative safeguards', 'PERMISSION_SET'));
                requirements.add(new FrameworkRequirement('HIPAA-164.312', 
                    'Technical safeguards', 'FIELD_LEVEL_SECURITY'));
            }
            when 'SOX' {
                requirements.add(new FrameworkRequirement('SOX-404', 
                    'Internal controls over financial reporting', 'SETUP_AUDIT_TRAIL'));
            }
            when else {
                // Generic requirements for other frameworks
                requirements.add(new FrameworkRequirement(framework + '-001', 
                    'Access control requirements', 'PERMISSION_SET'));
                requirements.add(new FrameworkRequirement(framework + '-002', 
                    'Audit trail requirements', 'SETUP_AUDIT_TRAIL'));
            }
        }
        
        return requirements;
    }
    
    /**
     * Map entity to framework requirement
     * @param entityType Entity type
     * @param entityId Entity ID
     * @param framework Framework name
     * @return List of matching requirement codes
     */
    public static List<String> mapEntityToRequirements(String entityType, String entityId, String framework) {
        List<String> requirementCodes = new List<String>();
        List<FrameworkRequirement> requirements = getFrameworkRequirements(framework);
        
        for (FrameworkRequirement req : requirements) {
            if (req.entityType == entityType) {
                requirementCodes.add(req.code);
            }
        }
        
        return requirementCodes;
    }
}
