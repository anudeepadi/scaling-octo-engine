import requests
import json
import time
import uuid
import firebase_admin
from firebase_admin import credentials, firestore

# Configuration
SERVER_URL = "https://dashmessaging-com.ngrok.io/scheduler/mobile-app"
FCM_TOKEN = "eLjQWERyTm2Kltsqxahvw6:APA91bFqgowOQxoeOpZuf9wMsUQczuxBBZZim_yo-r_j9H_SMKqU4HLuioUUgI028IRpUG5SObBY3Fp4HiJIkTNsLkrKPEgWEo2UWVvMa81mPIVdM0WEuV0"
FIREBASE_CREDS_PATH = "/Users/vuc229/Downloads/Projects/rcs_application/quitxtmobile-firebase-adminsdk-ud7bj-856f7be8e1.json"

# Known participant ID to external ID mapping from your configuration
PARTICIPANT_MAPPING = {
    "49945": "test_user_1747247438",
    "49934": "TEST_2ce373f1ccd6414f",
    "49926": "TEST_594e17b5b06c43e4",
    "49922": "TEST_9a8382faaa7c43f0",
    "49921": "TEST_47c58d217cac4933",
    "49920": "TEST_c9da834924294a68",
    "49919": "lHJf27tJirM6sWYwngdMGn9PSPR2",
    "49866": "SFnPqWN8wYaDZ5PUnvGqNDPEKjn2",
    "49804": "pUuutN05eoVeWhsKyXBiwRoFW9u1",
    "49938": "pDDlS8xuEhSLYJmNDVf7ZKBWQMU2",
    "49937": "test_user_3b392910",
    "49936": "test_user_4f4ffd75",
    "49939": "Lzz23UevNktwWfocRJAQ"
}

# Create reverse mapping
EXTERNAL_ID_TO_PARTICIPANT = {v: k for k, v in PARTICIPANT_MAPPING.items()}

# Initialize Firebase
try:
    firebase_admin.get_app()
except ValueError:
    try:
        cred = credentials.Certificate(FIREBASE_CREDS_PATH)
        firebase_admin.initialize_app(cred)
        print("Firebase initialized successfully")
    except Exception as e:
        print(f"Error initializing Firebase: {e}")

db = firestore.client()

def send_message_to_server(user_id, message_text, use_external_id=False):
    """
    Send a message to the server.
    
    Args:
        user_id: Either a participant ID (49xxx) or an external ID (Firebase user ID)
        message_text: The message to send
        use_external_id: Set to True if user_id is an external ID (Firebase user ID)
    """
    # Convert external ID to participant ID if needed
    actual_user_id = user_id
    if use_external_id:
        if user_id in EXTERNAL_ID_TO_PARTICIPANT:
            actual_user_id = EXTERNAL_ID_TO_PARTICIPANT[user_id]
            print(f"Using participant ID {actual_user_id} for external ID {user_id}")
        else:
            print(f"Warning: No known participant ID for external ID {user_id}")
    
    # Show mapping info if using participant ID
    if not use_external_id and user_id in PARTICIPANT_MAPPING:
        print(f"Note: Participant ID {user_id} corresponds to external ID {PARTICIPANT_MAPPING[user_id]}")
    
    message_id = str(uuid.uuid4())
    message_time = int(time.time())
    
    payload = {
        "userId": actual_user_id,  # Always use the participant ID (49xxx) for the server
        "messageId": message_id,
        "messageText": message_text,
        "messageTime": message_time,
        "eventTypeCode": 1,
        "fcmToken": FCM_TOKEN
    }
    
    print(f"\nSending message to server:")
    print(f"  Message: {message_text}")
    print(f"  User ID (sending as): {actual_user_id}")
    
    try:
        response = requests.post(SERVER_URL, json=payload)
        print(f"  Status code: {response.status_code}")
        
        if response.status_code == 200:
            print("  SUCCESS: Message sent to server!")
            try:
                response_data = response.json()
                if response_data:
                    print(f"  Server response: {json.dumps(response_data, indent=2)}")
            except:
                pass
            return True
        else:
            print(f"  ERROR: Server returned status {response.status_code}")
            return False
    
    except Exception as e:
        print(f"  ERROR: Request failed - {e}")
        return False

