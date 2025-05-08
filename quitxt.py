import requests
import json
import time
import uuid
import re
from datetime import datetime
from bs4 import BeautifulSoup
import urllib.parse

# Server configuration
BASE_URL = "http://localhost:8080"
LOGIN_ENDPOINT = "/login"

# User credentials
USERNAME = "sahak@gmail.com"
PASSWORD = "123"

# FCM Token
FCM_TOKEN = "cg1l-jH9RJyMF8hYMH81mB:APA91bH3UfqFr4-wwm4jbznCFmCZ4FgHy2MaOIeD92gbr_9LTL3Ul8NfQHNy-gGinisGVC1O6j7PitPF1WHFy368w-Qx0JYxChEhM4tr6c7A72ssc16U3wo"

# User ID (normally this would be retrieved after authentication)
USER_ID = "pUuutN05eoVeWhsKyXBiwRoFW9u1"

class QuiTXTClient:
    def __init__(self, base_url, username, password, fcm_token, user_id):
        self.base_url = base_url
        self.username = username
        self.password = password
        self.fcm_token = fcm_token
        self.user_id = user_id
        self.session = requests.Session()
        self.logged_in = False
        self.csrf_token = None
        self.message_endpoint = None
        self.home_page = None
        self.available_pages = []
    
    def login(self):
        """Log in to the server using the provided credentials"""
        try:
            # First, get the login page
            print("Fetching login page...")
            login_page = self.session.get(f"{self.base_url}{LOGIN_ENDPOINT}")
            
            if login_page.status_code != 200:
                print(f"Could not access login page. Status code: {login_page.status_code}")
                return False
            
            # Parse the login page to look for CSRF tokens
            soup = BeautifulSoup(login_page.text, 'html.parser')
            
            # Look for hidden inputs that might contain CSRF tokens
            csrf_inputs = soup.select('input[type="hidden"]')
            form_data = {}
            
            for input_field in csrf_inputs:
                if input_field.get('name'):
                    form_data[input_field['name']] = input_field.get('value', '')
                    print(f"Found form field: {input_field['name']} = {input_field.get('value', '')}")
            
            # Add username and password to form data
            form_data['username'] = self.username
            form_data['password'] = self.password
            
            # Find the login form to determine its action
            login_form = soup.find('form')
            form_action = ''
            if login_form and login_form.get('action'):
                form_action = login_form['action']
                print(f"Form action: {form_action}")
            
            # Determine the login URL
            login_url = f"{self.base_url}{LOGIN_ENDPOINT}"
            if form_action:
                if form_action.startswith('http'):
                    login_url = form_action
                elif form_action.startswith('/'):
                    login_url = f"{self.base_url}{form_action}"
                else:
                    login_url = f"{self.base_url}/{form_action}"
            
            print(f"Submitting login to: {login_url}")
            
            # Submit the login form
            response = self.session.post(
                login_url, 
                data=form_data,
                allow_redirects=True
            )
            
            # Check if login was successful
            if response.status_code == 200:
                # Try to determine if we're logged in by analyzing the response
                if "logout" in response.text.lower() or self.username.lower() in response.text.lower():
                    self.logged_in = True
                    self.home_page = response.url
                    print(f"Successfully logged in! Redirected to: {response.url}")
                    
                    # Analyze the home page to find potential endpoints
                    self.analyze_home_page(response)
                    return True
                else:
                    print("Login might have failed - could not confirm successful login.")
                    return False
            else:
                print(f"Login failed with status code: {response.status_code}")
                print(f"Response: {response.text[:200]}...")
                return False
                
        except Exception as e:
            print(f"Login error: {str(e)}")
            return False
    
    def analyze_home_page(self, response):
        """Analyze the home page to find potential endpoints"""
        try:
            soup = BeautifulSoup(response.text, 'html.parser')
            
            # Find all links on the page
            links = soup.find_all('a')
            
            print("\nDetected pages/endpoints:")
            for link in links:
                href = link.get('href')
                if href and not href.startswith('#') and not href.startswith('javascript:'):
                    # Normalize the URL
                    if href.startswith('http'):
                        url = href
                    elif href.startswith('/'):
                        url = f"{self.base_url}{href}"
                    else:
                        url = f"{self.base_url}/{href}"
                    
                    # Add to available pages
                    if url not in self.available_pages:
                        self.available_pages.append(url)
                        print(f"- {url} (Text: {link.text.strip()})")
            
            # Find all forms on the page
            forms = soup.find_all('form')
            
            print("\nDetected forms:")
            for form in forms:
                action = form.get('action', '')
                method = form.get('method', 'GET').upper()
                
                if action.startswith('http'):
                    form_url = action
                elif action.startswith('/'):
                    form_url = f"{self.base_url}{action}"
                else:
                    form_url = f"{self.base_url}/{action}"
                
                print(f"- Form: {form_url} (Method: {method})")
                
                # If this looks like a message form, set it as our message endpoint
                form_id = form.get('id', '').lower()
                form_class = form.get('class', '')
                if isinstance(form_class, list):
                    form_class = ' '.join(form_class).lower()
                else:
                    form_class = str(form_class).lower()
                
                if ('message' in form_id or 'chat' in form_id or 
                    'message' in form_class or 'chat' in form_class or
                    'message' in action.lower() or 'chat' in action.lower()):
                    print(f"  This appears to be a message form!")
                    self.message_endpoint = form_url
            
            # Look for any input fields or textareas that might be for messaging
            inputs = soup.find_all(['input', 'textarea'])
            
            for input_field in inputs:
                input_id = input_field.get('id', '').lower()
                input_name = input_field.get('name', '').lower()
                input_class = input_field.get('class', '')
                if isinstance(input_class, list):
                    input_class = ' '.join(input_class).lower()
                else:
                    input_class = str(input_class).lower()
                
                if ('message' in input_id or 'chat' in input_id or 
                    'message' in input_name or 'chat' in input_name or
                    'message' in input_class or 'chat' in input_class):
                    print(f"  Found potential message input: {input_id or input_name}")
            
        except Exception as e:
            print(f"Error analyzing home page: {str(e)}")
    
    def explore_site(self):
        """Explore the website to identify potential endpoints"""
        if not self.logged_in:
            if not self.login():
                return
        
        # At this point we should have a list of available pages
        print("\nExploring available pages to find messaging functionality...")
        
        for page_url in self.available_pages[:]:  # Copy the list to avoid modification during iteration
            try:
                print(f"\nExploring: {page_url}")
                response = self.session.get(page_url)
                
                if response.status_code == 200:
                    # Parse the page
                    soup = BeautifulSoup(response.text, 'html.parser')
                    
                    # Find forms that might be related to messaging
                    forms = soup.find_all('form')
                    
                    for form in forms:
                        action = form.get('action', '')
                        method = form.get('method', 'GET').upper()
                        form_id = form.get('id', '').lower()
                        
                        if 'message' in form_id or 'chat' in form_id:
                            print(f"Found potential message form: {action} (Method: {method})")
                            
                            # Check for message input fields
                            inputs = form.find_all(['input', 'textarea'])
                            for input_field in inputs:
                                input_type = input_field.get('type', '')
                                input_name = input_field.get('name', '')
                                if input_type == 'text' or not input_type:
                                    print(f"  Message input field: {input_name}")
                    
                    # Find links to other pages we haven't discovered yet
                    links = soup.find_all('a')
                    for link in links:
                        href = link.get('href')
                        if href and not href.startswith('#') and not href.startswith('javascript:'):
                            # Normalize the URL
                            if href.startswith('http'):
                                url = href
                            elif href.startswith('/'):
                                url = f"{self.base_url}{href}"
                            else:
                                url = f"{self.base_url}/{href}"
                            
                            # Add to available pages if not already there
                            if url not in self.available_pages:
                                self.available_pages.append(url)
                                print(f"Discovered new page: {url}")
                
                else:
                    print(f"Could not access page. Status code: {response.status_code}")
            
            except Exception as e:
                print(f"Error exploring page {page_url}: {str(e)}")
    
    def check_api_endpoints(self):
        """Try common API endpoint patterns"""
        if not self.logged_in:
            if not self.login():
                return
        
        common_endpoints = [
            "/api/messages",
            "/api/message",
            "/api/chat",
            "/api/scheduler/mobile-app",
            "/scheduler/mobile-app",
            "/mobile-app",
            "/chat/send",
            "/messages/send",
            "/send-message"
        ]
        
        print("\nChecking common API endpoints...")
        
        for endpoint in common_endpoints:
            full_url = f"{self.base_url}{endpoint}"
            print(f"Trying: {full_url}")
            
            try:
                # Try a GET request first
                response = self.session.get(full_url)
                if response.status_code != 404:
                    print(f"  Found endpoint: {endpoint} (GET Status: {response.status_code})")
                
                # Try a POST request with minimal data
                test_data = {"message": "test"}
                response = self.session.post(full_url, json=test_data)
                if response.status_code != 404:
                    print(f"  Found endpoint: {endpoint} (POST Status: {response.status_code})")
                    print(f"  Response: {response.text[:200]}...")
            
            except Exception as e:
                print(f"  Error checking {endpoint}: {str(e)}")
    
    def send_message(self, message_text, endpoint=None):
        """Attempt to send a message using various methods"""
        if not self.logged_in:
            if not self.login():
                return False
        
        # Use specified endpoint or default
        target_endpoint = endpoint or self.message_endpoint
        
        if not target_endpoint:
            print("No message endpoint found. Please specify an endpoint.")
            return False
        
        message_id = str(uuid.uuid4())
        current_time = int(time.time())
        
        # Try different message formats
        
        # Format 1: JSON with complete structure as per documentation
        json_data = {
            "userId": self.user_id,
            "messageText": message_text,
            "messageTime": current_time,
            "messageId": message_id,
            "eventTypeCode": 1,
            "fcmToken": self.fcm_token
        }
        
        # Format 2: Simple message
        form_data = {
            "message": message_text
        }
        
        # Format 3: Common form field names
        common_form_data = {
            "messageText": message_text,
            "text": message_text,
            "content": message_text,
            "body": message_text
        }
        
        print(f"\nAttempting to send message to: {target_endpoint}")
        
        # Try JSON format first
        try:
            print("Trying JSON format...")
            response = self.session.post(
                target_endpoint,
                json=json_data,
                headers={"Content-Type": "application/json"}
            )
            
            print(f"Status: {response.status_code}")
            print(f"Response: {response.text[:300]}...")
            
            if response.status_code < 400:
                print("Message sent successfully (JSON format)!")
                return True
        except Exception as e:
            print(f"Error sending JSON format: {str(e)}")
        
        # Try simple message format
        try:
            print("\nTrying simple message format...")
            response = self.session.post(
                target_endpoint,
                data=form_data
            )
            
            print(f"Status: {response.status_code}")
            print(f"Response: {response.text[:300]}...")
            
            if response.status_code < 400:
                print("Message sent successfully (simple format)!")
                return True
        except Exception as e:
            print(f"Error sending simple format: {str(e)}")
        
        # Try common form fields
        try:
            print("\nTrying common form fields...")
            response = self.session.post(
                target_endpoint,
                data=common_form_data
            )
            
            print(f"Status: {response.status_code}")
            print(f"Response: {response.text[:300]}...")
            
            if response.status_code < 400:
                print("Message sent successfully (common form fields)!")
                return True
        except Exception as e:
            print(f"Error sending common form fields: {str(e)}")
        
        print("\nAll sending methods failed.")
        return False
    
    def browse_to(self, path):
        """Browse to a specific page on the site"""
        if not self.logged_in:
            if not self.login():
                return
        
        # Normalize the URL
        if path.startswith('http'):
            url = path
        elif path.startswith('/'):
            url = f"{self.base_url}{path}"
        else:
            url = f"{self.base_url}/{path}"
        
        try:
            print(f"Browsing to: {url}")
            response = self.session.get(url)
            
            if response.status_code == 200:
                print("Page accessed successfully!")
                
                # Parse the page
                soup = BeautifulSoup(response.text, 'html.parser')
                
                # Print the title
                title = soup.find('title')
                if title:
                    print(f"Page title: {title.text}")
                
                # Look for potential message forms
                forms = soup.find_all('form')
                if forms:
                    print(f"Found {len(forms)} forms on the page.")
                
                    for i, form in enumerate(forms):
                        action = form.get('action', '')
                        method = form.get('method', 'GET').upper()
                        
                        print(f"\nForm {i+1}:")
                        print(f"  Action: {action}")
                        print(f"  Method: {method}")
                        
                        # Print form fields
                        inputs = form.find_all(['input', 'textarea', 'select'])
                        if inputs:
                            print("  Fields:")
                            for input_field in inputs:
                                field_type = input_field.name
                                field_name = input_field.get('name', '')
                                field_id = input_field.get('id', '')
                                field_type_attr = input_field.get('type', '')
                                
                                print(f"    - {field_type} (name='{field_name}', id='{field_id}', type='{field_type_attr}')")
                else:
                    print("No forms found on the page.")
                
                # Return the page content for further analysis
                return response.text
            else:
                print(f"Failed to access page. Status code: {response.status_code}")
                return None
                
        except Exception as e:
            print(f"Error browsing to {url}: {str(e)}")
            return None

