import Foundation
import CommonCrypto

class EncryptionService {
    
    // Encrypt data using AES
    static func encrypt(data: Data, key: Data) throws -> Data {
        return try crypt(data: data, key: key, operation: kCCEncrypt)
    }
    
    // Decrypt data using AES
    static func decrypt(data: Data, key: Data) throws -> Data {
        return try crypt(data: data, key: key, operation: kCCDecrypt)
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
