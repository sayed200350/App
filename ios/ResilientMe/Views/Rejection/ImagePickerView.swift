import SwiftUI
import PhotosUI

struct ImagePickerView: View {
    @Binding var image: UIImage?
    @State private var item: PhotosPickerItem?

    var body: some View {
        PhotosPicker(selection: $item, matching: .images) {
            ResilientButton(title: image == nil ? "Add Screenshot (Optional)" : "Change Screenshot", style: .secondary) {}
        }
        .onChange(of: item) { _ in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self), let ui = UIImage(data: data) {
                    image = ui
                }
            }
        }
    }
}


