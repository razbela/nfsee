import Foundation
import CoreNFC

class NFCService: NSObject, NFCTagReaderSessionDelegate {
    
    var session: NFCTagReaderSession?
    var completion: ((Data?) -> Void)?
    
    func readKey(completion: @escaping (Data?) -> Void) {
        self.completion = completion
        session = NFCTagReaderSession(pollingOption: .iso14443, delegate: self)
        session?.alertMessage = "Hold your NFC tag near the iPhone."
        session?.begin()
    }
    
    func writeKey(key: Data, completion: @escaping (Bool) -> Void) {
        // Implement the write logic
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        if let tag = tags.first {
            session.connect(to: tag) { (error: Error?) in
                if let error = error {
                    print("Error connecting to tag: \(error.localizedDescription)")
                    self.session?.invalidate(errorMessage: "Connection failed.")
                    self.completion?(nil)
                    return
                }
                
                // Implement the reading logic
            }
        }
    }
    
    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        // Handle session becoming active
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        // Handle session invalidation
        completion?(nil)
    }
}