def check_firebase_messages(external_id, limit=5):
    """Check for messages in Firebase for an external ID."""
    try:
        print(f"\nChecking Firebase messages for external ID: {external_id}")
        
        # Get reference to user's chat collection
        chat_ref = db.collection('messages').document(external_id).collection('chat')
        query = chat_ref.order_by('createdAt', direction=firestore.Query.DESCENDING).limit(limit)
        
        docs = query.get()
        if len(docs) == 0:
            print("No messages found in Firebase for this user.")
            return []
        
        print(f"Found {len(docs)} messages in Firebase:")
        for doc in docs:
            data = doc.to_dict()
            try:
                timestamp = data.get('createdAt')
                if timestamp:
                    if isinstance(timestamp, str):
                        timestamp = int(timestamp)
                    
                    if timestamp > 9999999999:
                        timestamp = timestamp / 1000.0
                    
                    time_str = time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(timestamp))
                else:
                    time_str = "No timestamp"
            except:
                time_str = "Error parsing timestamp"
            
            source = data.get('source', 'unknown')
            body = data.get('messageBody', '<No message body>')
            server_msg_id = data.get('serverMessageId', 'unknown')
            
            print(f"  Message ID: {server_msg_id}")
            print(f"  Time: {time_str}")
            print(f"  Source: {source}")
            print(f"  Content: {body}")
            print()
        
        return docs
    except Exception as e:
        print(f"Error checking Firebase messages: {e}")
        return []

def send_message_with_firebase_check():
    """Send message and check Firebase for responses."""
    print("\n=== SEND MESSAGE & CHECK FIREBASE ===")
    print("This will send a message to the server and check Firebase for responses.")
    
    # Show available mappings
    print("\nAvailable user mappings:")
    for participant_id, external_id in PARTICIPANT_MAPPING.items():
        print(f"  Participant ID: {participant_id}  →  External ID: {external_id}")
    
    # User selection
    print("\nSelect user to send as:")
    print("1. Use participant ID (49xxx format)")
    print("2. Use external ID (Firebase user ID)")
    
    id_choice = input("Enter choice (1-2): ")
    
    if id_choice == "1":
        user_id = input("Enter participant ID (e.g., 49804): ")
        use_external = False
        external_id = PARTICIPANT_MAPPING.get(user_id)
        if not external_id:
            print(f"Warning: No known external ID mapping for participant {user_id}")
            external_id = input("Enter external ID to check in Firebase (or leave blank): ")
    else:
        external_id = input("Enter external ID (e.g., pUuutN05eoVeWhsKyXBiwRoFW9u1): ")
        use_external = True
        user_id = external_id
    
    # Message to send
    print("\nSuggested commands:")
    print("- start (initiates welcome sequence)")
    print("- info (requests information)")
    print("- 1-9 (cigarette usage response)")
    print("- Yes, let us do it! (confirmation)")
    print("- 10:00 (time setting)")
    
    message = input("\nEnter message to send: ")
    
    # Send the message
    if send_message_to_server(user_id, message, use_external_id=use_external):
        print("\nMessage sent successfully!")
        
        # Check Firebase for current messages
        if external_id:
            print("\nChecking current messages in Firebase...")
            check_firebase_messages(external_id)
            
            # Ask to monitor for new messages
            monitor = input("\nMonitor for new messages in Firebase? (y/n): ")
            if monitor.lower() == 'y':
                wait_time = int(input("How many seconds to monitor? (recommended 120): ") or "120")
                
                print(f"\nMonitoring for new messages for {wait_time} seconds...")
                start_time = time.time()
                
                # Get current count to detect new messages
                current_docs = check_firebase_messages(external_id, limit=1)
                current_count = len(current_docs)
                
                while time.time() - start_time < wait_time:
                    elapsed = int(time.time() - start_time)
                    remaining = wait_time - elapsed
                    
                    print(f"Checking for new messages... ({elapsed}s elapsed, {remaining}s remaining)")
                    
                    new_docs = check_firebase_messages(external_id, limit=3)
                    if len(new_docs) > current_count:
                        print("\n🎉 New messages detected in Firebase!")
                        break
                    
                    time.sleep(10)  # Check every 10 seconds
                
                print("\nFinal message check:")
                check_firebase_messages(external_id)

