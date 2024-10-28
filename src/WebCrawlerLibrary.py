import requests
import urllib3;
import json
import os
from datetime import datetime, timedelta

class WebCrawlerLibrary:
    def __init__(self):
        pass

    def notify_slack(self, message: str, webhook_url: str):
        """
        Sends a message to a Slack channel.
        Args:
        - message: The message to send.
        - webhook_url: The webhook URL of the Slack channel.
        """
        urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
        resp = requests.post(webhook_url, json={"text": message}, allow_redirects=False)
        
        # Check Slack's response to ensure the message was accepted
        if resp.status_code == 200:
            print("Message sent to Slack successfully!")
        else:
            print(f"Failed to send message. Status code: {resp.status_code}, Response: {resp.text}")
            raise Exception(f"Failed to send message. Status code: {resp.status_code}, Response: {resp.text}")

    def get_first_line(self, multi_line_string: str)-> str:
        # Split the string into lines
        lines = multi_line_string.splitlines()
        
        # Return the first line
        if lines:
            return lines[0]
        
        return ""
    
    def get_line_from(self, multi_line_string: str, line_number:int)-> str:
        # Split the string into lines
        lines = multi_line_string.splitlines()
        
        # Return the first line
        if lines:
            return lines[line_number]
        
        return ""

    def form_anchor_element(self, text: str, href: str)-> str:
        """
        Forms an anchor element with the given text and href.
        Args:
        - text: The text of the anchor element.
        - href: The href attribute of the anchor element.
        
        Returns:
        - The anchor element.
        """
        return f'<a href="{href}">{text}</a>'
    
    def form_slack_link(self, text:str, link: str)-> str:
        """
        Converts a link to a Slack-formatted link.
        Args:
        - link: The link to convert.
        - text: The text of the link.
        
        Returns:
        - The Slack-formatted link.
        """
        return f'<{link}|{text}>'
    
    def extract_word_between(self, txt: str, start: str, end: str)-> str:
        """
        Extracts the text between two substrings.
        Args:
        - txt: The text in which to search for the substrings.
        - start: The starting substring.
        - end: The ending substring.
        
        Returns:
        - The text between the two substrings.
        """
        start_index = txt.find(start)
        if start_index == -1:
            return ""
        start_index += len(start)
        end_index = txt.find(end, start_index)
        if end_index == -1:
            return ""
        return txt[start_index:end_index]
    
    def find_words_frequency(self, txt: str, words: list[str])-> int:
        """
        Find the frequency of words in a given text.
        Args:
        - txt: The text in which to search for words.
        - words: A list of words to search for in the text.
        
        Returns:
        - The frequency of the words in the text.
        """
        txt = txt.lower()
        words = [word.lower() for word in words]
        frequency = 0
        for word in words:
            frequency += txt.count(word)
        return frequency
   
        self.add_announcement(announcement, file_path)

    def add_announcements(self, announcements:list[str], json_file:str)-> list[str]:
        # Load existing announcements from JSON file or initialize an empty list
        if os.path.exists(json_file):
            with open(json_file, 'r') as file:
                existing_data = json.load(file)
        else:
            existing_data = []

        # Extract current announcements (to avoid duplicates)
        existing_announcements = {item['announcement'] for item in existing_data}
        
        added_announcements = []

        # Add new announcements if they don't already exist
        for announcement in announcements:
            if announcement not in existing_announcements:
                new_entry = {
                    "announcement": announcement,
                    "date": datetime.now().strftime('%Y-%m-%d')
                }
                # Skip announcements that start with "***" (e.g. section headers)
                if not announcement.startswith("***"):
                    existing_data.append(new_entry)
                added_announcements.append(announcement)

        # Save updated list to JSON file
        with open(json_file, 'w') as file:
            json.dump(existing_data, file, indent=4)

        return added_announcements
    
    def remove_old_announcements(self, file_path: str, cutoff_date: datetime = None):
        # Set the cutoff date to 2 months ago if not provided
        if cutoff_date is None:
            cutoff_date = datetime.now() - timedelta(days=60)

        # Check if the file exists
        if not os.path.exists(file_path):
            print(f"File {file_path} does not exist.")
            return

        # Load announcements from the JSON file
        with open(file_path, 'r') as f:
            data = json.load(f)

        # Filter announcements older than the cutoff date
        updated_data = []
        for entry in data:
            entry_date = datetime.strptime(entry['date'], '%Y-%m-%d')
            if entry_date >= cutoff_date:
                updated_data.append(entry)

        # Save the updated data back to the JSON file
        with open(file_path, 'w') as f:
            json.dump(updated_data, f, indent=4)
        
        print(f"Removed announcements older than {cutoff_date.strftime('%Y-%m-%d')}.")
       
    # def add_announcement(announcement: str, file_path: str):
    #     # Check if the JSON file exists, create an empty one if not
    #     if not os.path.exists(file_path):
    #         with open(file_path, 'w') as f:
    #             json.dump([], f)  # Start with an empty list
        
    #     # Load the existing announcements from the JSON file
    #     with open(file_path, 'r') as f:
    #         data = json.load(f)

    #     # Check if an announcement with the same ID already exists
    #     for entry in data:
    #         if entry['announcement'] == id:
    #             print(f"Announcement {announcement} already exists.")
    #             return

    #     # Add new announcement with current date
    #     new_announcement = {
    #         "announcement": announcement,
    #         "date": datetime.now().strftime('%Y-%m-%d %H:%M:%S')  # Add current date and time
    #     }
    #     data.append(new_announcement)

    #     # Save the updated announcements back to the JSON file
    #     with open(file_path, 'w') as f:
    #         json.dump(data, f, indent=4)
        
    #     print(f"Added new announcement {announcement}.")

    # def check_announcement_exists(id: str, file_path: str) -> bool:
    #     # Check if the JSON file exists
    #     if not os.path.exists(file_path):
    #         print(f"File {file_path} does not exist.")
    #         return False
        
    #     # Load announcements from the JSON file
    #     with open(file_path, 'r') as f:
    #         data = json.load(f)
        
    #     # Check if an announcement with the given id exists
    #     for entry in data:
    #         if entry['id'] == id:
    #             print(f"Announcement with ID {id} already exists.")
    #             return True
        
    #     print(f"No announcement with ID {id} found.")
    #     return False

    