def main():
    client = QuiTXTClient(BASE_URL, USERNAME, PASSWORD, FCM_TOKEN, USER_ID)
    
    print("QuiTXT API Exploration Tool")
    print("This tool will help you discover and interact with the QuiTXT API.")
    
    # Login first
    if not client.login():
        print("Login failed. Exiting.")
        return
    
    # Interactive mode
    print("\nCommands:")
    print("  help - Show this help message")
    print("  explore - Explore the website to find messaging functionality")
    print("  check - Check common API endpoints")
    print("  browse <path> - Browse to a specific page on the site")
    print("  send <endpoint> <message> - Send a message to a specific endpoint")
    print("  exit - Exit the program")
    
    while True:
        command = input("\nEnter command: ")
        
        if command.lower() == 'exit':
            break
        elif command.lower() == 'help':
            print("\nCommands:")
            print("  help - Show this help message")
            print("  explore - Explore the website to find messaging functionality")
            print("  check - Check common API endpoints")
            print("  browse <path> - Browse to a specific page on the site")
            print("  send <endpoint> <message> - Send a message to a specific endpoint")
            print("  exit - Exit the program")
        elif command.lower() == 'explore':
            client.explore_site()
        elif command.lower() == 'check':
            client.check_api_endpoints()
        elif command.lower().startswith('browse '):
            path = command[7:].strip()
            client.browse_to(path)
        elif command.lower().startswith('send '):
            # Parse the send command
            parts = command[5:].strip().split(' ', 1)
            if len(parts) == 2:
                endpoint, message = parts
                client.send_message(message, endpoint)
            else:
                print("Invalid send command. Usage: send <endpoint> <message>")
        else:
            print("Unknown command. Type 'help' for a list of commands.")
    
if __name__ == "__main__":
    main()