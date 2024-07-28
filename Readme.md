# NFSee
## Final Project Definition

### By:
- Raz Belahusky
- Tomer Weisengreen
- Gal Adam

### Supervisor:
- Hemi Leibovich

### Git:
(https://github.com/razbela/nfsee.git)

---

## Table of Contents
1. [How to Run](#how-to-run)
2. [Project Description](#project-description)
3. [Architecture](#architecture)
4. [Each Module Description](#each-module-description)
5. [Client Side](#client-side)
6. [Server Side](#server-side)
    - [API](#api)

---

## How to Run

### (Phase_1) Virtual Env
 

cd path/to/your/project/nfsee
python3 -m venv venv
source venv/bin/activate

### (Phase_2) Config

Navigate to the project directory and modify the config :

vim path/to/your/project/nfsee/models/config.json

----vim models/config.json-----

"serverIPAddress": "",
"serverPort": ""

### (Phase_3) Vault Server (Remote vault) *cli_1
Start the Vault server in development mode :

vault server -dev -dev-listen-address="127.0.0.1:8200"

if port is used :
lsof -i :$(port_number)  
kill -9 pid

Copy Unseal Key & Root Token to .env file

### (Phase_4) Backend Server (Local vault) *cli_2

open venv
source venv/bin/activate

Navigate to the project directory and run the backend server :
cd path/to/your/project/nfsee

install requirements and deploy local server

pip install -r requirements.txt
python3 main.py

### Remote Vault Debug *window_1

Navigate to the remote vault, enter token to access & check password store
http://127.0.0.1:8200/ui/vault/auth?redirect_to=%2Fvault%2Fsecrets%2Fsecret%2Fconfiguration&with=token

### Local Vault Debug *window_2

Navigate to the local vault, with database app like DB Browser for SQLite

### ios App *window_3

Open the nfsee project in Xcode.
Select your target device or simulator.
Click on the Run button (or press Cmd + R) to build and run the application.


## Project Description

The project involves the development of an iOS application named NFSee, which is designed to manage and secure passwords using NFC (Near Field Communication) technology. 
The core feature of the application is its ability to encrypt and decrypt passwords stored within the app using a 512 bytes key that is embedded in an NFC card. 
This approach ensures that passwords are not just protected by a master password or Face ID but are secured through physical NFC cards, providing a unique extra layer of security.
NFSee aims to set a new standard in password management and security, combining the convenience of digital tools with the robust security of physical authentication methods.

## Architecture

Overall System:
The architecture of the NFSee application is structured to ensure a clear separation of concerns and maintainability. It comprises the following components:
Client-Side (iOS App): Includes the user interface (UI), view models, services for data management and network communication, and models for data representation. The iOS app interacts with the backend server to fetch, store, and manage sensitive information securely.
Backend Server: Handles business logic, authentication, and secure data storage. It interfaces with HashiCorp Vault to manage secrets and sensitive information securely. The server exposes API endpoints for the iOS app to interact with.
Vault (Secret Management): Used to securely store and manage secrets such as passwords, API keys, and other sensitive data. It ensures that sensitive information is encrypted and only accessible by authorized components of the system.

## Each Module Description

### Models:
PasswordItem.swift: Represents the data structure for securely storing password information.
APIResponse.swift: Represents the structure of API responses from the backend server.
### Services:
Persistence.swift: Manages data storage and retrieval.
nfseeApp.swift: Core application logic and initialization.
NFCServices.swift: Interfaces with NFC hardware to read/write NFC tags.
EncryptionService.swift: Provides data encryption and decryption services.
CoreDataService.swift: Manages interactions with CoreData for local database operations.
NetworkService.swift: Manages network requests and handles communication with the backend server.
### View_Models:
PasswordListViewModel.swift: Manages and provides the UI logic for listing passwords.
AddPasswordViewModel.swift: Handles the logic for adding new passwords to the storage.
### Views:
ContentView.swift: The primary view of the app.
AddPasswordView.swift: A view to input new passwords.
### Root Folder (nfsee):
Assets: Contains images and other assets used by the app.
nfsee: Main entry point of the app and contains app-specific configuration and resources.
Preview Content: Includes placeholder and preview UI components.
### nfseeTests: Contains unit tests for backend logic, ensuring the correct functionality of the core services and models.
### nfseeUITests: Contains UI tests to ensure the frontend integrates seamlessly with the backend, providing end-to-end testing of user interactions and UI elements.

### Backend:
Server: The Core Server application, which initializes the server and sets up routing.
###Routes: Define the URL paths and HTTP methods for interacting with the server. Routes are mapped to controller methods.
###Controllers: Contain the business logic for handling requests. Controllers process input, interact with models, and return responses.
###Models: Define the data structures and methods for interacting with the database.
###Config: Configuration files for setting up and managing external services like Vault.

##Client Side

###Initializing the NFC Card with a Key:
User launches the NFSee app and selects the option to initialize a new NFC card.
The app prompts the user to place their NFC card near the device.
The app generates a secure encryption key and writes it to the NFC card using encrypted transmission.
A confirmation message is displayed to the user indicating successful initialization.
###Adding and Encrypting Passwords:
User selects the option to add a new password.
User enters the password along with associated details (e.g., website, account name).
User is prompted to place the initialized NFC card near the device to encrypt the password.
The app reads the encryption key from the NFC card and uses it to encrypt the password.
The encrypted password is then saved in the app's secure storage.
A confirmation message is displayed to the user indicating the password has been securely saved.
###Decrypting and Accessing Passwords:
User navigates to the stored passwords list within the app.
User selects the password they wish to access.
The app prompts the user to place their NFC card near the device to decrypt the password.
The app reads the encryption key from the NFC card and uses it to decrypt the selected password.
The decrypted password is then displayed on the device for a limited time, or until the user closes the view.

##Server Side

###Functionality and Structure:
User Management: Handles user accounts, authentication, and access controls.
###Processes:
Registration: Users can create accounts with email verification.
Login: Authentication is managed through secure password mechanisms and can include two-factor authentication (2FA) for additional security.
Profile Management: Users can update their profile information and manage their security settings.
###Security Protocols:
AES Encryption: The server uses Advanced Encryption Standard (AES) for encrypting and decrypting stored passwords. AES is chosen for its reliability and security.
Symmetric Key Algorithm: AES uses the same key for both encryption and decryption, enhancing efficiency in environments where secure key distribution is managed.
###Implementation:
The encryption key is securely generated and managed by Vault and never exposed to the server directly, minimizing risk.
Passwords are encrypted on the client side before being sent to the server for storage, ensuring that sensitive data is always encrypted in transit and at rest.
Vault is used to securely store and manage the encryption keys, leveraging its robust secret management capabilities.
Data Processing: Manages data storage, retrieval, and integrity.
###Processes:
Data Storage: Encrypted passwords and user data are stored in a secure, scalable database.
Data Retrieval: Requests for data are handled efficiently, ensuring that responses are quick and that data integrity is maintained.
Backup and Recovery: Regular backups are conducted to prevent data loss, with robust recovery procedures in place.
Communications with the Client Application: Ensures secure and efficient communication between the client app and the server.
HTTPS: All communications are secured using HTTPS, which encrypts the data transmitted between the client and the server.
API Security: APIs are secured with authentication tokens to ensure that only authorized requests are processed.
###Implementation:
The server exposes RESTful APIs for the app to interact with for operations like adding, retrieving, and deleting passwords.
These APIs are designed to handle high-load scenarios, ensuring that the app remains responsive even under heavy user traffic.
Vault API is integrated for secure management of secrets and keys used in the encryption processes.