def send_enrollment_sequence():
    """Send the complete enrollment sequence."""
    print("\n=== SEND COMPLETE ENROLLMENT SEQUENCE ===")
    print("This will send the 4-step enrollment sequence.")
    
    # User selection
    print("\nSelect how to identify the user:")
    print("1. Use existing participant ID")
    print("2. Use existing external ID")
    print("3. Use a new test user ID")
    
    id_choice = input("Enter choice (1-3): ")
    
    if id_choice == "1":
        user_id = input("Enter participant ID (e.g., 49804): ")
        use_external = False
        external_id = PARTICIPANT_MAPPING.get(user_id)
    elif id_choice == "2":
        external_id = input("Enter external ID (e.g., pUuutN05eoVeWhsKyXBiwRoFW9u1): ")
        use_external = True
        user_id = external_id
    else:
        participant_id = input("Enter new participant ID (e.g., 49999): ")
        external_id = f"test_user_{int(time.time())}"
        PARTICIPANT_MAPPING[participant_id] = external_id
        EXTERNAL_ID_TO_PARTICIPANT[external_id] = participant_id
        user_id = participant_id
        use_external = False
        print(f"Created mapping: Participant ID {participant_id} → External ID {external_id}")
    
    # Enrollment steps
    steps = [
        ("start", "Starting enrollment"),
        ("1-9", "Sending cigarette usage"),
        ("Yes, let us do it!", "Confirming readiness"),
        ("10:00", "Setting contact time")
    ]
    
    # Ask for wait time between steps
    wait_time = int(input("Enter seconds to wait between steps (recommended 60-120): ") or "60")
    
    # Send each step
    success_count = 0
    for command, description in steps:
        print(f"\n--- {description} ---")
        if send_message_to_server(user_id, command, use_external_id=use_external):
            success_count += 1
            
            # Check Firebase after each step
            if external_id:
                time.sleep(5)  # Brief pause before checking
                check_firebase_messages(external_id, limit=3)
        
        if wait_time > 0 and steps.index((command, description)) < len(steps) - 1:
            print(f"Waiting {wait_time} seconds before next step...")
            time.sleep(wait_time)
    
    print(f"\nEnrollment sequence completed. {success_count} of {len(steps)} messages sent successfully.")
    
    # Final Firebase check
    if external_id:
        print("\nFinal Firebase message check:")
        check_firebase_messages(external_id)

def main():
    """Main function with focused menu."""
    print("\n===== DASH MESSAGING TEST TOOL =====")
    
    while True:
        print("\nOptions:")
        print("1. Send message & check Firebase")
        print("2. Send complete enrollment sequence")
        print("3. Check Firebase messages for user")
        print("4. List all user ID mappings")
        print("5. Exit")
        
        choice = input("\nEnter your choice (1-5): ")
        
        if choice == "1":
            send_message_with_firebase_check()
        elif choice == "2":
            send_enrollment_sequence()
        elif choice == "3":
            external_id = input("Enter external ID to check: ")
            check_firebase_messages(external_id)
        elif choice == "4":
            print("\n=== USER ID MAPPINGS ===")
            print("Participant ID → External ID (Firebase user ID)")
            for participant_id, external_id in PARTICIPANT_MAPPING.items():
                print(f"  {participant_id} → {external_id}")
        elif choice == "5":
            print("Exiting.")
            break
        else:
            print("Invalid choice. Please try again.")

if __name__ == "__main__":
    main()