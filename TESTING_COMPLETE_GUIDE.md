# Complete Testing Guide: Postman & Python

## Quick Start

### 1. Python - Simplest Test
```bash
# Install dependencies
pip install requests

# Run quick test
python quick_test.py
```

### 2. Postman - Import & Run
1. Open Postman
2. Import → Upload Files → Select `RCS_Testing.postman_collection.json`
3. Click "Send" on any request

## Python Testing Options

### Option 1: Simple Script (quick_test.py)
```bash
python quick_test.py
# Choose:
# 1 - Send single message
# 2 - Run test sequence
```

### Option 2: Advanced Tool (test_rcs.py)
```bash
# Install requirements
pip install -r test_requirements.txt

# Run different tests
python test_rcs.py --message "Hello"              # Send single message
python test_rcs.py --test                         # Run full sequence
python test_rcs.py --load 10                      # Load test with 10 messages
python test_rcs.py --check                        # Check Firebase messages
python test_rcs.py --listen                       # Start real-time listener
```

### Option 3: Direct Python Commands
```python
import requests
import json
import time
import uuid

# Send a message
url = "https://dashmessaging-com.ngrok.io/scheduler/mobile-app"
payload = {
    "userId": "49804",
    "messageId": str(uuid.uuid4()),
    "messageText": "Test from Python",
    "messageTime": int(time.time()),
    "eventTypeCode": 1,
    "fcmToken": "eLjQWERyTm2Kltsqxahvw6:APA91bFqgowOQxoeOpZuf9wMsUQczuxBBZZim_yo-r_j9H_SMKqU4HLuioUUgI028IRpUG5SObBY3Fp4HiJIkTNsLkrKPEgWEo2UWVvMa81mPIVdM0WEuV0"
}

response = requests.post(url, json=payload)
print(f"Status: {response.status_code}")
print(f"Response: {response.text}")
```

## Postman Testing Options

### Basic Request
1. Open "Send Text Message" request
2. Click "Send"
3. Check response in bottom panel

### Automated Testing
1. Click "Runner" (top right)
2. Select "RCS Application Testing" collection
3. Set iterations: 10
4. Set delay: 2000ms
5. Click "Run"

### Environment Variables
Create environment with:
- `SERVER_URL`: The ngrok URL
- `FCM_TOKEN`: The FCM token
- `USER_ID`: Default user ID (49804)

### Newman CLI
```bash
# Install Newman
npm install -g newman

# Run collection
newman run RCS_Testing.postman_collection.json -n 10 --delay-request 2000
```

## Testing Scenarios

### 1. Basic Message Flow
```
Send "Hello" → Check server response → Verify in Firebase
```

### 2. Enrollment Sequence
```
1. Send "start"
2. Wait for response
3. Send "1-9" 
4. Send "Yes, let's do it!"
5. Send "10:00"
```

### 3. Load Testing
```python
# Python
python test_rcs.py --load 50

# Postman
Collection Runner with 50 iterations
```

### 4. Real-time Monitoring
```python
# Start listener in one terminal
python test_rcs.py --listen

# Send messages in another terminal
python test_rcs.py --message "Test message"
```

## Expected Results

### Server Response
```json
{
  "status": "success",
  "messageId": "uuid-here",
  "timestamp": 1234567890
}
```

### Firebase Message Structure
```json
{
  "serverMessageId": "uuid-here",
  "messageBody": "Your message text",
  "createdAt": 1234567890,
  "source": "server",
  "recipientId": "49804",
  "isPoll": false
}
```

## Performance Benchmarks

- **Response Time**: < 500ms average
- **Success Rate**: > 99%
- **Firebase Delivery**: < 2 seconds
- **Load Capacity**: 100+ messages/minute

## Troubleshooting

### Connection Refused
- Check if ngrok URL is active
- Verify server is running

### 404 Not Found
- Check URL path: `/scheduler/mobile-app`
- Verify server endpoints

### No Firebase Updates
- Check user ID mapping
- Verify Firebase credentials
- Check collection path: `messages/{userId}/chat`

### Timeout Errors
- Increase timeout in requests
- Check network connection
- Verify server performance

## User ID Mappings

| Participant ID | Firebase ID |
|----------------|-------------|
| 49804 | pUuutN05eoVeWhsKyXBiwRoFW9u1 |
| 49866 | SFnPqWN8wYaDZ5PUnvGqNDPEKjn2 |
| 49919 | lHJf27tJirM6sWYwngdMGn9PSPR2 |
| 49938 | pDDlS8xuEhSLYJmNDVf7ZKBWQMU2 |

## Quick Commands Reference

```bash
# Python - Send message
python -c "import requests; print(requests.post('https://dashmessaging-com.ngrok.io/scheduler/mobile-app', json={'userId':'49804','messageId':'test','messageText':'Hello','messageTime':1234567890,'eventTypeCode':1,'fcmToken':'eLjQWERyTm2Kltsqxahvw6:APA91bFqgowOQxoeOpZuf9wMsUQczuxBBZZim_yo-r_j9H_SMKqU4HLuioUUgI028IRpUG5SObBY3Fp4HiJIkTNsLkrKPEgWEo2UWVvMa81mPIVdM0WEuV0'}).status_code)"

# cURL - Send message
curl -X POST https://dashmessaging-com.ngrok.io/scheduler/mobile-app \
  -H "Content-Type: application/json" \
  -d '{"userId":"49804","messageId":"test","messageText":"Hello","messageTime":1234567890,"eventTypeCode":1,"fcmToken":"eLjQWERyTm2Kltsqxahvw6:APA91bFqgowOQxoeOpZuf9wMsUQczuxBBZZim_yo-r_j9H_SMKqU4HLuioUUgI028IRpUG5SObBY3Fp4HiJIkTNsLkrKPEgWEo2UWVvMa81mPIVdM0WEuV0"}'
```

## Next Steps

1. Start with `quick_test.py` for simple testing
2. Use Postman for visual testing
3. Use `test_rcs.py` for advanced scenarios
4. Monitor Firebase Console for real-time updates
