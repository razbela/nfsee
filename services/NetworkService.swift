import Foundation

class NetworkService {
    static let shared = NetworkService()
    private let baseURL = "http://10.100.102.16:4444"

    private init() {}

    func fetchPasswords(completion: @escaping ([PasswordItem]?) -> Void) {
        guard let url = URL(string: "\(baseURL)/passwords") else {
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = UserDefaults.standard.string(forKey: "jwtToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }

            do {
                let decoder = JSONDecoder()
                let passwords = try decoder.decode([PasswordItem].self, from: data)
                completion(passwords)
            } catch {
                completion(nil)
            }
        }.resume()
    }

    func addPassword(_ password: PasswordItem, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(baseURL)/passwords") else {
            completion(false)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = UserDefaults.standard.string(forKey: "jwtToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        do {
            var passwordToSend = password
            passwordToSend.isDecrypted = false
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(passwordToSend)

            URLSession.shared.dataTask(with: request) { data, response, error in
                guard let _ = data, error == nil else {
                    completion(false)
                    return
                }
                completion(true)
            }.resume()
        } catch {
            completion(false)
        }
    }
}
