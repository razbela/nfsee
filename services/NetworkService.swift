import Foundation

struct PasswordsResponse: Codable {
    let passwords: [PasswordItem]
}

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

            print("Raw data: \(String(data: data, encoding: .utf8) ?? "N/A")")

            do {
                let decoder = JSONDecoder()
                let responseObject = try decoder.decode(PasswordsResponse.self, from: data)
                let passwords = responseObject.passwords
                print("Passwords decoded: \(passwords)")
                completion(passwords, nil)
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
            completion(false, "Failed to encode password")
        }
    }

    func fetchPassword(by id: UUID, completion: @escaping (String?, String?) -> Void) {
        guard let url = URL(string: "\(baseURL)/passwords/\(id.uuidString)") else {
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

            print("Raw data (single password): \(String(data: data, encoding: .utf8) ?? "N/A")")

            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let responseObject = try decoder.decode(PasswordResponse.self, from: data)
                let password = responseObject.password
                print("Single password decoded: \(password)")
                completion(password.password, nil)
            } catch {
                print("Decoding error (single password): \(error)")
                completion(nil, "Failed to decode password")
            }
        }.resume()
    }

    func deletePassword(_ passwordId: String, completion: @escaping (Bool, String?) -> Void) {
        guard let url = URL(string: "\(baseURL)/passwords/\(passwordId)") else {
            completion(false, "Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = UserDefaults.standard.string(forKey: "jwtToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let _ = data, error == nil else {
                print("Network error: \(error?.localizedDescription ?? "Unknown error")")
                completion(false, error?.localizedDescription ?? "Unknown error")
                return
            }
            completion(true, nil)
        }.resume()
    }
}
