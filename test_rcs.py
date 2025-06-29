#!/usr/bin/env python3
"""
RCS Application Testing Script
Tests message sending and retrieval with Firebase monitoring
"""

import requests
import json
import time
import uuid
import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime
import threading
import argparse
from colorama import init, Fore, Style

# Initialize colorama for colored output
init()

# Configuration
SERVER_URL = "https://dashmessaging-com.ngrok.io/scheduler/mobile-app"
FCM_TOKEN = "eLjQWERyTm2Kltsqxahvw6:APA91bFqgowOQxoeOpZuf9wMsUQczuxBBZZim_yo-r_j9H_SMKqU4HLuioUUgI028IRpUG5SObBY3Fp4HiJIkTNsLkrKPEgWEo2UWVvMa81mPIVdM0WEuV0"
FIREBASE_CREDS_PATH = "/Users/vuc229/Downloads/Projects/rcs_application/quitxtmobile-firebase-adminsdk-ud7bj-856f7be8e1.json"

# User mappings
USER_MAPPINGS = {
    "49804": "pUuutN05eoVeWhsKyXBiwRoFW9u1",
    "49866": "SFnPqWN8wYaDZ5PUnvGqNDPEKjn2",
    "49919": "lHJf27tJirM6sWYwngdMGn9PSPR2",
    "49938": "pDDlS8xuEhSLYJmNDVf7ZKBWQMU2"
}

