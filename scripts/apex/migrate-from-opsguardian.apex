// Execute via: sf apex run -f scripts/migrate-from-opsguardian.apex -o target-org

System.debug('🔄 Starting migration from OpsGuardian to Sentinel...');

// Check if OpsGuardian_History__c exists
Schema.DescribeSObjectResult[] describeResults = Schema.describeSObjects(new String[]{'OpsGuardian_History__c'});
if (describeResults[0] == null) {
    System.debug('⚠️  OpsGuardian_History__c object not found. Skipping migration.');
    return;
}

// Step 1: Migrate history to immutable graph
List<SObject> oldRecords = Database.query(
    'SELECT Event_Type__c, Severity__c, Message__c, Timestamp__c, Id ' +
    'FROM OpsGuardian_History__c ' +
    'WHERE Timestamp__c >= LAST_N_DAYS:180 ' +
    'LIMIT 10000'
);

Integer migratedCount = 0;
List<Sentinel_Compliance_Graph__b> allNewNodes = new List<Sentinel_Compliance_Graph__b>();

for (SObject old : oldRecords) {
    String eventType = String.valueOf(old.get('Event_Type__c'));
    String recordId = String.valueOf(old.get('Id'));
    String severity = String.valueOf(old.get('Severity__c'));

    String nodeHash = SentinelGraphIndexer.generateDeterministicHash(
        eventType != null ? eventType : 'UNKNOWN',
        recordId,
        'SOC2'
    );

    Decimal riskScore = 5.0;
    if (severity == 'Critical') riskScore = 9.0;
    else if (severity == 'Warning') riskScore = 6.0;
    else if (severity == 'Info') riskScore = 3.0;

    allNewNodes.add(new Sentinel_Compliance_Graph__b(
        Graph_Node_Id__c = nodeHash,
        Timestamp__c = (DateTime)old.get('Timestamp__c'),
        Entity_Type__c = eventType,
        Entity_Record_Id__c = recordId,
        Compliance_Framework__c = 'SOC2',
        Risk_Score__c = riskScore,
        Node_Metadata__c = JSON.serialize(old),
        Graph_Version__c = 'v3.0'
    ));

    if (allNewNodes.size() >= 100) {
        insert allNewNodes;
        migratedCount += allNewNodes.size();
        System.debug('✅ Migrated batch of ' + allNewNodes.size() + ' records (Total: ' + migratedCount + ')');
        allNewNodes.clear();
    }
}

// Insert remaining records
if (!allNewNodes.isEmpty()) {
    insert allNewNodes;
    migratedCount += allNewNodes.size();
    System.debug('✅ Migrated final batch of ' + allNewNodes.size() + ' records');
}

System.debug('🎉 Migration complete! Total records migrated: ' + migratedCount);
System.debug('📋 Next: Verify data in Sentinel Compliance Graph Big Object');
