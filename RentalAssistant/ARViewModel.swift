import SwiftUI
import Vision
import Combine

#if os(iOS)
import ARKit
#endif

class ARViewModel: ObservableObject {
    @Published var detectedObject: DetectedObjectInfo?
    @Published var isDetecting: Bool = false
    @Published var debugLabel: String = ""

    #if os(iOS)
    private var visionRequests = [VNRequest]()
    private let confidenceThreshold: Float = 0.05

    private var detectionDebouncer: AnyCancellable?
    private var lastDetectionTime: Date = Date()
    #endif

    init() {
        #if os(iOS)
        setupVision()
        #endif
    }

    func startDetection() {
        isDetecting = true
    }

    func stopDetection() {
        isDetecting = false
    }

    func selectObject(_ object: DetectedObjectInfo) {
        withAnimation {
            detectedObject = object
        }
    }

    #if os(iOS)
    private func setupVision() {
        let classificationRequest = VNClassifyImageRequest { [weak self] request, error in
            guard let self = self else { return }

            if let error = error {
                print("Vision error: \(error.localizedDescription)")
                return
            }

            guard let observations = request.results as? [VNClassificationObservation] else {
                return
            }

            self.processClassifications(observations)
        }

        visionRequests = [classificationRequest]
    }

    func processFrame(_ pixelBuffer: CVPixelBuffer) {
        let imageRequestHandler = VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer,
            orientation: .right,
            options: [:]
        )

        do {
            try imageRequestHandler.perform(visionRequests)
        } catch {
            print("Failed to perform vision request: \(error)")
        }
    }

    private func processClassifications(_ observations: [VNClassificationObservation]) {
        let topObservations = observations.filter { $0.confidence > confidenceThreshold }

        guard !topObservations.isEmpty else {
            DispatchQueue.main.async {
                if Date().timeIntervalSince(self.lastDetectionTime) > 1.5 {
                    withAnimation {
                        self.detectedObject = nil
                    }
                }
            }
            return
        }

        let identifiers = topObservations.map { $0.identifier.lowercased() }
        let objectInfo = identifyObject(labels: identifiers)

        guard let info = objectInfo else { return }

        DispatchQueue.main.async {
            self.lastDetectionTime = Date()

            self.detectionDebouncer?.cancel()
            self.detectionDebouncer = Just(info)
                .delay(for: .milliseconds(300), scheduler: RunLoop.main)
                .sink { [weak self] detected in
                    withAnimation {
                        self?.detectedObject = detected
                    }
                }
        }
    }

    private func identifyObject(labels: [String]) -> DetectedObjectInfo? {
        if labels.contains(where: {
            $0.contains("lock") || $0.contains("combination lock") ||
            $0.contains("padlock") || $0.contains("doorbell")
        }) {
            return .doorLock
        }

        if labels.contains(where: {
            $0.contains("router") || $0.contains("modem") || $0.contains("hub") ||
            $0.contains("power strip") || $0.contains("wireless")
        }) {
            return .wifiRouter
        }

        if labels.contains(where: {
            $0.contains("thermostat") || $0.contains("gauge") ||
            $0.contains("thermometer") || $0.contains("control panel")
        }) {
            return .thermostat
        }

        if labels.contains(where: {
            $0.contains("stove") || $0.contains("oven") || $0.contains("microwave") ||
            $0.contains("toaster") || $0.contains("coffee") || $0.contains("espresso")
        }) {
            return .kitchenAppliances
        }

        if labels.contains(where: {
            $0.contains("television") || $0.contains("monitor") ||
            $0.contains("screen") || $0.contains("remote")
        }) {
            return .tvEntertainment
        }

        if labels.contains(where: {
            $0.contains("washer") || $0.contains("dryer") || $0.contains("washing machine") ||
            $0.contains("laundry")
        }) {
            return .washerDryer
        }

        return nil
    }
    #endif
}

// MARK: - Object Info Models

enum DetectedObjectInfo: String, CaseIterable, Identifiable {
    case doorLock
    case wifiRouter
    case thermostat
    case kitchenAppliances
    case tvEntertainment
    case washerDryer

