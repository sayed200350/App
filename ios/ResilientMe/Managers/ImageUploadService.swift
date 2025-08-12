import Foundation
import SwiftUI

#if canImport(FirebaseStorage)
import FirebaseStorage
#endif

final class ImageUploadService {
    static let shared = ImageUploadService()
    private init() {}

    func uploadImage(_ image: UIImage, path: String) async throws -> String {
        #if canImport(FirebaseStorage)
        guard let data = image.jpegData(compressionQuality: 0.7) else { throw NSError(domain: "img", code: 1) }
        let ref = Storage.storage().reference(withPath: path)
        _ = try await ref.putDataAsync(data, metadata: nil)
        let url = try await ref.downloadURL()
        return url.absoluteString
        #else
        throw NSError(domain: "storage", code: -1)
        #endif
    }
}


