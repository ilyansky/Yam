import SwiftUI

struct OpenInfoButton: View {

    let action: () -> Void

    var body: some View {
        RectImageButton(imageName: "info.circle.fill",
                        imageScale: 0.5,
                        background: .thinMaterial) {
            action()
        }
    }


}

#Preview {
    OpenInfoButton(action: {})
}