class RCSTestingTool:
    def __init__(self):
        """Initialize the testing tool with Firebase"""
        self.init_firebase()
        self.db = firestore.client()
        self.listener = None
        self.message_count = 0
        self.received_messages = []
        
    def init_firebase(self):
        """Initialize Firebase if not already initialized"""
        try:
            firebase_admin.get_app()
        except ValueError:
            cred = credentials.Certificate(FIREBASE_CREDS_PATH)
            firebase_admin.initialize_app(cred)
            print(f"{Fore.GREEN}✓ Firebase initialized{Style.RESET_ALL}")
    
    def send_message(self, user_id, message_text, event_type=1):
        """Send a message to the server"""
        message_id = str(uuid.uuid4())
        timestamp = int(time.time())
        
        payload = {
            "userId": user_id,
            "messageId": message_id,
            "messageText": message_text,
            "messageTime": timestamp,
            "eventTypeCode": event_type,
            "fcmToken": FCM_TOKEN
        }
        
        print(f"\n{Fore.CYAN}📤 Sending message:{Style.RESET_ALL}")
        print(f"   User: {user_id}")
        print(f"   Text: {message_text}")
        print(f"   ID: {message_id}")
        
        try:
            start_time = time.time()
            response = requests.post(
                SERVER_URL,
                json=payload,
                headers={
                    'Content-Type': 'application/json',
                    'Accept': 'application/json',
                    'User-Agent': 'RCS-Testing/1.0'
                },
                timeout=10
            )
            elapsed = (time.time() - start_time) * 1000
            
            if response.status_code == 200:
                print(f"{Fore.GREEN}✓ Success!{Style.RESET_ALL} ({elapsed:.0f}ms)")
                try:
                    data = response.json()
                    if data:
                        print(f"   Response: {json.dumps(data, indent=2)}")
                except:
                    pass
                return True, message_id
            else:
                print(f"{Fore.RED}✗ Failed!{Style.RESET_ALL} Status: {response.status_code}")
                return False, message_id
                
        except Exception as e:
            print(f"{Fore.RED}✗ Error: {e}{Style.RESET_ALL}")
            return False, message_id
    
    def start_firebase_listener(self, external_id):
        """Start listening for Firebase messages"""
        print(f"\n{Fore.YELLOW}👂 Starting Firebase listener for: {external_id}{Style.RESET_ALL}")
        
        def on_snapshot(doc_snapshot, changes, read_time):
            for change in changes:
                if change.type.name == 'ADDED':
                    doc = change.document
                    data = doc.to_dict()
                    self.message_count += 1
                    
                    print(f"\n{Fore.GREEN}📨 New message received!{Style.RESET_ALL}")
                    print(f"   ID: {data.get('serverMessageId', 'N/A')}")
                    print(f"   Body: {data.get('messageBody', 'N/A')}")
                    print(f"   Time: {datetime.now().strftime('%H:%M:%S')}")
                    
                    if data.get('isPoll'):
                        print(f"   Type: Quick Reply Poll")
                        if data.get('questionsAnswers'):
                            print(f"   Options: {data.get('questionsAnswers')}")
                    
                    self.received_messages.append(data)
        
        # Create query for real-time updates
        query = self.db.collection('messages').document(external_id).collection('chat')
        query = query.order_by('createdAt', direction=firestore.Query.DESCENDING).limit(10)
        
        # Start listening
        self.listener = query.on_snapshot(on_snapshot)
        print(f"{Fore.GREEN}✓ Listener active{Style.RESET_ALL}")
    
    def stop_listener(self):
        """Stop the Firebase listener"""
        if self.listener:
            self.listener.unsubscribe()
            print(f"\n{Fore.YELLOW}Listener stopped{Style.RESET_ALL}")
    
    def check_firebase_messages(self, external_id, limit=5):
        """Check current messages in Firebase"""
        print(f"\n{Fore.CYAN}🔍 Checking Firebase messages for: {external_id}{Style.RESET_ALL}")
        
        try:
            docs = self.db.collection('messages').document(external_id).collection('chat')\
                .order_by('createdAt', direction=firestore.Query.DESCENDING)\
                .limit(limit).get()
            
            if not docs:
                print("   No messages found")
                return []
            
            messages = []
            for doc in docs:
                data = doc.to_dict()
                timestamp = data.get('createdAt', 0)
                if isinstance(timestamp, int):
                    time_str = datetime.fromtimestamp(timestamp).strftime('%Y-%m-%d %H:%M:%S')
                else:
                    time_str = "Unknown"
                
                print(f"\n   Message: {data.get('serverMessageId', 'N/A')}")
                print(f"   Time: {time_str}")
                print(f"   Body: {data.get('messageBody', 'N/A')[:100]}")
                messages.append(data)
            
            return messages
        except Exception as e:
            print(f"{Fore.RED}Error checking Firebase: {e}{Style.RESET_ALL}")
            return []
    
    def run_test_sequence(self, user_id):
        """Run a complete test sequence"""
        external_id = USER_MAPPINGS.get(user_id)
        if not external_id:
            print(f"{Fore.RED}Unknown user ID: {user_id}{Style.RESET_ALL}")
            return
        
        print(f"\n{Fore.CYAN}=== Starting Test Sequence ==={Style.RESET_ALL}")
        print(f"Participant ID: {user_id}")
        print(f"External ID: {external_id}")
        
        # Start listener
        self.start_firebase_listener(external_id)
        time.sleep(2)
        
        # Test messages
        test_messages = [
            ("start", 1),
            ("Hello from Python test", 1),
            ("1-9", 2),
            ("Yes, let's do it!", 2),
            ("10:00", 1)
        ]
        
        results = []
        for msg, event_type in test_messages:
            success, msg_id = self.send_message(user_id, msg, event_type)
            results.append((msg, success))
            time.sleep(3)  # Wait between messages
        
        # Wait for responses
        print(f"\n{Fore.YELLOW}Waiting for Firebase responses...{Style.RESET_ALL}")
        time.sleep(10)
        
        # Summary
        print(f"\n{Fore.CYAN}=== Test Summary ==={Style.RESET_ALL}")
        print(f"Messages sent: {len(test_messages)}")
        print(f"Successful: {sum(1 for _, s in results if s)}")
        print(f"Firebase messages received: {self.message_count}")
        
        # Stop listener
        self.stop_listener()
    
    def load_test(self, user_id, count=10, delay=1):
        """Run a load test"""
        print(f"\n{Fore.CYAN}=== Load Test ==={Style.RESET_ALL}")
        print(f"Sending {count} messages with {delay}s delay")
        
        successes = 0
        failures = 0
        response_times = []
        
        for i in range(count):
            message = f"Load test message {i+1}/{count} at {datetime.now().strftime('%H:%M:%S')}"
            
            start = time.time()
            success, _ = self.send_message(user_id, message)
            elapsed = (time.time() - start) * 1000
            response_times.append(elapsed)
            
            if success:
                successes += 1
            else:
                failures += 1
            
            if i < count - 1:
                time.sleep(delay)
        
        # Statistics
        avg_time = sum(response_times) / len(response_times)
        min_time = min(response_times)
        max_time = max(response_times)
        
        print(f"\n{Fore.CYAN}=== Load Test Results ==={Style.RESET_ALL}")
        print(f"Total: {count}")
        print(f"Success: {successes} ({successes/count*100:.1f}%)")
        print(f"Failed: {failures}")
        print(f"Avg Response: {avg_time:.0f}ms")
        print(f"Min Response: {min_time:.0f}ms")
        print(f"Max Response: {max_time:.0f}ms")

