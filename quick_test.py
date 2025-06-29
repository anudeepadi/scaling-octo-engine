#!/usr/bin/env python3
"""
Simple RCS Message Tester
Quick script to test sending and receiving messages
"""

import requests
import json
import time
import uuid

# Server configuration
SERVER_URL = "https://dashmessaging-com.ngrok.io/scheduler/mobile-app"
FCM_TOKEN = "eLjQWERyTm2Kltsqxahvw6:APA91bFqgowOQxoeOpZuf9wMsUQczuxBBZZim_yo-r_j9H_SMKqU4HLuioUUgI028IRpUG5SObBY3Fp4HiJIkTNsLkrKPEgWEo2UWVvMa81mPIVdM0WEuV0"

def send_message(user_id="49804", text="Hello from Python!"):
    """Send a simple message to the server"""
    
    payload = {
        "userId": user_id,
        "messageId": str(uuid.uuid4()),
        "messageText": text,
        "messageTime": int(time.time()),
        "eventTypeCode": 1,
        "fcmToken": FCM_TOKEN
    }
    
    print(f"\n📤 Sending: {text}")
    print(f"   To user: {user_id}")
    
    try:
        response = requests.post(
            SERVER_URL,
            json=payload,
            headers={'Content-Type': 'application/json'},
            timeout=10
        )
        
        if response.status_code == 200:
            print(f"✅ Success! Status: {response.status_code}")
            print(f"📥 Response: {response.text}")
            return True
        else:
            print(f"❌ Failed! Status: {response.status_code}")
            print(f"   Error: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

def test_sequence():
    """Run a simple test sequence"""
    print("🚀 Starting RCS Message Test")
    print("=" * 40)
    
    # Test messages
    messages = [
        "Hello from Python test!",
        "Testing message " + str(int(time.time())),
        "How are you today?",
        "start",
        "1-9",
        "Yes, let's do it!"
    ]
    
    success_count = 0
    
    for i, msg in enumerate(messages, 1):
        print(f"\nTest {i}/{len(messages)}")
        if send_message(text=msg):
            success_count += 1
        
        # Wait between messages
        if i < len(messages):
            print("⏳ Waiting 2 seconds...")
            time.sleep(2)
    
    print("\n" + "=" * 40)
    print(f"✅ Test Complete!")
    print(f"   Sent: {len(messages)}")
    print(f"   Success: {success_count}")
    print(f"   Failed: {len(messages) - success_count}")

def quick_test():
    """Send a single test message"""
    message = input("Enter message (or press Enter for default): ").strip()
    if not message:
        message = f"Test message at {time.strftime('%H:%M:%S')}"
    
    user_id = input("Enter user ID (or press Enter for 49804): ").strip()
    if not user_id:
        user_id = "49804"
    
    send_message(user_id, message)

if __name__ == "__main__":
    print("RCS Message Tester")
    print("1. Quick test (single message)")
    print("2. Test sequence (multiple messages)")
    
    choice = input("\nEnter choice (1 or 2): ").strip()
    
    if choice == "1":
        quick_test()
    elif choice == "2":
        test_sequence()
    else:
        print("Invalid choice. Running quick test...")
        quick_test()
