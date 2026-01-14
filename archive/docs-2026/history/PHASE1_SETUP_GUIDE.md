# Phase 1 Setup Guide: Off-Platform Compute Architecture

This guide walks you through setting up the foundational architecture for Prometheion's off-platform compute system.

## Prerequisites

- Salesforce org with API access
- AWS account (free tier is sufficient for testing)
- Anthropic Claude API key (for AI analysis)
- Salesforce CLI (`sf`) installed and authenticated

## Step 1: Deploy Salesforce Metadata

### 1.1 Deploy Platform Events and Custom Objects

```bash
cd /Users/derickporter/salesforce-projects/Solentra

# Deploy Platform Events
sf project deploy start \
  --source-dir force-app/main/default/objects/Prometheion_Raw_Event__e \
  --source-dir force-app/main/default/objects/Prometheion_Score_Result__e \
  -o prod-org

# Deploy Custom Object
sf project deploy start \
  --source-dir force-app/main/default/objects/Compliance_Score__c \
  -o prod-org
```

### 1.2 Deploy Apex Classes

```bash
# Deploy event publisher and callback
sf project deploy start \
  --source-dir force-app/main/default/classes/PrometheionEventPublisher.cls \
  --source-dir force-app/main/default/classes/PrometheionEventPublisher.cls-meta.xml \
  --source-dir force-app/main/default/classes/PrometheionAuditTrailPoller.cls \
  --source-dir force-app/main/default/classes/PrometheionAuditTrailPoller.cls-meta.xml \
  --source-dir force-app/main/default/classes/PrometheionScoreCallback.cls \
  --source-dir force-app/main/default/classes/PrometheionScoreCallback.cls-meta.xml \
  -o prod-org
```

### 1.3 Deploy Trigger

```bash
sf project deploy start \
  --source-dir force-app/main/default/triggers/PermissionSetAssignmentTrigger.trigger \
  --source-dir force-app/main/default/triggers/PermissionSetAssignmentTrigger.trigger-meta.xml \
  -o prod-org
```

### 1.4 Deploy LWC Components

```bash
sf project deploy start \
  --source-dir force-app/main/default/lwc/prometheionScoreListener \
  --source-dir force-app/main/default/lwc/prometheionDashboard \
  -o prod-org
```

### 1.5 Run Tests

```bash
# Run test classes
sf apex run test \
  --class-names PrometheionEventPublisherTest,PrometheionAuditTrailPollerTest,PrometheionScoreCallbackTest \
  --result-format human \
  --code-coverage \
  -o prod-org
```

## Step 2: Configure Salesforce Event Relay

### 2.1 Create Event Relay

