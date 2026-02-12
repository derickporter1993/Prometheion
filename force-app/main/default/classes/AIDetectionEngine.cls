/**
 * Scans Salesforce org metadata using Metadata API to detect Einstein and GenAI
 * components deployed in the org. Identifies AI systems that require governance
 * per EU AI Act and NIST AI RMF requirements.
 *
 * @author Elaro Team
 * @since v1.0.0 (Spring '26)
 * @group AI Governance
 * @see AIGovernanceService
 * @see AIRiskClassificationEngine
 */
public inherited sharing class AIDetectionEngine {

    private static final String METADATA_API_ENDPOINT = '/services/Soap/m/66.0';
    private static final List<String> AI_METADATA_TYPES = new List<String>{
        'MLPredictionDefinition',
        'Bot',
        'GenAiFunction',
        'GenAiPlanner',
        'ConversationVendorInfo'
    };

    /**
     * Discovers all AI systems deployed in the org via Metadata API scanning.
     *
     * @return List of detected AI system metadata including type, name, and configuration
     * @throws AuraHandledException if Metadata API query fails or user lacks permission
     * @example
     * List<AIDetectionEngine.AISystemMetadata> systems = AIDetectionEngine.discoverAISystems();
     */
    public static List<AISystemMetadata> discoverAISystems() {
        List<AISystemMetadata> detectedSystems = new List<AISystemMetadata>();

        try {
            for (String metadataType : AI_METADATA_TYPES) {
                List<AISystemMetadata> systemsOfType = queryMetadataType(metadataType);
                if (systemsOfType != null && !systemsOfType.isEmpty()) {
                    detectedSystems.addAll(systemsOfType);
                }
            }
        } catch (Exception e) {
            ElaroLogger.error('AIDetectionEngine.discoverAISystems', e.getMessage(), e.getStackTraceString());
            throw new AuraHandledException('Unable to discover AI systems. Please verify you have the required permissions and try again.');
        }

        return detectedSystems;
    }

    /**
     * Queries Metadata API for components of a specific type.
     *
     * @param metadataType The metadata type to query (e.g., 'Bot', 'MLPredictionDefinition')
     * @return List of AISystemMetadata for the specified type
     */
    private static List<AISystemMetadata> queryMetadataType(String metadataType) {
        List<AISystemMetadata> systems = new List<AISystemMetadata>();

        try {
            // Use Tooling API to query metadata components
            String query = 'SELECT DeveloperName, NamespacePrefix, Id FROM ' + getToolingObjectName(metadataType);
            HttpRequest req = new HttpRequest();
            req.setEndpoint(URL.getOrgDomainUrl().toExternalForm()
                + '/services/data/v66.0/tooling/query/?q=' + EncodingUtil.urlEncode(query, 'UTF-8'));
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
            req.setHeader('Content-Type', 'application/json');

            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200) {
                Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                List<Object> records = (List<Object>) result.get('records');

                if (records != null) {
                    for (Object record : records) {
                        Map<String, Object> recordMap = (Map<String, Object>) record;
                        AISystemMetadata metadata = new AISystemMetadata();
                        metadata.systemType = mapMetadataTypeToSystemType(metadataType);
                        metadata.systemName = String.valueOf(recordMap.get('DeveloperName'));
                        metadata.detectionMethod = 'Metadata API Scan';
                        metadata.metadataId = String.valueOf(recordMap.get('Id'));
                        metadata.namespacePrefix = String.valueOf(recordMap.get('NamespacePrefix'));
                        systems.add(metadata);
                    }
                }
            }
        } catch (Exception e) {
            ElaroLogger.error('AIDetectionEngine.queryMetadataType',
                'Failed to query ' + metadataType + ': ' + e.getMessage(),
                e.getStackTraceString());
        }

        return systems;
    }

    /**
     * Maps Tooling API metadata type names to their corresponding Tooling Object names.
     *
     * @param metadataType The metadata type identifier
     * @return Corresponding Tooling API object name
     */
    private static String getToolingObjectName(String metadataType) {
        switch on metadataType {
            when 'MLPredictionDefinition' { return 'MLPredictionDefinition'; }
            when 'Bot' { return 'BotDefinition'; }
            when 'GenAiFunction' { return 'GenAiFunction'; }
            when 'GenAiPlanner' { return 'GenAiPlanner'; }
            when 'ConversationVendorInfo' { return 'ConversationVendorInfo'; }
            when else { return metadataType; }
        }
    }

    /**
     * Maps Metadata API type names to System Type picklist values.
     *
     * @param metadataType The metadata type identifier
     * @return System Type picklist value for AI_System_Registry__c
     */
    private static String mapMetadataTypeToSystemType(String metadataType) {
        switch on metadataType {
            when 'MLPredictionDefinition' { return 'Einstein Prediction'; }
            when 'Bot' { return 'Einstein Bot'; }
            when 'GenAiFunction' { return 'GenAI Function'; }
            when 'GenAiPlanner' { return 'GenAI Planner'; }
            when else { return 'Custom ML'; }
        }
    }

    /**
     * Wrapper class representing detected AI system metadata.
     */
    public class AISystemMetadata {
        @AuraEnabled public String systemType { get; set; }
        @AuraEnabled public String systemName { get; set; }
        @AuraEnabled public String detectionMethod { get; set; }
        @AuraEnabled public String metadataId { get; set; }
        @AuraEnabled public String namespacePrefix { get; set; }
        @AuraEnabled public String useCaseDescription { get; set; }
    }
}
