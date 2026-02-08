#if os(iOS)
import SwiftUI
import ARKit
import RealityKit

struct ARViewContainer: UIViewRepresentable {
    @ObservedObject var viewModel: ARViewModel

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)

        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]

        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            configuration.sceneReconstruction = .mesh
        }

        arView.session.run(configuration)

        context.coordinator.arView = arView
        arView.session.delegate = context.coordinator

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    class Coordinator: NSObject, ARSessionDelegate {
        var viewModel: ARViewModel
        var arView: ARView?

        private var lastProcessedTime: Date = Date()
        private let processingInterval: TimeInterval = 0.1

        init(viewModel: ARViewModel) {
            self.viewModel = viewModel
        }

        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            let now = Date()
            guard now.timeIntervalSince(lastProcessedTime) >= processingInterval else {
                return
            }
            lastProcessedTime = now

            guard viewModel.isDetecting else { return }

            let pixelBuffer = frame.capturedImage
            viewModel.processFrame(pixelBuffer)
        }
    }
}
#endif
