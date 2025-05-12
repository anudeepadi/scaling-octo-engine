import requests
import json
import time
import uuid
import argparse
from datetime import datetime

def create_new_test_user(host, fcm_token=None):
    """Create a completely new test user and test the full enrollment flow."""
    
    # Generate a new unique external ID (user ID)
    new_user_id = "TEST_" + str(uuid.uuid4()).replace("-", "")[:16]
    
    # Use the provided FCM token or a default
    if not fcm_token:
        fcm_token = "eLjQWERyTm2Kltsqxahvw6:APA91bFqgowOQxoeOpZuf9wMsUQczuxBBZZim_yo-r_j9H_SMKqU4HLuioUUgI028IRpUG5SObBY3Fp4HiJIkTNsLkrKPEgWEo2UWVvMa81mPIVdM0WEuV0"
    
    print("\n===== Testing with New User =====")
    print(f"Generated User ID: {new_user_id}")
    print(f"FCM Token: {fcm_token[:20]}...")
    print(f"Host: {host}")
    
    # Create the endpoint URL
    endpoint = f"{host}/scheduler/mobile-app"
    
    # The enrollment sequence based on the message history
    enrollment_sequence = [
        {"message": "start", "description": "Start enrollment process", "delay": 0},
        {"message": "1-9", "description": "Respond to cigarette question", "delay": 10},
        {"message": "Yes, let us do it!", "description": "Confirm readiness to quit", "delay": 10},
        {"message": "10:00", "description": "Set preferred contact time", "delay": 5}
    ]
    
    for step in enrollment_sequence:
        # Create a unique message ID
        message_id = str(uuid.uuid4())
        
        # Get current time
        current_time = int(time.time())
        
        # Prepare payload
        payload = {
            "userId": new_user_id,
            "messageId": message_id,
            "messageText": step["message"],
            "messageTime": current_time,
            "eventTypeCode": 1,
            "fcmToken": fcm_token
        }
        
        print(f"\n\nSending: {step['message']} - {step['description']}")
        print(f"Payload: {json.dumps(payload, indent=2)}")
        
        try:
            # Send POST request
            response = requests.post(endpoint, json=payload, timeout=15)
            
            # Check if request was successful
            response.raise_for_status()
            
            # Try to parse response as JSON
            try:
                response_data = response.json()
                print(f"Server Response (JSON): {json.dumps(response_data, indent=2)}")
            except json.JSONDecodeError:
                if not response.text.strip():
                    print("Empty response from server (normal)")
                    print(f"The server should be processing the '{step['message']}' command")
                    print("Check the server history to see incoming/outgoing messages")
                else:
                    print(f"Server Response (text): {response.text}")
                
        except requests.exceptions.RequestException as e:
            print(f"Request failed: {e}")
        
        # Wait before sending the next message
        if step["delay"] > 0:
            print(f"Waiting {step['delay']} seconds before next message...")
            time.sleep(step["delay"])
    
    print("\n===== Enrollment Sequence Complete =====")
    print("Check the server's history page to see if your messages were received")
    print("And check the Firebase Console to see if outgoing messages were sent")
    print(f"User ID to watch for: {new_user_id}")
    return new_user_id

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Test DashMessaging enrollment with a new user')
    parser.add_argument('--host', type=str, default="https://dashmessaging-com.ngrok.io", 
                        help='Server host URL')
    parser.add_argument('--fcm-token', type=str, 
                        default="eLjQWERyTm2Kltsqxahvw6:APA91bFqgowOQxoeOpZuf9wMsUQczuxBBZZim_yo-r_j9H_SMKqU4HLuioUUgI028IRpUG5SObBY3Fp4HiJIkTNsLkrKPEgWEo2UWVvMa81mPIVdM0WEuV0",
                        help='Firebase Cloud Messaging token')
    
    args = parser.parse_args()
    create_new_test_user(args.host, args.fcm_token)