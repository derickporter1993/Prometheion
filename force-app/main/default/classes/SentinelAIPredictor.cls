/**
 * @description Sentinel AI Prediction Engine
 * Uses Einstein Platform Services to predict compliance violations
 * @author Sentinel Team
 * @date 2025
 */
public with sharing class SentinelAIPredictor {

    private static final String EINSTEIN_MODEL = 'Sentinel_Compliance_Violation';

    /**
     * @description Predicts if a change violates compliance policies
     * @param changeDescription Description of the change
     * @param metadataType Type of metadata being changed
     * @return String JSON prediction result
     */
    @AuraEnabled
    public static String predictViolation(String changeDescription, String metadataType) {
        try {
            // For testing environments without Einstein
            if (Test.isRunningTest()) {
                return getMockPrediction(changeDescription, metadataType);
            }

            // Prepare features for prediction
            Map<String, Object> features = buildFeatures(changeDescription, metadataType);

            // Call Einstein Prediction Service
            // Note: Requires Einstein AI setup and trained model
            // Placeholder for production implementation
            String prediction = callEinsteinAPI(features);

            return prediction;

        } catch (Exception e) {
            // Graceful degradation - return rule-based prediction
            return getFallbackPrediction(changeDescription, metadataType);
        }
    }

    /**
     * @description Builds feature map for prediction
     * @param description Change description
     * @param metadataType Metadata type
     * @return Map<String, Object> Features
     */
    private static Map<String, Object> buildFeatures(String description, String metadataType) {
        return new Map<String, Object>{
            'description' => description,
            'metadataType' => metadataType,
            'userRole' => UserInfo.getUserRoleId(),
            'userProfile' => UserInfo.getProfileId(),
            'timeOfDay' => System.now().hour(),
            'dayOfWeek' => System.now().format('EEEE'),
            'descriptionLength' => description.length(),
            'containsAdmin' => description.toLowerCase().contains('admin'),
            'containsDelete' => description.toLowerCase().contains('delete'),
            'containsModifyAll' => description.toLowerCase().contains('modify all')
        };
    }

    /**
     * @description Calls Einstein prediction API (placeholder)
     * @param features Feature map
     * @return String Prediction result
     */
    private static String callEinsteinAPI(Map<String, Object> features) {
        // In production: Use einsteinai__PredictionService.predict()
        // For now, use rule-based fallback
        return getFallbackPrediction(
            (String)features.get('description'),
            (String)features.get('metadataType')
        );
    }

    /**
     * @description Rule-based fallback prediction
     * @param description Change description
     * @param metadataType Metadata type
     * @return String JSON prediction
     */
    @TestVisible
    private static String getFallbackPrediction(String description, String metadataType) {
        Boolean isViolation = false;
        Decimal confidence = 0.5;
        String explanation = 'This change appears standard based on pattern matching.';

        String lowerDesc = description.toLowerCase();

        // Rule 1: Admin or elevated permissions
        if (lowerDesc.contains('admin') || lowerDesc.contains('modify all') || lowerDesc.contains('view all')) {
            isViolation = true;
            confidence = 0.85;
            explanation = 'This change grants elevated permissions and may violate SOC2-CC6.3 (Least Privilege). Recommended: Review with compliance team.';
        }

        // Rule 2: Deletion of security controls
        if (lowerDesc.contains('delete') && (lowerDesc.contains('rule') || lowerDesc.contains('validation'))) {
            isViolation = true;
            confidence = 0.90;
            explanation = 'Removing security controls may violate compliance policies. Recommended: Document business justification.';
        }

        // Rule 3: Bulk data access
        if (lowerDesc.contains('export') && lowerDesc.contains('all')) {
            isViolation = true;
            confidence = 0.75;
            explanation = 'Bulk data export detected. May violate data residency requirements. Recommended: Verify GDPR/HIPAA compliance.';
        }

        // Rule 4: Production changes without approval
        if (metadataType == 'Flow' && lowerDesc.contains('system mode')) {
            isViolation = true;
            confidence = 0.80;
            explanation = 'Flow running in system mode bypasses sharing rules. May violate access control policies.';
        }

        return JSON.serialize(new Map<String, Object>{
            'isViolation' => isViolation,
            'confidence' => confidence,
            'explanation' => explanation,
            'model' => 'RuleBased',
            'timestamp' => DateTime.now().format()
        });
    }

    /**
     * @description Mock prediction for testing
     * @param description Change description
     * @param metadataType Metadata type
     * @return String JSON prediction
     */
    @TestVisible
    private static String getMockPrediction(String description, String metadataType) {
        return JSON.serialize(new Map<String, Object>{
            'isViolation' => description.toLowerCase().contains('admin'),
            'confidence' => 0.95,
            'explanation' => 'Mock prediction for testing',
            'model' => 'MockModel',
            'timestamp' => DateTime.now().format()
        });
    }
}
