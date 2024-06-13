import Foundation
import CoreNFC
import CryptoKit

class NFCService: NSObject, NFCTagReaderSessionDelegate {
    
    var session: NFCTagReaderSession?
    var completion: ((Data?) -> Void)?
    private var completionCalled = false
    
    func startSession(completion: @escaping (Data?) -> Void) {
        DispatchQueue.main.async {
            self.completion = completion
            self.completionCalled = false
            guard NFCTagReaderSession.readingAvailable else {
                print("NFC reading not available on this device.")
                completion(nil)
                return
            }
            
            self.session = NFCTagReaderSession(pollingOption: .iso14443, delegate: self, queue: nil)
            self.session?.alertMessage = "Hold your NFC tag near the iPhone."
            self.session?.begin()
        }
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        guard let tag = tags.first else {
            session.alertMessage = "No tags found. Please try again."
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                session.invalidate(errorMessage: "No tags found.")
                self.callCompletion(with: nil)
            }
            return
        }
        
        print("Tag detected: \(tag)")
        
        session.connect(to: tag) { error in
            if let error = error {
                print("Error connecting to tag: \(error.localizedDescription)")
                session.alertMessage = "Connection failed. Please try again."
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    session.invalidate(errorMessage: "Connection failed.")
                    self.callCompletion(with: nil)
                }
                return
            }
            
            print("Connected to tag: \(tag)")
            
            switch tag {
            case .miFare(let miFareTag):
                print("MIFARE tag detected")
                self.checkTagStatusAndWrite(miFareTag, session: session)
            default:
                session.alertMessage = "Unsupported tag type."
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    session.invalidate(errorMessage: "Unsupported tag.")
                    self.callCompletion(with: nil)
                }
            }
        }
    }
    
    private func checkTagStatusAndWrite(_ tag: NFCMiFareTag, session: NFCTagReaderSession) {
        tag.queryNDEFStatus { status, capacity, error in
            if let error = error {
                print("Failed to query NDEF status: \(error.localizedDescription)")
                session.alertMessage = "Failed to query NDEF status. Please try again."
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    session.invalidate(errorMessage: "Failed to query NDEF status.")
                    self.callCompletion(with: nil)
                }
                return
            }
            
            print("NDEF status queried: \(status), capacity: \(capacity)")
            
            switch status {
            case .notSupported:
                session.alertMessage = "NDEF not supported by this tag."
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    session.invalidate(errorMessage: "NDEF not supported.")
                    self.callCompletion(with: nil)
                }
            case .readOnly:
                session.alertMessage = "Tag is read-only."
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    session.invalidate(errorMessage: "Tag is read-only.")
                    self.callCompletion(with: nil)
                }
            case .readWrite:
                print("Tag is writable")
                self.writeToMiFareTag(tag, session: session)
            @unknown default:
                session.alertMessage = "Unknown NDEF status."
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    session.invalidate(errorMessage: "Unknown NDEF status.")
                    self.callCompletion(with: nil)
                }
            }
        }
    }
    
    private func writeToMiFareTag(_ tag: NFCMiFareTag, session: NFCTagReaderSession) {
        let key = SymmetricKey(size: .bits256)
        let keyData = key.withUnsafeBytes { Data($0) }
        let payload = NFCNDEFPayload(format: .unknown, type: Data(), identifier: Data(), payload: keyData)
        let message = NFCNDEFMessage(records: [payload])
        
        tag.writeNDEF(message) { error in
            if let error = error {
                print("Failed to write key to tag: \(error.localizedDescription)")
                session.alertMessage = "Write failed. Please try again."
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    session.invalidate(errorMessage: "Write failed.")
                    self.callCompletion(with: nil)
                }
                return
            } else {
                print("Successfully wrote key to tag.")
                session.alertMessage = "Write successful!"
                self.callCompletion(with: keyData)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    session.invalidate()
                }
            }
        }
    }
    
    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        print("NFC Session Did Become Active")
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        print("NFC Session Invalidated: \(error.localizedDescription)")
        self.callCompletion(with: nil)
    }
    
    private func callCompletion(with data: Data?) {
        guard !completionCalled else { return }
        completionCalled = true
        completion?(data)
    }
}
