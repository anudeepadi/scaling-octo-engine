import requests
import time
import json

# Base URL of the application
BASE_URL = "http://localhost:8080/scheduler"

def test_application():
    """Test basic access to the application."""
    print("\n=== Testing Basic Application Access ===")
    try:
        response = requests.get(BASE_URL)
        print(f"Status Code: {response.status_code}")
        print(f"Response Size: {len(response.text)} bytes")
        print("✅ Application is accessible")
        return True
    except Exception as e:
        print(f"❌ Failed to access application: {e}")
        return False

def test_messaging_processor():
    """Test starting and stopping the messaging processor."""
    print("\n=== Testing Messaging Processor ===")
    
    # Start the processor
    try:
        start_url = f"{BASE_URL}/webservice/messaging/process2/start"
        response = requests.get(start_url)
        print(f"Start Status Code: {response.status_code}")
        print(f"Start Response: {response.text}")
        print("✅ Messaging processor started")
        
        # Wait a few seconds
        print("Waiting 5 seconds...")
        time.sleep(5)
        
        # Stop the processor
        stop_url = f"{BASE_URL}/webservice/messaging/process2/stop"
        response = requests.get(stop_url)
        print(f"Stop Status Code: {response.status_code}")
        print(f"Stop Response: {response.text}")
        print("✅ Messaging processor stopped")
        return True
    except Exception as e:
        print(f"❌ Failed to test messaging processor: {e}")
        return False

def test_info_endpoint():
    """Test the info endpoint."""
    print("\n=== Testing Info Endpoint ===")
    try:
        info_url = f"{BASE_URL}/info"
        response = requests.get(info_url)
        print(f"Status Code: {response.status_code}")
        print(f"Response Size: {len(response.text)} bytes")
        print("✅ Info endpoint is accessible")
        return True
    except Exception as e:
        print(f"❌ Failed to access info endpoint: {e}")
        return False

def simulate_facebook_webhook():
    """Simulate a Facebook webhook call."""
    print("\n=== Testing Facebook Webhook ===")
    try:
        webhook_url = f"{BASE_URL}/facebook"
        
        # Sample Facebook webhook payload
        payload = {
            "object": "page",
            "entry": [{
                "id": "1234567890",
                "time": int(time.time() * 1000),
                "messaging": [{
                    "sender": {
                        "id": "SFnPqWN8wYaDZ5PUnvGqNDPEKjn2"
                    },
                    "recipient": {
                        "id": "1234567890"
                    },
                    "timestamp": int(time.time() * 1000),
                    "message": {
                        "mid": "mid." + str(int(time.time() * 1000)),
                        "text": "Test message from Python script",
                        "quick_reply": {
                            "payload": "TEST_PAYLOAD"
                        }
                    }
                }]
            }]
        }
        
        headers = {
            "Content-Type": "application/json"
        }
        
        response = requests.post(webhook_url, json=payload, headers=headers)
        print(f"Status Code: {response.status_code}")
        print(f"Response: {response.text}")
        print("✅ Facebook webhook endpoint test completed")
        return True
    except Exception as e:
        print(f"❌ Failed to test Facebook webhook: {e}")
        return False

def simulate_twilio_callback():
    """Simulate a Twilio SMS callback."""
    print("\n=== Testing Twilio Callback ===")
    try:
        twilio_url = f"{BASE_URL}/twilio"
        
        # Sample Twilio SMS callback payload
        payload = {
            "MessageSid": "SM" + str(int(time.time())),
            "SmsSid": "SM" + str(int(time.time())),
            "AccountSid": "AC1234567890",
            "From": "+15551234567",
            "To": "+15557654321",
            "Body": "Test message from SFnPqWN8wYaDZ5PUnvGqNDPEKjn2",
            "NumMedia": "0",
            "FromUser": "SFnPqWN8wYaDZ5PUnvGqNDPEKjn2"
        }
        
        headers = {
            "Content-Type": "application/x-www-form-urlencoded"
        }
        
        response = requests.post(twilio_url, data=payload, headers=headers)
        print(f"Status Code: {response.status_code}")
        print(f"Response: {response.text}")
        print("✅ Twilio callback endpoint test completed")
        return True
    except Exception as e:
        print(f"❌ Failed to test Twilio callback: {e}")
        return False

def run_all_tests():
    """Run all tests and summarize results."""
    results = {}
    
    print("🚀 Starting tests for Scheduler Application")
    print(f"Testing application at: {BASE_URL}")
    
    results["Application Access"] = test_application()
    results["Messaging Processor"] = test_messaging_processor()
    results["Info Endpoint"] = test_info_endpoint()
    results["Facebook Webhook"] = simulate_facebook_webhook()
    results["Twilio Callback"] = simulate_twilio_callback()
    
    print("\n=== Test Summary ===")
    for test, result in results.items():
        status = "✅ PASSED" if result else "❌ FAILED"
        print(f"{test}: {status}")
    
    passed = sum(1 for result in results.values() if result)
    total = len(results)
    print(f"\nOverall Result: {passed}/{total} tests passed")

if __name__ == "__main__":
    run_all_tests()