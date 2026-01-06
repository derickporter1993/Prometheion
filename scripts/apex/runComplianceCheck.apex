// Use .apex files to store anonymous Apex.
// You can execute anonymous Apex in VS Code by selecting the
//     apex text and running the command:
//     SFDX: Execute Anonymous Apex with Currently Selected Text
// You can also execute the entire file by running the command:
//     SFDX: Execute Anonymous Apex with Editor Contents

// Run a compliance score check
Map<String, Object> scores = SolentraComplianceScorer.calculateComplianceScore();
System.debug('=== SOLENTRA COMPLIANCE SCORES ===');
System.debug('Overall Score: ' + scores.get('overallScore'));
System.debug('HIPAA Score: ' + scores.get('hipaaScore'));
System.debug('SOC2 Score: ' + scores.get('soc2Score'));
System.debug('NIST Score: ' + scores.get('nistScore'));
System.debug('FedRAMP Score: ' + scores.get('fedrampScore'));
System.debug('GDPR Score: ' + scores.get('gdprScore'));
System.debug('Risk Level: ' + scores.get('riskLevel'));

// Test the Copilot
SolentraComplianceCopilot.CopilotResponse response = SolentraComplianceCopilot.askCopilot('What is my current compliance status?');
System.debug('=== COPILOT RESPONSE ===');
System.debug('Message: ' + response.message);
System.debug('Score: ' + response.score);
System.debug('Query Type: ' + response.queryType);

