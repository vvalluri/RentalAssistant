import SwiftUI

struct InfoCardView: View {
    let objectInfo: DetectedObjectInfo
    @State private var isExpanded: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: objectInfo.icon)
                    .font(.title2)
                    .foregroundColor(objectInfo.color)
                
                Text(objectInfo.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.spring()) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(objectInfo.color.opacity(0.1))
            
            // Content
            if isExpanded {
                ScrollView {
                    Text(objectInfo.instructions)
                        .font(.body)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .padding()
                }
                .frame(maxHeight: 300)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.95))
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(objectInfo.color.opacity(0.3), lineWidth: 2)
        )
    }
}

struct InfoCardView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Spacer()
            InfoCardView(objectInfo: .doorLock)
                .padding()
            Spacer()
        }
        .background(Color.gray.opacity(0.3))
        
        VStack {
            Spacer()
            InfoCardView(objectInfo: .wifiRouter)
                .padding()
            Spacer()
        }
        .background(Color.gray.opacity(0.3))
    }
}
