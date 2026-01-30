/**
 * ElaroChangeAdvisor
 * 
 * Analyzes PROPOSED changes before they're made, showing compliance impact in real-time.
 * This is proactive compliance - preventing violations before they happen.
 */
public with sharing class ElaroChangeAdvisor {
    
    /**
     * Analyzes a proposed change and returns compliance impact
     * 
     * @param changeType Type of change (GRANT_PERMISSION, MODIFY_SHARING, etc.)
     * @param proposedConfig Map containing proposed configuration
     * @return ChangeImpact object with score deltas and alternatives
     */
    public static ChangeImpact analyzeProposedChange(
        String changeType,
        Map<String, Object> proposedConfig
    ) {
        // Get current compliance scores
        ElaroComplianceScorer.ScoreResult currentScores = 
            ElaroComplianceScorer.calculateReadinessScore();
        
        // Simulate the proposed change
        Map<String, Decimal> projectedScores = simulateChange(
            changeType, 
            proposedConfig, 
            currentScores
        );
        
        // Calculate impact (delta)
        Map<String, Integer> scoreImpact = new Map<String, Integer>();
        scoreImpact.put('HIPAA', 
            Integer.valueOf(projectedScores.get('HIPAA') - currentScores.frameworkScores.get('HIPAA')));
        scoreImpact.put('SOC2', 
            Integer.valueOf(projectedScores.get('SOC2') - currentScores.frameworkScores.get('SOC2')));
        scoreImpact.put('NIST', 
            Integer.valueOf(projectedScores.get('NIST') - currentScores.frameworkScores.get('NIST')));
        scoreImpact.put('GDPR', 
            Integer.valueOf(projectedScores.get('GDPR') - currentScores.frameworkScores.get('GDPR')));
        
        // Calculate overall impact
        Decimal overallImpact = projectedScores.get('OVERALL') - currentScores.overallScore;
        
        // Determine risk level
        String riskLevel = calculateRiskLevel(overallImpact, scoreImpact);
        
        // Generate alternatives
        List<ChangeAlternative> alternatives = generateAlternatives(
            changeType, 
            proposedConfig, 
            currentScores
        );
        
        // Generate AI explanation
        String explanation = generateAIExplanation(
            changeType, 
            proposedConfig, 
            scoreImpact, 
            riskLevel
        );
        
        return new ChangeImpact(
            scoreImpact,
            overallImpact,
            riskLevel,
            alternatives,
            explanation,
            projectedScores.get('OVERALL'),
            currentScores.overallScore
        );
    }
    
    /**
     * Simulates a change and calculates projected compliance scores
     */
    private static Map<String, Decimal> simulateChange(
        String changeType,
        Map<String, Object> proposedConfig,
        ElaroComplianceScorer.ScoreResult currentScores
    ) {
        Map<String, Decimal> projectedScores = new Map<String, Decimal>();
        
        // Start with current scores
        projectedScores.put('HIPAA', currentScores.frameworkScores.get('HIPAA'));
        projectedScores.put('SOC2', currentScores.frameworkScores.get('SOC2'));
        projectedScores.put('NIST', currentScores.frameworkScores.get('NIST'));
        projectedScores.put('GDPR', currentScores.frameworkScores.get('GDPR'));
        
        // Apply change impact based on type
        if (changeType == 'GRANT_ADMIN_PERMISSION') {
            // Granting admin access reduces all framework scores
            Decimal impact = -8.0; // Base impact
            if (proposedConfig.containsKey('userCount')) {
                Integer userCount = (Integer)proposedConfig.get('userCount');
                impact = impact * userCount; // More users = more impact
            }
            
            projectedScores.put('HIPAA', projectedScores.get('HIPAA') + impact);
            projectedScores.put('SOC2', projectedScores.get('SOC2') + impact);
            projectedScores.put('NIST', projectedScores.get('NIST') + impact);
            projectedScores.put('GDPR', projectedScores.get('GDPR') + impact);
            
        } else if (changeType == 'MODIFY_SHARING_RULE') {
            String sharingLevel = (String)proposedConfig.get('sharingLevel');
            if (sharingLevel == 'Public Read/Write') {
                // Making sharing public reduces scores
                projectedScores.put('HIPAA', projectedScores.get('HIPAA') - 5.0);
                projectedScores.put('SOC2', projectedScores.get('SOC2') - 4.0);
                projectedScores.put('NIST', projectedScores.get('NIST') - 5.0);
            }
            
        } else if (changeType == 'ASSIGN_PERMISSION_SET') {
            String permissionSetId = (String)proposedConfig.get('permissionSetId');
            // Check if permission set has elevated privileges
            List<PermissionSet> ps = [
                SELECT PermissionsModifyAllData, PermissionsViewAllData
                FROM PermissionSet
                WHERE Id = :permissionSetId
                LIMIT 1
            ];
            
            if (!ps.isEmpty() && (ps[0].PermissionsModifyAllData || ps[0].PermissionsViewAllData)) {
                projectedScores.put('HIPAA', projectedScores.get('HIPAA') - 6.0);
                projectedScores.put('SOC2', projectedScores.get('SOC2') - 5.0);
            }
        }
        
        // Ensure scores don't go below 0
        for (String framework : projectedScores.keySet()) {
            if (projectedScores.get(framework) < 0) {
                projectedScores.put(framework, 0);
            }
        }
        
        // Calculate overall score (weighted average)
        Decimal overall = (projectedScores.get('HIPAA') * 0.25) +
                         (projectedScores.get('SOC2') * 0.25) +
                         (projectedScores.get('NIST') * 0.25) +
                         (projectedScores.get('GDPR') * 0.25);
        projectedScores.put('OVERALL', overall);
        
        return projectedScores;
    }
    
    /**
     * Generates alternative approaches that maintain compliance
     */
    private static List<ChangeAlternative> generateAlternatives(
        String changeType,
        Map<String, Object> proposedConfig,
        ElaroComplianceScorer.ScoreResult currentScores
    ) {
        List<ChangeAlternative> alternatives = new List<ChangeAlternative>();
        
        if (changeType == 'GRANT_ADMIN_PERMISSION') {
            // Alternative 1: Grant specific permission set instead
            alternatives.add(new ChangeAlternative(
                'GRANT_SPECIFIC_PERMISSION_SET',
                'Grant specific permission set instead of admin access',
                'Create a granular permission set with only the required object/field permissions. ' +
                'Maintains functionality without violating least privilege.',
                0, // No negative impact
                'This approach maintains your current compliance score while providing necessary access.'
            ));
            
            // Alternative 2: Use delegated admin
            alternatives.add(new ChangeAlternative(
                'USE_DELEGATED_ADMIN',
                'Use delegated admin for time-bound access',
                'Grant delegated admin rights for specific objects only, with automatic expiration. ' +
                'Reduces compliance risk while maintaining operational flexibility.',
                -1, // Minimal negative impact
                'Delegated admin provides admin-level access to specific objects without org-wide privileges.'
            ));
            
            // Alternative 3: Use permission set groups
            alternatives.add(new ChangeAlternative(
                'USE_PERMISSION_SET_GROUPS',
                'Use permission set groups for granular control',
                'Create a permission set group that combines multiple permission sets. ' +
                'Provides fine-grained access control without violating least privilege.',
                0,
                'Permission set groups allow you to grant exactly the access needed, nothing more.'
            ));
            
        } else if (changeType == 'MODIFY_SHARING_RULE') {
            alternatives.add(new ChangeAlternative(
                'USE_PRIVATE_OWD',
                'Set org-wide default to Private with sharing rules',
                'Set org-wide default to Private and use sharing rules for legitimate access. ' +
                'Maintains data security while allowing necessary collaboration.',
                0,
                'This approach provides better security while maintaining functionality.'
            ));
        }
        
        return alternatives;
    }
    
    /**
     * Generates AI-powered explanation of change impact
     */
    private static String generateAIExplanation(
        String changeType,
        Map<String, Object> proposedConfig,
        Map<String, Integer> scoreImpact,
        String riskLevel
    ) {
        String explanation = '';
        
        if (changeType == 'GRANT_ADMIN_PERMISSION') {
            Integer userCount = proposedConfig.containsKey('userCount') ? 
                (Integer)proposedConfig.get('userCount') : 1;
            
            explanation = 'Granting administrator-level permissions to ' + userCount + 
                ' user(s) will reduce your compliance scores across all frameworks. ' +
                'This violates the principle of least privilege, which requires granting ' +
                'only the minimum access necessary to perform job functions. ';
            
            if (scoreImpact.get('HIPAA') < -5) {
                explanation += 'HIPAA requires "minimum necessary" access (45 CFR §164.514(d)). ';
            }
            if (scoreImpact.get('SOC2') < -5) {
                explanation += 'SOC 2 requires logical access controls (CC6.1). ';
            }
            if (scoreImpact.get('NIST') < -5) {
                explanation += 'NIST requires least privilege access (AC-6). ';
            }
            
            explanation += 'Consider using granular permission sets instead.';
        }
        
        return explanation;
    }
    
    /**
     * Calculates risk level based on impact
     */
    private static String calculateRiskLevel(
        Decimal overallImpact,
        Map<String, Integer> scoreImpact
    ) {
        // Check if any framework drops below threshold
        Boolean criticalDrop = false;
        for (Integer impact : scoreImpact.values()) {
            if (impact < -10) {
                criticalDrop = true;
                break;
            }
        }
        
        if (criticalDrop || overallImpact < -10) {
            return 'CRITICAL';
        } else if (overallImpact < -5) {
            return 'HIGH';
        } else if (overallImpact < -2) {
            return 'MEDIUM';
        } else {
            return 'LOW';
        }
    }
    
    /**
     * Inner class representing change impact
     */
    public class ChangeImpact {
        public Map<String, Integer> frameworkImpact;
        public Decimal overallImpact;
        public String riskLevel;
        public List<ChangeAlternative> alternatives;
        public String explanation;
        public Decimal projectedScore;
        public Decimal currentScore;
        
        public ChangeImpact(
            Map<String, Integer> frameworkImpact,
            Decimal overallImpact,
            String riskLevel,
            List<ChangeAlternative> alternatives,
            String explanation,
            Decimal projectedScore,
            Decimal currentScore
        ) {
            this.frameworkImpact = frameworkImpact;
            this.overallImpact = overallImpact;
            this.riskLevel = riskLevel;
            this.alternatives = alternatives;
            this.explanation = explanation;
            this.projectedScore = projectedScore;
            this.currentScore = currentScore;
        }
    }
    
    /**
     * Inner class representing an alternative approach
     */
    public class ChangeAlternative {
        public String alternativeType;
        public String title;
        public String description;
        public Integer scoreImpact;
        public String benefit;
        
        public ChangeAlternative(
            String type,
            String title,
            String description,
            Integer scoreImpact,
            String benefit
        ) {
            this.alternativeType = type;
            this.title = title;
            this.description = description;
            this.scoreImpact = scoreImpact;
            this.benefit = benefit;
        }
    }
}

