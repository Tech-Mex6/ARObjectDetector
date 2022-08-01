import SwiftUI

public struct ARObjectDetector: View {
    @State private var message: String = ""
    @State private var confidenceLevel: Float = 0.0
    
    public init() {}
    
    private var sliderColor: Color {
        self.confidenceLevel < 50 ? (Color.red.opacity(10 - Double(self.confidenceLevel/100))) : (Color.green.opacity(Double(self.confidenceLevel/100)))
    }
    
    public var body: some View {
        ZStack {
            ARView()
            
            VStack {
                Spacer()
                Text(message.capitalized)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Slider(value: $confidenceLevel, in: 0...100) {
                    Text("Confidence")
                }.tint(sliderColor)
            }.padding(20)
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.AppMessage)) { nObject in
            guard let appMessage = nObject.object as? NotificationMessage else {
                print("Error")
                return
            }
            
            message = appMessage.objectName
            confidenceLevel = appMessage.confidence
        }
    }
}
