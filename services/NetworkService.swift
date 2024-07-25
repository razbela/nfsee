import Foundation

class NetworkService {
    static let shared = NetworkService()
    private let baseURL = "http://10.100.102.6:4444"

    private init() {}

    func fetchPasswords(completion: @escaping ([PasswordItem]?, String?) -> Void) {
        guard let url = URL(string: "\(baseURL)/passwords") else {
            completion(nil, "Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = UserDefaults.standard.string(forKey: "jwtToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Network error: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil, error?.localizedDescription ?? "Unknown error")
                return
            }

            do {
                let decoder = JSONDecoder()
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let passwordsData = jsonResponse["passwords"] as? [[String: Any]] {
                    let jsonData = try JSONSerialization.data(withJSONObject: passwordsData, options: [])
                    let passwords = try decoder.decode([PasswordItem].self, from: jsonData)
                    completion(passwords, nil)
                } else {
                    completion(nil, "Invalid response format")
                }
            } catch {
                print("Decoding error: \(error)")
                completion(nil, "Failed to decode passwords")
            }
        }.resume()
    }

    func addPassword(_ password: PasswordItem, completion: @escaping (Bool, String?) -> Void) {
        guard let url = URL(string: "\(baseURL)/passwords") else {
            completion(false, "Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = UserDefaults.standard.string(forKey: "jwtToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        do {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(password)

            URLSession.shared.dataTask(with: request) { data, response, error in
                guard let _ = data, error == nil else {
                    print("Network error: \(error?.localizedDescription ?? "Unknown error")")
                    completion(false, error?.localizedDescription ?? "Unknown error")
                    return
                }
                completion(true, nil)
            }.resume()
        } catch {
            print("Encoding error: \(error)")
            completion(false, "Failed to encode password")
        }
    }
}