def main():
    parser = argparse.ArgumentParser(description='RCS Application Testing Tool')
    parser.add_argument('--user', default='49804', help='User ID to test with')
    parser.add_argument('--message', help='Custom message to send')
    parser.add_argument('--test', action='store_true', help='Run full test sequence')
    parser.add_argument('--load', type=int, help='Run load test with N messages')
    parser.add_argument('--check', action='store_true', help='Just check Firebase messages')
    parser.add_argument('--listen', action='store_true', help='Start real-time listener')
    
    args = parser.parse_args()
    
    tool = RCSTestingTool()
    
    try:
        if args.check:
            external_id = USER_MAPPINGS.get(args.user)
            if external_id:
                tool.check_firebase_messages(external_id)
        
        elif args.listen:
            external_id = USER_MAPPINGS.get(args.user)
            if external_id:
                tool.start_firebase_listener(external_id)
                print("Press Ctrl+C to stop...")
                while True:
                    time.sleep(1)
        
        elif args.load:
            tool.load_test(args.user, args.load)
        
        elif args.test:
            tool.run_test_sequence(args.user)
        
        elif args.message:
            tool.send_message(args.user, args.message)
            external_id = USER_MAPPINGS.get(args.user)
            if external_id:
                time.sleep(3)
                tool.check_firebase_messages(external_id, limit=3)
        
        else:
            # Interactive mode
            print(f"{Fore.CYAN}RCS Testing Tool - Interactive Mode{Style.RESET_ALL}")
            print("\nOptions:")
            print("1. Send single message")
            print("2. Run test sequence")
            print("3. Load test")
            print("4. Check Firebase")
            print("5. Start listener")
            print("6. Exit")
            
            while True:
                choice = input(f"\n{Fore.YELLOW}Enter choice (1-6): {Style.RESET_ALL}")
                
                if choice == '1':
                    msg = input("Enter message: ")
                    tool.send_message(args.user, msg)
                elif choice == '2':
                    tool.run_test_sequence(args.user)
                elif choice == '3':
                    count = int(input("Number of messages: "))
                    tool.load_test(args.user, count)
                elif choice == '4':
                    external_id = USER_MAPPINGS.get(args.user)
                    if external_id:
                        tool.check_firebase_messages(external_id)
                elif choice == '5':
                    external_id = USER_MAPPINGS.get(args.user)
                    if external_id:
                        tool.start_firebase_listener(external_id)
                elif choice == '6':
                    break
                    
    except KeyboardInterrupt:
        print(f"\n{Fore.YELLOW}Shutting down...{Style.RESET_ALL}")
    finally:
        tool.stop_listener()

if __name__ == "__main__":
    main()