    var id: String { rawValue }

    var title: String {
        switch self {
        case .doorLock: return "Door Lock"
        case .wifiRouter: return "WiFi Network"
        case .thermostat: return "Thermostat"
        case .kitchenAppliances: return "Kitchen Appliances"
        case .tvEntertainment: return "TV & Entertainment"
        case .washerDryer: return "Washer & Dryer"
        }
    }

    var subtitle: String {
        switch self {
        case .doorLock: return "Access code & lock instructions"
        case .wifiRouter: return "Network name & password"
        case .thermostat: return "Temperature controls & settings"
        case .kitchenAppliances: return "Appliance usage guide"
        case .tvEntertainment: return "Streaming & remote guide"
        case .washerDryer: return "Laundry instructions"
        }
    }

    var instructions: String {
        switch self {
        case .doorLock:
            return """
            Access Code: 1234

            To unlock:
            1. Enter code on keypad
            2. Turn handle clockwise
            3. Push door open

            To lock when leaving:
            \u{2022} Close door firmly
            \u{2022} Press the Schlage button
            \u{2022} Lock will auto-engage
            """

        case .wifiRouter:
            return """
            Network: MyRental_Guest
            Password: WelcomeGuest2024

            If having connection issues:
            1. Forget network and reconnect
            2. Toggle WiFi off/on
            3. Restart your device

            Speed: Up to 500 Mbps
            Guest network is isolated from smart home devices.
            """

        case .thermostat:
            return """
            Nest Thermostat

            Comfort range: 68\u{00B0}F - 76\u{00B0}F
            Please keep within this range.

            To adjust:
            1. Tap the thermostat screen to wake
            2. Rotate the outer ring to change temp
            3. Tap to confirm

            Auto schedule is enabled. It will adjust overnight for energy savings.

            Please do not change to "Away" mode manually.
            """

        case .kitchenAppliances:
            return """
            Oven/Stove (GE):
            \u{2022} Turn knob to desired temp
            \u{2022} Preheat indicator light turns off when ready
            \u{2022} Always turn off after use

            Coffee Maker (Keurig):
            \u{2022} Fill water reservoir on the left
            \u{2022} Insert K-Cup pod, close lid
            \u{2022} Select cup size and press brew

            Microwave:
            \u{2022} Do not use metal containers
            \u{2022} Max time: 10 minutes

            Dishwasher:
            \u{2022} Pods are under the sink
            \u{2022} Run on "Normal" cycle
            """

        case .tvEntertainment:
            return """
            Samsung Smart TV

            Remote:
            \u{2022} Power button at top
            \u{2022} Use center dial to navigate

            Streaming apps available:
            \u{2022} Netflix (logged in)
            \u{2022} Hulu (logged in)
            \u{2022} Disney+ (logged in)

            To switch input:
            1. Press Source on remote
            2. Select HDMI 1 for cable

            Soundbar: Turns on with TV automatically.
            Volume controls on TV remote work for soundbar.
            """

        case .washerDryer:
            return """
            LG Washer & Dryer (stacked)

            Washer (bottom):
            \u{2022} Detergent goes in top-left drawer
            \u{2022} Use "Normal" cycle for most loads
            \u{2022} Cold water recommended
            \u{2022} Max load: 3/4 full

            Dryer (top):
            \u{2022} Clean lint trap before every use
            \u{2022} Use "Medium" heat
            \u{2022} Cycle takes ~45 minutes

            Detergent pods provided under the sink in laundry area.
            Please do not use bleach.
            """
        }
    }

    var icon: String {
        switch self {
        case .doorLock: return "lock.fill"
        case .wifiRouter: return "wifi"
        case .thermostat: return "thermometer.medium"
        case .kitchenAppliances: return "flame.fill"
        case .tvEntertainment: return "tv.fill"
        case .washerDryer: return "drop.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .doorLock: return .blue
        case .wifiRouter: return .green
        case .thermostat: return .orange
        case .kitchenAppliances: return .red
        case .tvEntertainment: return .purple
        case .washerDryer: return .cyan
        }
    }
}
