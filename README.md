# Description
Little program to convert (phone) contacts from iPhone to Samsung Galaxy (Android), from SQLite to VCard.
Simple PowerShell script.
Created in my free time for a colleague, who moved from his old iPhone 6s to a new Samsung Galaxy S9+.
I managed to successfully extract the contacts from iPhone, convert them to VCards and import them into Samsung.
Back then 1008 contacts got converted.

Feel free to ask or create an issue if anyone needs to do the same.

# iPhone Contacts
Extracted database-file from an (unencrypted) itunes-backup.
Path: /Home/Library/AddressBook/AddressBook.sqlitedb
Structure is explained in the program.
Basically it's 2 tables, one containing the Persons and the other containing every related Person's contact-information (web, mail, phone, etc.).

# How to extract contact-data of iPhone/iOS using a Windows-PC - January 2019
- connect your iPhone with the PC
- Use Windows iTunes (Windows Store) to create a local (unencrypted!) backup
- Backup will be saved at "%USERPROFILE%/Apple Computer/MobileSync/Backup"
- Download: https://www.giga.de/downloads/iphone-backup-extractor/ (Free Version sufficient, 4 "objects" is enough)
- Open created backup with the extractor tool
- Use "Expert-Mode" to see all files/folders directly
- See also: https://support.apple.com/de-de/HT204215
- Now search for file: "Home/Library/AddressBook/AddressBook.sqlitedb". Extract and save on PC
- This file contains all the contact information in SQLite
- See: https://social.technet.microsoft.com/wiki/contents/articles/30562.powershell-accessing-sqlite-databases.aspx

# Notes
Programmed in English but comments are in German (native language).
