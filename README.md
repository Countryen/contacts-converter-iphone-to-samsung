# Description
Little program to convert (phone) contacts from iPhone to Samsung Galaxy (Android), from SQLite to VCard.
Simple PowerShell script.
Created in my free time for a colleague, who moved from his old iPhone 6s to a new Samsung Galaxy S9+.
Successfully converted 1008 contacts from SQLite to VCards.

Feel free to use - see MIT licence.
Feel free to create an issue if assistance/guidance is needed.

# iPhone Contacts
Extracted database-file from an (unencrypted) itunes-backup.
Path: /Home/Library/AddressBook/AddressBook.sqlitedb
Structure is explained in the script.
Basically, it's 2 tables, one containing the Persons and the other containing every related Person's ContactInformation (web, mail, phone, etc.).

# How to extract contact-data of iPhone/iOS using a Windows-PC - January 2019
- connect your iPhone to the PC (USB)
- use Windows iTunes (Windows Store) to create a local (unencrypted!) backup
- backup will be saved at "%USERPROFILE%/Apple Computer/MobileSync/Backup" (other paths are known, look it up)
- download: https://www.giga.de/downloads/iphone-backup-extractor/ (free version sufficient, 4 "objects" is enough)
- open created backup with the extractor tool
- use "Expert-Mode" to see all files/folders directly
- see also: https://support.apple.com/de-de/HT204215
- search for "Home/Library/AddressBook/AddressBook.sqlitedb". 
- extract and save on PC (contains all the contact information as SQLite)
- see also: https://social.technet.microsoft.com/wiki/contents/articles/30562.powershell-accessing-sqlite-databases.aspx

# Notes
Comments are in German (my native language).
