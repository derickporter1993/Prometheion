// Execute via: sf apex run -f scripts/generate-baseline-report.apex -o target-org

System.debug('📊 Generating Prometheion Baseline Compliance Report...');

// Generate baseline entries for all permission sets
List<PermissionSet> permSets = [
    SELECT Id, Name, Label, Description
    FROM PermissionSet
    WHERE IsCustom = true
    LIMIT 100
];

Integer indexed = 0;
for (PermissionSet ps : permSets) {
    try {
        String nodeHash = PrometheionGraphIndexer.indexChange('PERMISSION_SET', ps.Id, null, 'SOC2');
        indexed++;
        System.debug('✅ Indexed permission set: ' + ps.Label + ' (' + nodeHash + ')');
    } catch (Exception e) {
        System.debug('❌ Failed to index ' + ps.Label + ': ' + e.getMessage());
    }
}

// Generate baseline for flows
List<FlowDefinitionView> flows = [
    SELECT DurableId, ApiName, Label
    FROM FlowDefinitionView
    WHERE IsActive = true
    LIMIT 100
];

for (FlowDefinitionView flow : flows) {
    try {
        String nodeHash = PrometheionGraphIndexer.indexChange('FLOW', flow.DurableId, null, 'SOC2');
        indexed++;
        System.debug('✅ Indexed flow: ' + flow.Label + ' (' + nodeHash + ')');
    } catch (Exception e) {
        System.debug('❌ Failed to index ' + flow.Label + ': ' + e.getMessage());
    }
}

System.debug('🎉 Baseline report complete! Total entities indexed: ' + indexed);
System.debug('📋 Next: Review compliance dashboard to see readiness score');
