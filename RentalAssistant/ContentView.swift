import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ARViewModel()
    @State private var showManualSelection = false

    var body: some View {
        ZStack {
            #if os(iOS)
            // AR Camera View
            ARViewContainer(viewModel: viewModel)
                .edgesIgnoringSafeArea(.all)
            #else
            // macOS fallback — no AR, just a gradient background
            LinearGradient(
                colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.all)
            #endif

            // Overlay UI
            VStack {
                // Top bar with status
                HStack {
                    #if os(iOS)
                    // Scanning indicator
                    HStack(spacing: 8) {
                        Circle()
                            .fill(viewModel.isDetecting ? Color.green : Color.gray)
                            .frame(width: 10, height: 10)

                        Text(viewModel.isDetecting ? "Scanning..." : "Paused")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    #else
                    Text("RentalAssistant")
                        .font(.headline)
                    #endif

                    Spacer()

                    // Manual selection button
                    Button(action: {
                        showManualSelection.toggle()
                    }) {
                        Image(systemName: "list.bullet.rectangle")
                            .font(.title3)
                            .padding(10)
                            #if os(iOS)
                            .background(.ultraThinMaterial)
                            #else
                            .background(Color.secondary.opacity(0.2))
                            #endif
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)

                Spacer()

                // Detected object info card
                if let objectInfo = viewModel.detectedObject {
                    InfoCardView(objectInfo: objectInfo)
                        .padding(.horizontal)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                #if os(iOS)
                // Bottom controls — scan button for iOS only
                HStack(spacing: 24) {
                    Button(action: {
                        if viewModel.isDetecting {
                            viewModel.stopDetection()
                        } else {
                            viewModel.startDetection()
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: viewModel.isDetecting ? "stop.fill" : "camera.viewfinder")
                            Text(viewModel.isDetecting ? "Stop" : "Scan")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(viewModel.isDetecting ? Color.red : Color.blue)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 16)
                #endif
            }
        }
        .sheet(isPresented: $showManualSelection) {
            ManualSelectionView(viewModel: viewModel)
        }
    }
}

// MARK: - Manual Selection View
struct ManualSelectionView: View {
    @ObservedObject var viewModel: ARViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                ForEach(DetectedObjectInfo.allCases) { item in
                    Button(action: {
                        viewModel.selectObject(item)
                        dismiss()
                    }) {
                        HStack(spacing: 14) {
                            Image(systemName: item.icon)
                                .font(.title2)
                                .foregroundColor(item.color)
                                .frame(width: 40)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text(item.subtitle)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Property Items")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
