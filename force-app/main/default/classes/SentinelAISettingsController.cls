public with sharing class SentinelAISettingsController {
    @AuraEnabled(cacheable=true)
    public static Sentinel_AI_Settings__c getSettings() {
        Sentinel_AI_Settings__c settings = Sentinel_AI_Settings__c.getInstance();
        if (settings == null) {
            settings = new Sentinel_AI_Settings__c(
                Enable_AI_Reasoning__c = true,
                Confidence_Threshold__c = 0.85,
                Require_Human_Approval__c = true,
                Auto_Remediation_Enabled__c = false,
                Blacklisted_Users__c = ''
            );
        }
        return settings;
    }

    @AuraEnabled
    public static void saveSettings(Sentinel_AI_Settings__c settings) {
        try {
            upsert settings;
        } catch (Exception e) {
            throw new AuraHandledException('Error saving settings: ' + e.getMessage());
        }
    }
}
