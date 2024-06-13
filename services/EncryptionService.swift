import Foundation
import CommonCrypto
import CryptoKit

class EncryptionService {
    
    func encrypt(data: Data, key: SymmetricKey) -> Data? {
            do {
                let sealedBox = try AES.GCM.seal(data, using: key)
                return sealedBox.combined
            } catch {
                print("Encryption failed: \(error.localizedDescription)")
                return nil
            }
        }
        
        func decrypt(data: Data, key: SymmetricKey) -> Data? {
            do {
                let sealedBox = try AES.GCM.SealedBox(combined: data)
                let decryptedData = try AES.GCM.open(sealedBox, using: key)
                return decryptedData
            } catch {
                print("Decryption failed: \(error.localizedDescription)")
                return nil
            }
        }

    
    private static func crypt(data: Data, key: Data, operation: Int) throws -> Data {
        var outLength = Int(0)
        var outBytes = [UInt8](repeating: 0, count: data.count + kCCBlockSizeAES128)
        let keyBytes = [UInt8](key)
        let dataBytes = [UInt8](data)
        
        let status = CCCrypt(
            CCOperation(operation),
            CCAlgorithm(kCCAlgorithmAES128),
            CCOptions(kCCOptionPKCS7Padding),
            keyBytes, kCCKeySizeAES128,
            nil,
            dataBytes, data.count,
            &outBytes, outBytes.count,
            &outLength
        )
        
        guard status == kCCSuccess else {
            throw NSError(domain: "EncryptionError", code: Int(status), userInfo: nil)
        }
        
        return Data(bytes: outBytes, count: outLength)
    }
}
