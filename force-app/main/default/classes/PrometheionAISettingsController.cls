public with sharing class PrometheionAISettingsController {
    @AuraEnabled(cacheable=true)
    public static Prometheion_AI_Settings__c getSettings() {
        Prometheion_AI_Settings__c settings = Prometheion_AI_Settings__c.getInstance();
        if (settings == null) {
            settings = new Prometheion_AI_Settings__c(
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
    public static void saveSettings(Prometheion_AI_Settings__c settings) {
        try {
            upsert settings;
        } catch (Exception e) {
            throw new AuraHandledException('Error saving settings: ' + e.getMessage());
        }
    }
}
