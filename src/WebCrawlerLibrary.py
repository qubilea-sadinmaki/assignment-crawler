import requests
import urllib3;
import json
import os
import re
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

    def add_baseurl_if_relative(self, base_url: str, url: str)-> str:
        """
        Adds the base URL to a relative URL.
        Args:
        - base_url: The base URL.
        - url: The URL to check.
        
        Returns:
        - The URL with the base URL added if it was relative.
        """
        if url.startswith("http"):
            return url
        return base_url + url
    
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
        short_words = [word for word in words if len(word) < 4]
        # Remove the short words from the original list
        words[:] = [word for word in words if len(word) >= 4]
        frequency = 0
        short_word_matches = []

        # We want to find words like AI, QA as whole words and not as part of other words
        for short_word in short_words:
            short_word_matches = self.find_whole_words(txt, [short_word])
            frequency += len(short_word_matches)

        for word in words:
            frequency += txt.count(word)

        # print(f"Short words: {short_words} - {short_word_matches}")
        # print(f"Words: {txt.count(word)} ")
        return frequency

    def has_right_words(self, txt: str, words_to_have: list[str], words_to_not_have: list[str])-> int:
        """
        Checks if a text contains the right words and not the wrong words.
        Args:
        - txt: The text to check.
        - words_to_have: A list of words that must be present in the text.
        - words_to_not_have: A list of words that must not be present in the text.
        
        Returns:
        - True if the text contains the right words and not the wrong words, False otherwise.
        """
        if self.find_words_frequency(txt, words_to_not_have) > 0:
            return 0
        
        return self.find_words_frequency(txt, words_to_have)
    
    def find_whole_words(self, text, words):
        # Create a regular expression pattern for the words
        # \b ensures word boundaries
        pattern = r'\b(' + '|'.join(map(re.escape, words)) + r')\b'
        
        # Use re.findall to find all matching words
        matches = re.findall(pattern, text)
        
        return matches

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
    
    def add_notifications(self, notifications:list[str], json_file:str)-> list[str]:
        # Load existing notifications from JSON file or initialize an empty list
        if os.path.exists(json_file):
            with open(json_file, 'r') as file:
                existing_data = json.load(file)
        else:
            existing_data = []

        # Extract current notifications (to avoid duplicates)
        existing_notifications = {item['notification'] for item in existing_data}
        
        added_notifications = []

        # Add new notifications if they don't already exist
        for notification in notifications:
            if notification not in existing_notifications:
                new_entry = {
                    "notification": notification,
                    "date": datetime.now().strftime('%Y-%m-%d')
                }
                # Skip notifications that start with "***" (e.g. section headers)
                if not notification.startswith("***"):
                    existing_data.append(new_entry)
                added_notifications.append(notification)

        # Save updated list to JSON file
        with open(json_file, 'w') as file:
            json.dump(existing_data, file, indent=4)

        return added_notifications
    

    def remove_old_notifications(self, file_path: str, cutoff_date: datetime = None):
        # Set the cutoff date to 2 months ago if not provided
        if cutoff_date is None:
            cutoff_date = datetime.now() - timedelta(days=60)

        # Check if the file exists
        if not os.path.exists(file_path):
            print(f"File {file_path} does not exist.")
            return

        # Load notifications from the JSON file
        with open(file_path, 'r') as f:
            data = json.load(f)

        # Filter notifications older than the cutoff date
        updated_data = []
        for entry in data:
            entry_date = datetime.strptime(entry['date'], '%Y-%m-%d')
            if entry_date >= cutoff_date:
                updated_data.append(entry)

        # Save the updated data back to the JSON file
        with open(file_path, 'w') as f:
            json.dump(updated_data, f, indent=4)
        
        print(f"Removed elements older than {cutoff_date.strftime('%Y-%m-%d')}.")


    
