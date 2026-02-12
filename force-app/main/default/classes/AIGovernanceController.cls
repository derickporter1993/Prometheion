/**
 * Lightning Web Component controller for AI Governance dashboard.
 * Provides discovery, classification, and governance endpoints for
 * managing AI systems in compliance with EU AI Act and NIST AI RMF.
 *
 * @author Elaro Team
 * @since v1.0.0 (Spring '26)
 * @group AI Governance
 * @see AIDetectionEngine
 * @see AIGovernanceService
 */
public with sharing class AIGovernanceController {

    /**
     * Discovers all AI systems in the org and returns their detection metadata.
     *
     * @return List of AIDetectionEngine.AISystemMetadata
     * @throws AuraHandledException if discovery fails
     */
    @AuraEnabled(cacheable=false)
    public static List<AIDetectionEngine.AISystemMetadata> discoverAISystems() {
        try {
            return AIDetectionEngine.discoverAISystems();
        } catch (Exception e) {
            ElaroLogger.error('AIGovernanceController.discoverAISystems', e.getMessage(), e.getStackTraceString());
            throw new AuraHandledException('Unable to discover AI systems. Please verify you have the required permissions and try again.');
        }
    }

    /**
     * Registers a detected AI system into the AI_System_Registry__c.
     *
     * @param systemMetadata The AIDetectionEngine.AISystemMetadata to register
     * @param useCase Optional use case description
     * @return Id of the created AI_System_Registry__c record
     * @throws AuraHandledException if registration fails
     */
    @AuraEnabled
    public static Id registerAISystem(String systemMetadataJson, String useCase) {
        try {
            AIDetectionEngine.AISystemMetadata metadata =
                (AIDetectionEngine.AISystemMetadata) JSON.deserialize(
                    systemMetadataJson, AIDetectionEngine.AISystemMetadata.class
                );

            // Classify the system
            AIRiskClassificationEngine.RiskClassification classification =
                AIRiskClassificationEngine.classifySystem(metadata.systemType, useCase);

            // Create registry entry
            AI_System_Registry__c registry = new AI_System_Registry__c();
            registry.Name = metadata.systemName;
            registry.System_Type__c = metadata.systemType;
            registry.Detection_Method__c = metadata.detectionMethod;
            registry.Risk_Level__c = classification.riskLevel;
            registry.Status__c = classification.riskLevel == 'Unacceptable' ? 'Suspended' : 'Active';
            registry.Use_Case_Description__c = useCase;

            insert as user registry;

            ElaroLogger.info('AIGovernanceController.registerAISystem',
                'Registered AI system: ' + metadata.systemName + ' (Risk: ' + classification.riskLevel + ')');

            return registry.Id;

        } catch (Exception e) {
            ElaroLogger.error('AIGovernanceController.registerAISystem', e.getMessage(), e.getStackTraceString());
            throw new AuraHandledException('Unable to register the AI system. Please verify you have the required permissions and try again.');
        }
    }

    /**
     * Gets all registered AI systems with their risk classifications.
     *
     * @return List of AI_System_Registry__c records
     * @throws AuraHandledException if query fails
     */
    @AuraEnabled(cacheable=true)
    public static List<AI_System_Registry__c> getRegisteredSystems() {
        try {
            return [
                SELECT Id, Name, System_Type__c, Detection_Method__c, Risk_Level__c,
                       Status__c, Use_Case_Description__c, CreatedDate, LastModifiedDate
                FROM AI_System_Registry__c
                WITH USER_MODE
                ORDER BY Risk_Level__c DESC, CreatedDate DESC
            ];
        } catch (Exception e) {
            ElaroLogger.error('AIGovernanceController.getRegisteredSystems', e.getMessage(), e.getStackTraceString());
            throw new AuraHandledException('Unable to retrieve registered AI systems. Please verify you have the required permissions and try again.');
        }
    }

    /**
     * Gets AI governance compliance score and gaps.
     *
     * @return Dashboard summary with score and gaps
     * @throws AuraHandledException if calculation fails
     */
    @AuraEnabled(cacheable=false)
    public static DashboardSummary getGovernanceSummary() {
        try {
            AIGovernanceService service = new AIGovernanceService();

            DashboardSummary summary = new DashboardSummary();
            summary.complianceScore = service.calculateScore(null);
            summary.gaps = service.identifyGaps(null);
            summary.totalSystems = [SELECT COUNT() FROM AI_System_Registry__c WITH USER_MODE];
            summary.highRiskCount = [
                SELECT COUNT()
                FROM AI_System_Registry__c
                WHERE Risk_Level__c IN ('High', 'Unacceptable')
                WITH USER_MODE
            ];
            summary.aiUserCount = AILicenseDetector.getAIUserCount();
            summary.lastScanDate = Datetime.now();

            return summary;

        } catch (Exception e) {
            ElaroLogger.error('AIGovernanceController.getGovernanceSummary', e.getMessage(), e.getStackTraceString());
            throw new AuraHandledException('Unable to generate the governance summary. Please verify you have the required permissions and try again.');
        }
    }

    /**
     * Records a human oversight decision for an AI system.
     *
     * @param systemId The AI_System_Registry__c Id
     * @param originalOutput The original AI output
     * @param decision The human decision (Accept/Modify/Reject/Override)
     * @param justification The justification for the decision
     * @return Id of the created oversight record
     * @throws AuraHandledException if creation fails
     */
    @AuraEnabled
    public static Id recordOversightDecision(Id systemId, String originalOutput,
                                              String decision, String justification) {
        try {
            AI_Human_Oversight_Record__c oversight = new AI_Human_Oversight_Record__c();
            oversight.AI_System__c = systemId;
            oversight.Original_AI_Output__c = originalOutput;
            oversight.Human_Decision__c = decision;
            oversight.Justification__c = justification;
            oversight.Reviewer__c = UserInfo.getUserId();

            insert as user oversight;

            ElaroLogger.info('AIGovernanceController.recordOversightDecision',
                'Oversight decision recorded for system: ' + systemId + ', Decision: ' + decision);

            return oversight.Id;

        } catch (Exception e) {
            ElaroLogger.error('AIGovernanceController.recordOversightDecision', e.getMessage(), e.getStackTraceString());
            throw new AuraHandledException('Unable to record the oversight decision. Please verify you have the required permissions and try again.');
        }
    }

    /**
     * Gets recent AI-related audit trail entries.
     *
     * @param lookbackDays Number of days to scan backwards
     * @return List of AIAuditTrailScanner.AIAuditEntry
     * @throws AuraHandledException if scan fails
     */
    @AuraEnabled(cacheable=false)
    public static List<AIAuditTrailScanner.AIAuditEntry> getAIAuditTrail(Integer lookbackDays) {
        try {
            return AIAuditTrailScanner.scanAIChanges(lookbackDays);
        } catch (Exception e) {
            ElaroLogger.error('AIGovernanceController.getAIAuditTrail', e.getMessage(), e.getStackTraceString());
            throw new AuraHandledException('Unable to retrieve the AI audit trail. Please verify you have the required permissions and try again.');
        }
    }

    /**
     * Gets AI license assignments for governance reporting.
     *
     * @return List of AILicenseDetector.AILicenseAssignment
     * @throws AuraHandledException if detection fails
     */
    @AuraEnabled(cacheable=true)
    public static List<AILicenseDetector.AILicenseAssignment> getAILicenses() {
        try {
            return AILicenseDetector.detectAILicenses();
        } catch (Exception e) {
            ElaroLogger.error('AIGovernanceController.getAILicenses', e.getMessage(), e.getStackTraceString());
            throw new AuraHandledException('Unable to retrieve AI license information. Please verify you have the required permissions and try again.');
        }
    }

    /**
     * Updates the risk level of a registered AI system.
     *
     * @param systemId The AI_System_Registry__c Id
     * @param newRiskLevel The new risk level
     * @return Updated AI_System_Registry__c record
     * @throws AuraHandledException if update fails
     */
    @AuraEnabled
    public static AI_System_Registry__c updateRiskLevel(Id systemId, String newRiskLevel) {
        try {
            AI_System_Registry__c system = [
                SELECT Id, Risk_Level__c, Status__c
                FROM AI_System_Registry__c
                WHERE Id = :systemId
                WITH USER_MODE
                LIMIT 1
            ];

            system.Risk_Level__c = newRiskLevel;
            if (newRiskLevel == 'Unacceptable') {
                system.Status__c = 'Suspended';
            }

            update as user system;

            ElaroLogger.info('AIGovernanceController.updateRiskLevel',
                'Updated risk level for system ' + systemId + ' to ' + newRiskLevel);

            return system;

        } catch (Exception e) {
            ElaroLogger.error('AIGovernanceController.updateRiskLevel', e.getMessage(), e.getStackTraceString());
            throw new AuraHandledException('Unable to update the risk level. Please verify you have the required permissions and try again.');
        }
    }

    /**
     * Wrapper class for dashboard summary data.
     */
    public class DashboardSummary {
        @AuraEnabled public Decimal complianceScore { get; set; }
        @AuraEnabled public List<IComplianceModule.Gap> gaps { get; set; }
        @AuraEnabled public Integer totalSystems { get; set; }
        @AuraEnabled public Integer highRiskCount { get; set; }
        @AuraEnabled public Integer aiUserCount { get; set; }
        @AuraEnabled public Datetime lastScanDate { get; set; }
    }
}
