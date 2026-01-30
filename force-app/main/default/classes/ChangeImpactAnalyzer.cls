/**
 * ChangeImpactAnalyzer
 * 
 * Pre-deployment analysis of metadata changes
 * 
 * @author Elaro
 * @version 1.0
 */
public with sharing class ChangeImpactAnalyzer {
    
    /**
     * Analyze impact of metadata changes before deployment
     * @param changes List of metadata changes to analyze
     * @return Impact analysis result
     */
    @AuraEnabled
    public static ImpactAnalysisResult analyzeImpact(List<MetadataChange> changes) {
        if (changes == null || changes.isEmpty()) {
            throw new IllegalArgumentException('Changes list cannot be null or empty');
        }
        
        ImpactAnalysisResult result = new ImpactAnalysisResult();
        result.analyzedDate = System.now();
        result.totalChanges = changes.size();
        result.risks = new List<RiskFinding>();
        result.complianceImpact = new Map<String, String>();
        
        for (MetadataChange change : changes) {
            // Analyze each change
            RiskFinding risk = analyzeChange(change);
            if (risk != null) {
                result.risks.add(risk);
            }
            
            // Check compliance impact
            String complianceImpact = checkComplianceImpact(change);
            if (String.isNotBlank(complianceImpact)) {
                result.complianceImpact.put(change.metadataName, complianceImpact);
            }
        }
        
        // Calculate overall risk level
        result.overallRiskLevel = calculateOverallRisk(result.risks);
        
        return result;
    }
    
    /**
     * Analyze a single change
     */
    private static RiskFinding analyzeChange(MetadataChange change) {
        RiskFinding risk = new RiskFinding();
        risk.metadataName = change.metadataName;
        risk.metadataType = change.metadataType;
        risk.changeType = change.changeType;
        
        // High-risk metadata types
        Set<String> highRiskTypes = new Set<String>{
            'PermissionSet', 'Profile', 'SharingRule', 'ApexClass', 'Flow'
        };
        
        if (highRiskTypes.contains(change.metadataType)) {
            risk.severity = 'HIGH';
            risk.description = 'Change to ' + change.metadataType + ' may impact security or compliance';
        } else if (change.changeType == 'DELETE') {
            risk.severity = 'MEDIUM';
            risk.description = 'Deletion of ' + change.metadataType + ' may break dependencies';
        } else {
            return null; // Low risk, no finding
        }
        
        return risk;
    }
    
    /**
     * Check compliance impact
     */
    private static String checkComplianceImpact(MetadataChange change) {
        // Check if change affects compliance-sensitive metadata
        Set<String> complianceSensitive = new Set<String>{
            'PermissionSet', 'Profile', 'SharingRule', 'CustomObject'
        };
        
        if (complianceSensitive.contains(change.metadataType)) {
            return 'May impact SOX, SOC2, or HIPAA compliance';
        }
        
        return null;
    }
    
    /**
     * Calculate overall risk level
     */
    private static String calculateOverallRisk(List<RiskFinding> risks) {
        Boolean hasCritical = false;
        Boolean hasHigh = false;
        
        for (RiskFinding risk : risks) {
            if (risk.severity == 'CRITICAL') {
                hasCritical = true;
            } else if (risk.severity == 'HIGH') {
                hasHigh = true;
            }
        }
        
        if (hasCritical) return 'CRITICAL';
        if (hasHigh) return 'HIGH';
        if (!risks.isEmpty()) return 'MEDIUM';
        return 'LOW';
    }
    
    /**
     * Metadata Change
     */
    public class MetadataChange {
        @AuraEnabled public String metadataType;
        @AuraEnabled public String metadataName;
        @AuraEnabled public String changeType;
    }
    
    /**
     * Impact Analysis Result
     */
    public class ImpactAnalysisResult {
        @AuraEnabled public Datetime analyzedDate;
        @AuraEnabled public Integer totalChanges;
        @AuraEnabled public String overallRiskLevel;
        @AuraEnabled public List<RiskFinding> risks;
        @AuraEnabled public Map<String, String> complianceImpact;
    }
    
    /**
     * Risk Finding
     */
    public class RiskFinding {
        @AuraEnabled public String metadataName;
        @AuraEnabled public String metadataType;
        @AuraEnabled public String changeType;
        @AuraEnabled public String severity;
        @AuraEnabled public String description;
    }
}