1. Navigate to **Setup** → **Integrations** → **Event Relays**
2. Click **New Event Relay**
3. Configure:
   - **Name**: `Prometheion_AWS_Relay`
   - **Source Event**: `Prometheion_Raw_Event__e`
   - **Destination Type**: `Amazon EventBridge`
   - **Event Bus ARN**: (You'll get this from AWS in Step 3)
   - **Region**: `us-east-1` (or your preferred region)

### 2.2 Enable Event Relay

1. After creating the Event Relay, click **Enable**
2. Note the **Event Relay ID** (you'll need this for AWS configuration)

## Step 3: Set Up AWS Infrastructure

### 3.1 Create AWS Resources

Use the Terraform configuration or AWS Console to create:

1. **Amazon EventBridge Custom Bus**
   - Name: `prometheion-events`
   - Region: `us-east-1`

2. **Amazon Kinesis Firehose Delivery Stream**
   - Name: `prometheion-events-stream`
   - Destination: S3 bucket `prometheion-events`
   - Buffer size: 1 MB
   - Buffer interval: 60 seconds

3. **Amazon S3 Bucket**
   - Name: `prometheion-events` (must be globally unique)
   - Region: `us-east-1`
   - Enable versioning: Yes
   - Lifecycle policy: Move to Glacier after 90 days

4. **Amazon DynamoDB Table**
   - Name: `prometheion-scores`
   - Partition Key: `PK` (String)
   - Sort Key: `SK` (String)
   - Billing: On-demand

5. **AWS Lambda Functions** (see Step 4)

### 3.2 Configure EventBridge Rule

Create an EventBridge rule that:
- **Source**: `salesforce.prometheion`
- **Target**: Kinesis Firehose delivery stream
- **Pattern**: Match all events from Salesforce

## Step 4: Deploy AWS Lambda Functions

### 4.1 Event Processor Lambda

Create `lambda/event_processor.py` (see TECHNICAL_DEEP_DIVE.md Section 4.7)

Deploy:
```bash
cd lambda
zip -r event_processor.zip event_processor.py
aws lambda create-function \
  --function-name prometheion-event-processor \
  --runtime python3.11 \
  --role arn:aws:iam::ACCOUNT_ID:role/lambda-execution-role \
  --handler event_processor.lambda_handler \
  --zip-file fileb://event_processor.zip \
  --timeout 300 \
  --memory-size 512
```

### 4.2 Compliance Scorer Lambda

Create `lambda/compliance_scorer.py` (see TECHNICAL_DEEP_DIVE.md Section 4.8)

Deploy:
```bash
zip -r compliance_scorer.zip compliance_scorer.py
aws lambda create-function \
  --function-name prometheion-compliance-scorer \
  --runtime python3.11 \
  --role arn:aws:iam::ACCOUNT_ID:role/lambda-execution-role \
  --handler compliance_scorer.lambda_handler \
  --zip-file fileb://compliance_scorer.zip \
  --timeout 300 \
  --memory-size 512 \
  --environment Variables="{
    ANTHROPIC_API_KEY=your-api-key,
    SALESFORCE_INSTANCE_URL=https://yourinstance.salesforce.com,
    SCORES_TABLE=prometheion-scores
  }"
```

### 4.3 Configure Lambda Triggers

- **Event Processor**: Triggered by Kinesis Firehose (automatic)
- **Compliance Scorer**: Invoked by Event Processor (async)

## Step 5: Configure Salesforce OAuth for Lambda Callback

### 5.1 Create Connected App

1. Navigate to **Setup** → **App Manager** → **New Connected App**
2. Configure:
   - **Name**: `Prometheion AWS Lambda`
   - **API Name**: `Prometheion_AWS_Lambda`
   - **Enable OAuth Settings**: Yes
   - **Callback URL**: `https://lambda-url.amazonaws.com/callback`
   - **Selected OAuth Scopes**: 
     - `Full access (full)`
     - `Perform requests on your behalf at any time (refresh_token, offline_access)`

3. Save and note the **Consumer Key** and **Consumer Secret**

### 5.2 Store Credentials in AWS Secrets Manager

```bash
aws secretsmanager create-secret \
  --name prometheion/sf-oauth/ORG_ID \
  --secret-string '{
    "consumer_key": "YOUR_CONSUMER_KEY",
    "consumer_secret": "YOUR_CONSUMER_SECRET",
    "instance_url": "https://yourinstance.salesforce.com"
  }'
```

### 5.3 Update Lambda Environment Variables

Add to Compliance Scorer Lambda:
- `SALESFORCE_CONSUMER_KEY`: (from Connected App)
- `SALESFORCE_CONSUMER_SECRET`: (from Connected App)
- `SALESFORCE_INSTANCE_URL`: Your Salesforce instance URL

## Step 6: Schedule Audit Trail Poller

### 6.1 Schedule via Anonymous Apex

Execute in **Developer Console** → **Anonymous Apex**:

```apex
// Schedule the audit trail poller to run every 5 minutes
String jobId = PrometheionAuditTrailPoller.schedule();
System.debug('Scheduled job: ' + jobId);
```

### 6.2 Verify Schedule

1. Navigate to **Setup** → **Apex Jobs**
2. Find "Prometheion Audit Trail Poller"
3. Verify it's scheduled and running

## Step 7: Test End-to-End Flow

### 7.1 Test Event Publishing

Execute in **Developer Console** → **Anonymous Apex**:

```apex
// Publish a test event
PrometheionEventPublisher.publishConfigChange(
    'PermissionSet',
    '0PS000000000000AAA',
    'MODIFIED',
    'Test User'
);
```

### 7.2 Verify Event in AWS

1. Check **Amazon EventBridge** → **Events** → Recent events
2. Verify event appears with source `salesforce.prometheion`

### 7.3 Verify S3 Storage

1. Check **Amazon S3** → `prometheion-events` bucket
2. Verify events are being written (may take up to 60 seconds due to Firehose buffering)

### 7.4 Test Lambda Callback

Manually invoke Compliance Scorer Lambda with test payload:

```json
{
  "orgId": "YOUR_ORG_ID",
  "entityType": "PermissionSet",
  "entityId": "0PS000000000000AAA",
  "riskScore": 75.5,
  "frameworkScores": {
    "HIPAA": 80.0,
    "SOC2": 70.0
  }
}
```

### 7.5 Verify Salesforce Record

1. Navigate to **Compliance Score** tab (if created)
2. Query: `SELECT Id, Risk_Score__c FROM Compliance_Score__c WHERE Entity_Type__c = 'PermissionSet'`
3. Verify record was created/updated

### 7.6 Test Real-Time UI Updates

1. Open **Prometheion Dashboard** in Lightning App
2. Assign a Permission Set to a user (triggers event)
3. Wait 30-60 seconds for Lambda processing
4. Verify toast notification appears with updated score

## Step 8: Monitor and Troubleshoot

### 8.1 Monitor Event Publishing

**Salesforce Debug Logs:**
- Filter: `PrometheionEventPublisher`
- Look for: "Published event for..." messages

### 8.2 Monitor AWS Lambda

**CloudWatch Logs:**
- `/aws/lambda/prometheion-event-processor`
- `/aws/lambda/prometheion-compliance-scorer`

**Common Issues:**
- **Lambda timeout**: Increase timeout to 5 minutes
- **Permission errors**: Check IAM roles and policies
- **OAuth errors**: Verify Connected App credentials

### 8.3 Monitor Event Relay

**Salesforce Setup** → **Event Relays** → **Prometheion_AWS_Relay**
- Check **Status**: Should be "Enabled"
- Check **Last Event**: Should show recent timestamp
- Check **Error Count**: Should be 0

## Step 9: Production Checklist

- [ ] All metadata deployed to production
- [ ] Event Relay configured and enabled
- [ ] AWS infrastructure created (EventBridge, Kinesis, S3, DynamoDB, Lambda)
- [ ] Lambda functions deployed with correct environment variables
- [ ] OAuth Connected App created and credentials stored in AWS Secrets Manager
- [ ] Audit Trail Poller scheduled
- [ ] End-to-end test completed successfully
- [ ] Monitoring and alerting configured (CloudWatch alarms)
- [ ] Documentation updated with production URLs and ARNs

## Next Steps

Once Phase 1 is complete:
1. **Build Event Intelligence Engine** (Section 1) on AWS Lambda
2. **Build Configuration Drift Guard** (Section 2) using S3 data lake
3. **Build Evidence Engine** (Section 3) using DynamoDB + S3

All future features will be built off-platform from day one! ✅

## Support

For issues or questions:
- Check `TECHNICAL_DEEP_DIVE.md` Section 4 for architecture details
- Review CloudWatch logs for Lambda errors
- Check Salesforce Debug Logs for Apex errors
- Verify Event Relay status in Salesforce Setup

