# Postman & Python Testing Guide for RCS Application

## Overview
Test the messaging flow:
1. Send messages to the server
2. Monitor Firebase for message delivery
3. Verify message retrieval

## Server Endpoint Details
- **URL**: `https://dashmessaging-com.ngrok.io/scheduler/mobile-app`
- **Method**: POST
- **Content-Type**: application/json

## 1. Postman Setup

### Create New Request
1. Open Postman
2. Create new POST request
3. URL: `https://dashmessaging-com.ngrok.io/scheduler/mobile-app`

### Headers
```
Content-Type: application/json
Accept: application/json
User-Agent: QuitTXT-Mobile/1.0
```

### Request Body (raw JSON)
```json
{
  "userId": "49804",
  "messageId": "{{$guid}}",
  "messageText": "Test message from Postman",
  "messageTime": {{$timestamp}},
  "eventTypeCode": 1,
  "fcmToken": "eLjQWERyTm2Kltsqxahvw6:APA91bFqgowOQxoeOpZuf9wMsUQczuxBBZZim_yo-r_j9H_SMKqU4HLuioUUgI028IRpUG5SObBY3Fp4HiJIkTNsLkrKPEgWEo2UWVvMa81mPIVdM0WEuV0"
}
```

### Postman Environment Variables
Create environment with:
```
SERVER_URL: https://dashmessaging-com.ngrok.io/scheduler/mobile-app
FCM_TOKEN: eLjQWERyTm2Kltsqxahvw6:APA91bFqgowOQxoeOpZuf9wMsUQczuxBBZZim_yo-r_j9H_SMKqU4HLuioUUgI028IRpUG5SObBY3Fp4HiJIkTNsLkrKPEgWEo2UWVvMa81mPIVdM0WEuV0
USER_ID: 49804
```

### Test Scripts (Tests Tab)
```javascript
pm.test("Status code is 200", function () {
    pm.response.to.have.status(200);
});

pm.test("Response time is less than 2000ms", function () {
    pm.expect(pm.response.responseTime).to.be.below(2000);
});

pm.test("Response has message", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData).to.have.property('message');
});

// Save response for next request
if (pm.response.code === 200) {
    var response = pm.response.json();
    pm.environment.set("last_server_message_id", response.serverMessageId);
}
```

### Pre-request Script
```javascript
// Generate unique message ID
pm.variables.set("messageId", require('uuid').v4());

// Set current timestamp
pm.variables.set("timestamp", Math.floor(Date.now() / 1000));

// Rotate through test messages
const testMessages = [
    "Hello from Postman",
    "Test message " + new Date().toISOString(),
    "How are you today?",
    "Testing quick reply",
    "1-9"
];
const randomMessage = testMessages[Math.floor(Math.random() * testMessages.length)];
pm.variables.set("messageText", randomMessage);
```

## 2. Postman Collection

Save this as `RCS_Testing.postman_collection.json`:
```json
{
  "info": {
    "name": "RCS Application Testing",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "item": [
    {
      "name": "Send Message",
      "request": {
        "method": "POST",
        "header": [
          {
            "key": "Content-Type",
            "value": "application/json"
          }
        ],
        "body": {
          "mode": "raw",
          "raw": "{\n  \"userId\": \"{{USER_ID}}\",\n  \"messageId\": \"{{$guid}}\",\n  \"messageText\": \"{{messageText}}\",\n  \"messageTime\": {{$timestamp}},\n  \"eventTypeCode\": 1,\n  \"fcmToken\": \"{{FCM_TOKEN}}\"\n}"
        },
        "url": {
          "raw": "{{SERVER_URL}}",
          "host": ["{{SERVER_URL}}"]
        }
      }
    },
    {
      "name": "Send Quick Reply",
      "request": {
        "method": "POST",
        "header": [
          {
            "key": "Content-Type",
            "value": "application/json"
          }
        ],
        "body": {
          "mode": "raw",
          "raw": "{\n  \"userId\": \"{{USER_ID}}\",\n  \"messageId\": \"{{$guid}}\",\n  \"messageText\": \"Yes\",\n  \"messageTime\": {{$timestamp}},\n  \"eventTypeCode\": 2,\n  \"fcmToken\": \"{{FCM_TOKEN}}\"\n}"
        },
        "url": {
          "raw": "{{SERVER_URL}}",
          "host": ["{{SERVER_URL}}"]
        }
      }
    }
  ]
}
```

## 3. Running Tests in Postman

### Manual Testing
1. Send single message
2. Check response
3. Monitor Firebase console

### Automated Testing (Collection Runner)
1. Click "Runner" in Postman
2. Select collection
3. Set iterations (e.g., 10)
4. Set delay (e.g., 2000ms)
5. Run collection

### Newman CLI Testing
```bash
# Install Newman
npm install -g newman

# Run collection
newman run RCS_Testing.postman_collection.json \
  -e RCS_Testing.postman_environment.json \
  -n 10 \
  --delay-request 2000
```

## 4. Monitoring Firebase

### Using Firebase Console
1. Go to Firebase Console → Firestore
2. Navigate to: `messages/{userId}/chat`
3. Watch for new documents

### Using Postman to Check Firebase
Create a GET request with Firebase REST API:
```
GET https://firestore.googleapis.com/v1/projects/YOUR_PROJECT_ID/databases/(default)/documents/messages/USER_ID/chat
```

Headers:
```
Authorization: Bearer YOUR_FIREBASE_TOKEN
```

## 5. Complete Test Flow

1. **Send Message** → Check server response
2. **Wait 2-3 seconds** → Check Firebase
3. **Verify message fields**:
   - serverMessageId
   - messageBody
   - createdAt
   - source
   - isPoll (for quick replies)

## 6. Load Testing

### Using Postman
1. Collection Runner with high iterations
2. Monitor response times
3. Check for errors

### Expected Results
- Response time: < 500ms average
- Success rate: > 99%
- Firebase delivery: < 2 seconds
