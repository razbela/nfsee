import Foundation
import CoreNFC
import CryptoKit

class NFCService: NSObject, NFCTagReaderSessionDelegate {
    var session: NFCTagReaderSession?
    var completion: ((Data?) -> Void)?
    private var completionCalled = false
    private var isWriting = false
    
    func startSession(prompt: Bool, writing: Bool, completion: @escaping (Data?) -> Void) {
        print("Starting NFC session - Writing: \(writing)")
        self.completion = completion
        self.completionCalled = false
        self.isWriting = writing
        
        guard NFCTagReaderSession.readingAvailable else {
            print("NFC reading not available on this device.")
            completion(nil)
            return
        }
        
        self.session = NFCTagReaderSession(pollingOption: .iso14443, delegate: self, queue: nil)
        self.session?.alertMessage = prompt ? (writing ? "Hold your NFC card near the iPhone to write the key." : "Hold your NFC card near the iPhone to read the key.") : ""
        self.session?.begin()
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
        
        session.connect(to: tag) { error in
            if let error = error {
                session.alertMessage = "Connection failed. Please try again."
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    session.invalidate(errorMessage: "Connection failed.")
                    self.callCompletion(with: nil)
                }
                return
            }
            
            switch tag {
            case .miFare(let miFareTag):
                print("MIFARE tag detected")
                self.isWriting ? self.writeToMiFareTag(miFareTag, session: session) : self.readKeyFromMiFareTag(miFareTag, session: session)
            default:
                session.alertMessage = "Unsupported tag type."
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    session.invalidate(errorMessage: "Unsupported tag.")
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
            }
            
            print("Successfully wrote key to tag.")
            session.alertMessage = "Write successful!"
            self.callCompletion(with: keyData)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                session.invalidate()
            }
        }
    }
    
    private func readKeyFromMiFareTag(_ tag: NFCMiFareTag, session: NFCTagReaderSession) {
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
            
            switch status {
            case .notSupported:
                session.alertMessage = "NDEF not supported by this tag."
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    session.invalidate(errorMessage: "NDEF not supported.")
                    self.callCompletion(with: nil)
                }
            case .readOnly, .readWrite:
                tag.readNDEF { message, error in
                    if let error = error {
                        print("Failed to read NDEF message: \(error.localizedDescription)")
                        session.alertMessage = "Read failed. Please try again."
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            session.invalidate(errorMessage: "Read failed.")
                            self.callCompletion(with: nil)
                        }
                        return
                    }
                    
                    guard let message = message, let keyData = message.records.first?.payload else {
                        session.alertMessage = "No key found. Please try again."
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            session.invalidate(errorMessage: "No key found.")
                            self.callCompletion(with: nil)
                        }
                        return
                    }
                    
                    print("Successfully read key from tag: \(keyData.base64EncodedString())")
                    session.alertMessage = "Read successful!"
                    self.callCompletion(with: keyData)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        session.invalidate()
                    }
                }
            @unknown default:
                session.alertMessage = "Unknown NDEF status."
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    session.invalidate(errorMessage: "Unknown NDEF status.")
                    self.callCompletion(with: nil)
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
        DispatchQueue.main.async {
            self.completion?(data)
        }
    }
    
    func stopSession() {
        session?.invalidate()
        session = nil
        print("NFC session stopped")
    }
}
