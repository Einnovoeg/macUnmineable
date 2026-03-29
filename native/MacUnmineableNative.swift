import AppKit
import Foundation
import Network
import SwiftUI

// This file contains the entire native macOS app. The project intentionally
// stays dependency-light, so the model, theme system, runtime management, and
// SwiftUI views all live in one file and are separated with MARK sections.

// MARK: - Domain Models

struct CoinOption: Identifiable, Hashable {
    let symbol: String
    let name: String

    var id: String { symbol }
}

// Each algorithm describes the unMineable pool endpoint plus the backend-
// specific algorithm identifiers needed to launch the underlying miner.
struct AlgorithmConfig: Identifiable, Hashable {
    let id: String
    let label: String
    let host: String
    let ports: [Int]
    let xmrigAlgo: String?
    let cpuminerAlgo: String?
    let uselethSupported: Bool
    let srbCpuAlgo: String?
    let srbGpuAlgo: String?
}

enum HardwareChoice: String, CaseIterable, Identifiable {
    case auto
    case cpu
    case gpu

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .auto: return "Auto"
        case .cpu: return "CPU"
        case .gpu: return "GPU"
        }
    }
}

enum BackendChoice: String, CaseIterable, Identifiable {
    case auto
    case xmrig
    case cpuminerScash
    case uselethminer
    case srbminer

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .auto: return "Auto"
        case .xmrig: return "XMRig"
        case .cpuminerScash: return "cpuminer-scash"
        case .uselethminer: return "UselethMiner"
        case .srbminer: return "SRBMiner"
        }
    }
}

enum InstallTarget: String, CaseIterable {
    case xmrig
    case cpuminerScash = "cpuminer_scash"
    case uselethminer
    case srbminer

    var displayName: String {
        switch self {
        case .xmrig: return "XMRig"
        case .cpuminerScash: return "cpuminer-scash"
        case .uselethminer: return "UselethMiner"
        case .srbminer: return "SRBMiner"
        }
    }
}

// MARK: - Appearance

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var preferredColorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

enum AccentPalette: String, CaseIterable, Identifiable {
    case mint
    case ocean
    case ember
    case citrus

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .mint: return "Mint"
        case .ocean: return "Ocean"
        case .ember: return "Ember"
        case .citrus: return "Citrus"
        }
    }

    var colors: (start: Color, end: Color) {
        switch self {
        case .mint:
            return (
                Color(red: 0.17, green: 0.72, blue: 0.60),
                Color(red: 0.13, green: 0.58, blue: 0.51)
            )
        case .ocean:
            return (
                Color(red: 0.15, green: 0.52, blue: 0.95),
                Color(red: 0.08, green: 0.34, blue: 0.78)
            )
        case .ember:
            return (
                Color(red: 0.93, green: 0.46, blue: 0.29),
                Color(red: 0.79, green: 0.26, blue: 0.23)
            )
        case .citrus:
            return (
                Color(red: 0.82, green: 0.76, blue: 0.22),
                Color(red: 0.59, green: 0.64, blue: 0.16)
            )
        }
    }
}

// DashboardTheme keeps all palette-dependent colors in one place so light/dark
// mode and alternate accent palettes stay visually coherent across the app.
struct DashboardTheme {
    let backgroundTop: Color
    let backgroundBottom: Color
    let cardFill: Color
    let cardStroke: Color
    let fieldFill: Color
    let fieldStroke: Color
    let chromeFill: Color
    let chromeStroke: Color
    let primaryText: Color
    let secondaryText: Color
    let tertiaryText: Color
    let accentStart: Color
    let accentEnd: Color
    let accentSoft: Color
    let accentLine: Color
    let segmentFill: Color
    let idleButtonFill: Color
    let stopButtonFill: Color
    let orbFill: Color
    let ghostOrbFill: Color
    let shadow: Color

    static func make(colorScheme: ColorScheme, palette: AccentPalette) -> DashboardTheme {
        let accent = palette.colors
        if colorScheme == .dark {
            return DashboardTheme(
                backgroundTop: Color(red: 0.10, green: 0.11, blue: 0.13),
                backgroundBottom: Color(red: 0.06, green: 0.07, blue: 0.09),
                cardFill: Color.white.opacity(0.08),
                cardStroke: Color.white.opacity(0.09),
                fieldFill: Color.white.opacity(0.06),
                fieldStroke: Color.white.opacity(0.08),
                chromeFill: Color.white.opacity(0.08),
                chromeStroke: Color.white.opacity(0.10),
                primaryText: Color.white.opacity(0.92),
                secondaryText: Color.white.opacity(0.74),
                tertiaryText: Color.white.opacity(0.46),
                accentStart: accent.start,
                accentEnd: accent.end,
                accentSoft: accent.start.opacity(0.20),
                accentLine: accent.start,
                segmentFill: accent.start,
                idleButtonFill: accent.start,
                stopButtonFill: Color(red: 0.90, green: 0.29, blue: 0.43),
                orbFill: accent.start.opacity(0.13),
                ghostOrbFill: Color.white.opacity(0.04),
                shadow: Color.black.opacity(0.34)
            )
        }

        return DashboardTheme(
            backgroundTop: Color(red: 0.95, green: 0.95, blue: 0.94),
            backgroundBottom: Color(red: 0.91, green: 0.91, blue: 0.90),
            cardFill: Color.white.opacity(0.72),
            cardStroke: Color.white.opacity(0.90),
            fieldFill: Color.white.opacity(0.76),
            fieldStroke: Color.white.opacity(0.90),
            chromeFill: Color.white.opacity(0.70),
            chromeStroke: Color.white.opacity(0.92),
            primaryText: Color.black.opacity(0.82),
            secondaryText: Color.black.opacity(0.62),
            tertiaryText: Color.black.opacity(0.42),
            accentStart: accent.start,
            accentEnd: accent.end,
            accentSoft: accent.start.opacity(0.15),
            accentLine: accent.start,
            segmentFill: accent.start,
            idleButtonFill: Color(red: 0.14, green: 0.18, blue: 0.21),
            stopButtonFill: Color(red: 0.94, green: 0.31, blue: 0.48),
            orbFill: accent.start.opacity(0.10),
            ghostOrbFill: Color.white.opacity(0.46),
            shadow: Color.black.opacity(0.07)
        )
    }
}

// MARK: - Static Configuration

private let fallbackCoins: [CoinOption] = [
    .init(symbol: "BTC", name: "Bitcoin"),
    .init(symbol: "ETH", name: "Ethereum"),
    .init(symbol: "SOL", name: "Solana"),
    .init(symbol: "DOGE", name: "Dogecoin"),
    .init(symbol: "USDT", name: "Tether"),
    .init(symbol: "XRP", name: "XRP"),
    .init(symbol: "LTC", name: "Litecoin"),
    .init(symbol: "TRX", name: "Tron"),
]

private let algorithms: [AlgorithmConfig] = [
    .init(id: "rx", label: "RandomX", host: "rx.unmineable.com", ports: [3333, 13333, 4445], xmrigAlgo: "rx", cpuminerAlgo: "randomx", uselethSupported: false, srbCpuAlgo: "randomx", srbGpuAlgo: nil),
    .init(id: "ghostrider", label: "GhostRider", host: "ghostrider.unmineable.com", ports: [3333, 13333], xmrigAlgo: "gr", cpuminerAlgo: nil, uselethSupported: false, srbCpuAlgo: "ghostrider", srbGpuAlgo: nil),
    .init(id: "etchash", label: "Etchash", host: "etchash.unmineable.com", ports: [3333, 13333], xmrigAlgo: nil, cpuminerAlgo: nil, uselethSupported: false, srbCpuAlgo: nil, srbGpuAlgo: "etchash"),
    .init(id: "ethash", label: "Ethash", host: "ethash.unmineable.com", ports: [3333, 13333], xmrigAlgo: nil, cpuminerAlgo: nil, uselethSupported: true, srbCpuAlgo: nil, srbGpuAlgo: "ethash"),
    .init(id: "kp", label: "KawPow", host: "kp.unmineable.com", ports: [3333, 13333], xmrigAlgo: "kawpow", cpuminerAlgo: nil, uselethSupported: false, srbCpuAlgo: nil, srbGpuAlgo: "kawpow"),
    .init(id: "autolykos", label: "Autolykos", host: "autolykos.unmineable.com", ports: [3333, 13333], xmrigAlgo: nil, cpuminerAlgo: nil, uselethSupported: false, srbCpuAlgo: nil, srbGpuAlgo: "autolykos2"),
]

private let prefAutoInstallXMRigKey = "macunmineable.pref.autoInstallXmrig"
private let prefAutoValidateOnLaunchKey = "macunmineable.pref.autoValidateOnLaunch"
private let prefAppearanceModeKey = "macunmineable.pref.appearanceMode"
private let prefPaletteKey = "macunmineable.pref.palette"
private let supportURLString = "https://buymeacoffee.com/einnovoeg"

private enum AppReleaseInfo {
    static let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev"
    static let buildVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "dev"

    static var displayString: String {
        if shortVersion == buildVersion {
            return shortVersion
        }
        return "\(shortVersion) (\(buildVersion))"
    }
}

private func openExternalURL(_ rawValue: String) {
    // External links are restricted to HTTPS destinations so settings/support
    // buttons cannot be repointed to arbitrary local files or custom schemes.
    guard let components = URLComponents(string: rawValue),
          components.scheme?.lowercased() == "https",
          let host = components.host,
          !host.isEmpty,
          let url = components.url
    else {
        return
    }
    NSWorkspace.shared.open(url)
}

// MARK: - Runtime Model

@MainActor
final class NativeAppModel: ObservableObject {
    @Published var coins: [CoinOption] = fallbackCoins
    @Published var coinSymbol: String = "BTC"
    @Published var walletAddress: String = ""
    @Published var selectedAlgorithmID: String = "rx"
    @Published var hardware: HardwareChoice = .auto
    @Published var backend: BackendChoice = .auto
    @Published var selectedPort: Int = 3333
    @Published var workerName: String = "macunmineable"
    @Published var referralCode: String = ""
    @Published var threadsPercent: Double = 80

    @Published var statusPill: String = "Idle"
    @Published var statusText: String = "Waiting to start."
    @Published var warningText: String = ""
    @Published var systemText: String = ""
    @Published var minerText: String = ""
    @Published var minerLogs: String = ""
    @Published var localHashrateText: String = "--"
    @Published var effectiveHashrateText: String = "--"
    @Published var hashrateSamples: [Double] = []
    @Published var isOnline: Bool = true
    @Published var installLogs: String = ""
    @Published var installStatusText: String = "No install task running."
    @Published var validationStatusText: String = "No validation run yet."
    @Published var validationLogs: String = ""
    @Published var poolConnectionText: String = "Not tested."
    @Published var xmrigPathOverride: String = ""
    @Published var srbminerPathOverride: String = ""
    @Published var isMining: Bool = false
    @Published var isInstalling: Bool = false
    @Published var isTestingConnection: Bool = false

    private var minerProcess: Process?
    private var installProcess: Process?
    private var minerBackend: BackendChoice = .auto
    private var configMinerPaths: [String: String] = [:]

    private let fileManager = FileManager.default
    private let appSupportURL: URL
    private let runtimeURL: URL
    private let configURL: URL
    private let defaults = UserDefaults.standard
    private var networkMonitor: NWPathMonitor?
    private let networkMonitorQueue = DispatchQueue(label: "macunmineable.network-monitor")

    private let formDefaultsKey = "macunmineable.native.form.v1"

    // App startup restores persisted state, stages the runtime payload under
    // Application Support, refreshes the live availability text, and then
    // optionally installs/validates the managed miner set depending on user
    // preferences.
    init() {
        defaults.register(defaults: [
            prefAutoInstallXMRigKey: true,
            prefAutoValidateOnLaunchKey: true,
        ])
        let supportRoot = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        appSupportURL = supportRoot.appendingPathComponent("macUnmineable", isDirectory: true)
        runtimeURL = appSupportURL.appendingPathComponent("runtime", isDirectory: true)
        configURL = appSupportURL.appendingPathComponent("local_config.json", isDirectory: false)
        systemText = "\(ProcessInfo.processInfo.operatingSystemVersionString) | \(isAppleSilicon() ? "Apple Silicon" : "Intel")"

        bootstrapRuntime()
        loadConfig()
        loadFormState()
        normalizeSelections(showWarning: false)
        refreshSelection()
        refreshMinerAvailabilityText()
        fetchCoins()
        startNetworkMonitor()
        if defaults.bool(forKey: prefAutoInstallXMRigKey) {
            ensureManagedMinersInstalledIfNeeded()
        } else if defaults.bool(forKey: prefAutoValidateOnLaunchKey) {
            validateMiners()
        }
    }

    deinit {
        networkMonitor?.cancel()
    }

    // The visible algorithm list is intentionally constrained by the current
    // backend/hardware selection so the UI never offers combinations that the
    // runtime cannot actually execute on this Mac.
    var filteredAlgorithms: [AlgorithmConfig] {
        let xmrigReady = hasUsableXMRigBinary
        let cpuminerReady = hasUsableCPUMinerScashBinary
        let uselethReady = hasUsableUselethMinerBinary
        let srbminerReady = hasUsableSRBMinerBinary
        switch backend {
        case .xmrig:
            if hardware == .gpu {
                return []
            }
            return xmrigReady ? algorithms.filter { $0.xmrigAlgo != nil } : []
        case .cpuminerScash:
            if hardware == .gpu {
                return []
            }
            return cpuminerReady ? algorithms.filter { $0.cpuminerAlgo != nil } : []
        case .uselethminer:
            return uselethReady ? algorithms.filter { $0.uselethSupported } : []
        case .srbminer:
            guard srbminerReady else { return [] }
            switch hardware {
            case .gpu:
                return algorithms.filter { $0.srbGpuAlgo != nil }
            case .cpu:
                return algorithms.filter { $0.srbCpuAlgo != nil }
            case .auto:
                return algorithms.filter { $0.srbGpuAlgo != nil || $0.srbCpuAlgo != nil }
            }
        case .auto:
            switch hardware {
            case .gpu:
                return algorithms.filter { (uselethReady && $0.uselethSupported) || (srbminerReady && $0.srbGpuAlgo != nil) }
            case .cpu:
                return algorithms.filter {
                    (xmrigReady && $0.xmrigAlgo != nil)
                        || (cpuminerReady && $0.cpuminerAlgo != nil)
                        || (uselethReady && $0.uselethSupported)
                        || (srbminerReady && $0.srbCpuAlgo != nil)
                }
            case .auto:
                return algorithms.filter {
                    (xmrigReady && $0.xmrigAlgo != nil)
                        || (cpuminerReady && $0.cpuminerAlgo != nil)
                        || (uselethReady && $0.uselethSupported)
                        || (srbminerReady && ($0.srbCpuAlgo != nil || $0.srbGpuAlgo != nil))
                }
            }
        }
    }

    var hasUsableXMRigBinary: Bool {
        hasUsableBinary(target: .xmrig)
    }

    var hasUsableCPUMinerScashBinary: Bool {
        hasUsableBinary(target: .cpuminerScash)
    }

    var hasUsableUselethMinerBinary: Bool {
        hasUsableBinary(target: .uselethminer)
    }

    var hasUsableSRBMinerBinary: Bool {
        hasUsableBinary(target: .srbminer)
    }

    var availableBackends: [BackendChoice] {
        let ready: [BackendChoice] = [
            hasUsableXMRigBinary ? .xmrig : nil,
            hasUsableCPUMinerScashBinary ? .cpuminerScash : nil,
            hasUsableUselethMinerBinary ? .uselethminer : nil,
            hasUsableSRBMinerBinary ? .srbminer : nil,
        ].compactMap { $0 }

        if ready.count > 1 {
            return [.auto] + ready
        }
        if let only = ready.first {
            return [only]
        }
        return isAppleSilicon() ? [.xmrig] : [.auto, .xmrig]
    }

    var availableHardwareChoices: [HardwareChoice] {
        let gpuAvailable = hasUsableUselethMinerBinary || hasUsableSRBMinerBinary
        let cpuAvailable = hasUsableXMRigBinary || hasUsableCPUMinerScashBinary || hasUsableUselethMinerBinary || hasUsableSRBMinerBinary

        if gpuAvailable && cpuAvailable {
            return [.auto, .cpu, .gpu]
        }
        if gpuAvailable {
            return [.gpu]
        }
        if cpuAvailable {
            return isAppleSilicon() ? [.cpu] : [.auto, .cpu]
        }
        return isAppleSilicon() ? [.cpu] : [.auto, .cpu]
    }

    var appleSiliconMiningSummary: String {
        var backends: [String] = []
        if hasUsableXMRigBinary {
            backends.append("XMRig for RandomX, GhostRider, and KawPow on CPU")
        }
        if hasUsableCPUMinerScashBinary {
            backends.append("cpuminer-scash for RandomX on CPU")
        }
        if hasUsableUselethMinerBinary {
            backends.append("UselethMiner for Ethash on CPU or Metal GPU when the official /usr/local installation is present")
        }
        if hasUsableSRBMinerBinary {
            backends.append("custom SRBMiner build for any manually supplied modes")
        }
        if backends.isEmpty {
            return "Apple Silicon mode: install the managed backends from Setup to enable XMRig and cpuminer-scash. UselethMiner only becomes available after its official macOS package is installed to /usr/local/uselethminer. Your payout coin, algorithm, hardware, and backend remain separate settings."
        }
        return "Apple Silicon supported backends: \(backends.joined(separator: " | "))."
    }

    var portOptions: [Int] {
        selectedAlgorithm?.ports ?? [3333]
    }

    var selectedAlgorithm: AlgorithmConfig? {
        filteredAlgorithms.first(where: { $0.id == selectedAlgorithmID })
            ?? algorithms.first(where: { $0.id == selectedAlgorithmID })
    }

    var displayedBackendName: String {
        if isMining, minerBackend != .auto {
            return minerBackend.displayName
        }
        return backend.displayName
    }

    var selectedPoolHost: String {
        selectedAlgorithm?.host ?? "-"
    }

    func handleAlgorithmOrPortChange() {
        refreshSelection()
        poolConnectionText = "Not tested."
        saveFormState()
    }

    func handleHardwareChange() {
        normalizeSelections(showWarning: false)
        refreshSelection()
        poolConnectionText = "Not tested."
        saveFormState()
    }

    func handleBackendChange() {
        normalizeSelections(showWarning: true)
        refreshSelection()
        poolConnectionText = "Not tested."
        saveFormState()
    }

    func handleSimpleFormChange() {
        saveFormState()
    }

    func displayWallet() -> String {
        let wallet = walletAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        if wallet.count <= 24 {
            return wallet.isEmpty ? "-" : wallet
        }
        let prefix = wallet.prefix(12)
        let suffix = wallet.suffix(10)
        return "\(prefix)...\(suffix)"
    }

    func displayWorker() -> String {
        let worker = sanitizeWorker(workerName)
        return worker
    }

    func clearMinerLogs() {
        minerLogs = ""
    }

    func testUnmineableConnection() {
        warningText = ""
        guard let cfg = selectedAlgorithm else {
            poolConnectionText = "No algorithm selected."
            return
        }
        guard let port = NWEndpoint.Port(rawValue: UInt16(selectedPort)) else {
            poolConnectionText = "Invalid port: \(selectedPort)"
            return
        }
        if isTestingConnection {
            return
        }

        isTestingConnection = true
        poolConnectionText = "Testing \(cfg.host):\(selectedPort)..."
        let connection = NWConnection(host: NWEndpoint.Host(cfg.host), port: port, using: .tcp)
        let queue = DispatchQueue(label: "macunmineable.pool-test")

        let timeout = DispatchWorkItem { [weak self] in
            connection.cancel()
            Task { @MainActor in
                guard let self, self.isTestingConnection else { return }
                self.isTestingConnection = false
                self.poolConnectionText = "Connection timed out."
            }
        }

        queue.asyncAfter(deadline: .now() + 5, execute: timeout)

        connection.stateUpdateHandler = { [weak self] state in
            guard let self else { return }
            switch state {
            case .ready:
                timeout.cancel()
                connection.cancel()
                Task { @MainActor in
                    guard self.isTestingConnection else { return }
                    self.isTestingConnection = false
                    self.poolConnectionText = "Connected to \(cfg.host):\(self.selectedPort)"
                }
            case let .failed(error):
                timeout.cancel()
                Task { @MainActor in
                    guard self.isTestingConnection else { return }
                    self.isTestingConnection = false
                    self.poolConnectionText = "Connection failed: \(error.localizedDescription)"
                }
            case .cancelled:
                break
            default:
                break
            }
        }
        connection.start(queue: queue)
    }

    func startMining() {
        warningText = ""
        normalizeSelections(showWarning: true)
        refreshSelection()

        guard !isInstalling else {
            warningText = "Wait for installer to finish."
            return
        }

        guard !isMining else {
            warningText = "Miner is already running."
            return
        }

        let coin = sanitizeCoin(coinSymbol)
        guard !coin.isEmpty else {
            warningText = "Coin symbol is required."
            return
        }

        let wallet = walletAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !wallet.isEmpty else {
            warningText = "Wallet address is required."
            return
        }
        if wallet.contains(where: { $0.isWhitespace }) {
            warningText = "Wallet address must not contain spaces."
            return
        }

        guard let cfg = selectedAlgorithm else {
            warningText = "No compatible algorithm for selected backend/hardware."
            return
        }

        let worker = sanitizeWorker(workerName)
        let referral = sanitizeReferral(referralCode)
        let available = minerAvailable()

        let picked: BackendChoice
        do {
            picked = try pickBackend(cfg: cfg, available: available)
        } catch {
            warningText = error.localizedDescription
            return
        }

        let command: [String]
        let mode: String
        switch picked {
        case .xmrig:
            guard let xmrigAlgo = cfg.xmrigAlgo else {
                warningText = "\(cfg.label) is not supported by XMRig."
                return
            }
            command = buildXMRigCommand(cfg: cfg, xmrigAlgo: xmrigAlgo, coin: coin, wallet: wallet, worker: worker, referral: referral)
            mode = "cpu"
        case .cpuminerScash:
            guard let cpuminerAlgo = cfg.cpuminerAlgo else {
                warningText = "\(cfg.label) is not supported by cpuminer-scash."
                return
            }
            command = buildCPUMinerScashCommand(cfg: cfg, cpuminerAlgo: cpuminerAlgo, coin: coin, wallet: wallet, worker: worker, referral: referral)
            mode = "cpu"
        case .uselethminer:
            guard cfg.uselethSupported else {
                warningText = "\(cfg.label) is not supported by UselethMiner."
                return
            }
            command = buildUselethCommand(cfg: cfg, coin: coin, wallet: wallet, worker: worker, referral: referral)
            if hardware == .gpu {
                mode = "gpu"
            } else if hardware == .auto {
                mode = "cpu+gpu"
            } else {
                mode = "cpu"
            }
        case .srbminer:
            do {
                command = try buildSRBCommand(cfg: cfg, coin: coin, wallet: wallet, worker: worker, referral: referral)
                mode = command.contains("--disable-cpu") ? "gpu" : "cpu"
            } catch {
                warningText = error.localizedDescription
                return
            }
        case .auto:
            warningText = "No backend selected."
            return
        }

        guard !command.isEmpty else {
            warningText = "Empty miner command."
            return
        }

        let executablePath = command[0]
        guard fileManager.fileExists(atPath: executablePath), fileManager.isExecutableFile(atPath: executablePath) else {
            warningText = "Miner binary is not executable: \(executablePath)"
            return
        }

        minerLogs = ""
        localHashrateText = "0 H/s"
        effectiveHashrateText = "0 H/s"
        hashrateSamples = []
        appendMinerLog("[system] Starting miner...")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = Array(command.dropFirst())
        process.currentDirectoryURL = URL(fileURLWithPath: executablePath).deletingLastPathComponent()

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }
            let text = String(decoding: data, as: UTF8.self)
            Task { @MainActor in
                self?.appendMinerLog(text)
            }
        }

        process.terminationHandler = { [weak self] proc in
            pipe.fileHandleForReading.readabilityHandler = nil
            Task { @MainActor in
                self?.isMining = false
                self?.statusPill = "Idle"
                self?.statusText = "Stopped (exit code \(proc.terminationStatus))."
                self?.localHashrateText = "--"
                self?.effectiveHashrateText = "--"
                self?.hashrateSamples = []
                self?.appendMinerLog("[system] Miner exited with code \(proc.terminationStatus)")
                self?.minerProcess = nil
            }
        }

        do {
            try process.run()
            minerProcess = process
            minerBackend = picked
            isMining = true
            statusPill = "Mining"
            statusText = "Running via \(picked.displayName) (\(mode))"
            if isAppleSilicon(), mode == "gpu" {
                warningText = "Apple Silicon GPU mining support is miner-dependent; if it fails, switch to CPU."
            }
            saveFormState()
        } catch {
            pipe.fileHandleForReading.readabilityHandler = nil
            warningText = "Failed to start miner: \(error.localizedDescription)"
            appendMinerLog("[system] Failed to start miner: \(error.localizedDescription)")
        }
    }

    func stopMining() {
        warningText = ""
        guard let process = minerProcess else {
            warningText = "Miner is not running."
            return
        }

        process.terminate()
        DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
            if process.isRunning {
                process.interrupt()
            }
        }
    }

    func install(target: InstallTarget, dryRun: Bool) {
        warningText = ""
        if isMining {
            warningText = "Stop mining before installing/updating."
            return
        }
        if isInstalling {
            warningText = "Installer already running."
            return
        }

        if target == .srbminer || target == .uselethminer {
            installStatusText = "\(target.displayName) is not available as a managed in-app installer target."
            if target == .uselethminer {
                warningText = "Install the official UselethMiner macOS package separately so it is present at /usr/local/uselethminer."
            } else {
                warningText = "Add a compatible custom miner path manually instead of using an installer."
            }
            return
        }
        guard let scriptURL = bundledInstallerScriptURL(target: target) else {
            warningText = "Installer is missing from the app bundle for \(target.displayName)."
            return
        }

        guard fileManager.fileExists(atPath: scriptURL.path), fileManager.isExecutableFile(atPath: scriptURL.path) else {
            warningText = "Installer not found or not executable: \(scriptURL.path)"
            return
        }

        installLogs = ""
        installStatusText = "Installing \(target.displayName)..."
        isInstalling = true

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = [scriptURL.path] + (dryRun ? ["--dry-run"] : ["--force"])
        process.environment = installerEnvironment(for: target)
        process.currentDirectoryURL = runtimeURL

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }
            let text = String(decoding: data, as: UTF8.self)
            Task { @MainActor in
                self?.appendInstallLog(text)
            }
        }

        process.terminationHandler = { [weak self] proc in
            pipe.fileHandleForReading.readabilityHandler = nil
            Task { @MainActor in
                self?.isInstalling = false
                self?.installProcess = nil
                if proc.terminationStatus == 0 {
                    self?.installStatusText = "Install/check completed for \(target.displayName)."
                } else {
                    self?.installStatusText = "Install failed for \(target.displayName) (exit \(proc.terminationStatus))."
                }
                self?.refreshMinerAvailabilityText()
                self?.validateMiners()
                if proc.terminationStatus == 0 && !dryRun && self?.defaults.bool(forKey: prefAutoInstallXMRigKey) == true {
                    self?.ensureManagedMinersInstalledIfNeeded()
                }
            }
        }

        do {
            try process.run()
            installProcess = process
        } catch {
            pipe.fileHandleForReading.readabilityHandler = nil
            isInstalling = false
            installStatusText = "Failed to launch installer."
            warningText = "Failed to launch installer: \(error.localizedDescription)"
        }
    }

    func ensureManagedMinersInstalledIfNeeded() {
        let managedTargets: [InstallTarget] = [.xmrig, .cpuminerScash]
        for target in managedTargets {
            let envName: String
            switch target {
            case .xmrig:
                envName = "XMRIG_PATH"
            case .cpuminerScash:
                envName = "CPUMINER_SCASH_PATH"
            case .uselethminer:
                envName = "USELETHMINER_PATH"
            case .srbminer:
                envName = "SRBMINER_PATH"
            }

            let envOverride = ProcessInfo.processInfo.environment[envName]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !envOverride.isEmpty {
                continue
            }

            if !hasUsableBinary(target: target) {
                installStatusText = "\(target.displayName) missing. Installing automatically..."
                install(target: target, dryRun: false)
                return
            }
        }

        refreshMinerAvailabilityText()
        if defaults.bool(forKey: prefAutoValidateOnLaunchKey) {
            validateMiners()
        }
    }

    func savePathOverride(target: InstallTarget) {
        warningText = ""
        let rawInput: String
        switch target {
        case .xmrig:
            rawInput = xmrigPathOverride
        case .cpuminerScash, .uselethminer:
            rawInput = configMinerPaths[target.rawValue] ?? ""
        case .srbminer:
            rawInput = srbminerPathOverride
        }

        let trimmed = rawInput.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            clearPathOverride(target: target)
            return
        }

        let resolvedURL: URL
        do {
            resolvedURL = try validateCustomBinaryPath(rawInput: trimmed, target: target)
        } catch {
            warningText = error.localizedDescription
            return
        }

        configMinerPaths[target.rawValue] = resolvedURL.path
        saveConfig()
        refreshMinerAvailabilityText()
        validateMiners()
    }

    func clearPathOverride(target: InstallTarget) {
        warningText = ""
        configMinerPaths.removeValue(forKey: target.rawValue)
        switch target {
        case .xmrig:
            xmrigPathOverride = ""
        case .cpuminerScash, .uselethminer:
            break
        case .srbminer:
            srbminerPathOverride = ""
        }
        saveConfig()
        refreshMinerAvailabilityText()
        validateMiners()
    }

    func validateMiners() {
        // Validation is intentionally read-only. It captures path, executable
        // status, architecture, and version output without mutating any runtime
        // payload so users can debug setup problems safely.
        let paths = effectiveMinerPaths()
        DispatchQueue.global(qos: .utility).async {
            var reports: [String] = []
            var okCount = 0
            let targets = InstallTarget.allCases

            for target in targets {
                let path = paths[target.rawValue] ?? ""
                let exists = FileManager.default.fileExists(atPath: path)
                let executable = exists && FileManager.default.isExecutableFile(atPath: path)

                var lines: [String] = []
                var ok = false
                lines.append("\(target.displayName.uppercased()): \(executable ? "CHECK" : "MISSING")")
                lines.append("  path: \(path)")
                lines.append("  exists: \(exists) | executable: \(executable)")

                if executable {
                    let arch = Self.runCapture(executable: "/usr/bin/file", arguments: ["-b", path])
                    if arch.code == 0, let first = Self.firstLine(arch.output), !first.isEmpty {
                        lines.append("  architecture: \(first)")
                        ok = true
                    }

                    switch target {
                    case .uselethminer:
                        lines.append("  version: package payload installed (version probe not exposed by binary)")
                    default:
                        let version = Self.runCapture(executable: path, arguments: ["--version"])
                        if let first = Self.firstLine(version.output), !first.isEmpty {
                            lines.append("  version: \(first)")
                            ok = true
                        } else if version.code == 0 {
                            lines.append("  warning: version output was empty.")
                        } else {
                            lines.append("  warning: version check exit code \(version.code).")
                        }
                    }
                } else {
                    lines.append("  warning: binary missing or not executable.")
                }

                if ok {
                    okCount += 1
                    lines[0] = "\(target.displayName.uppercased()): OK"
                }

                reports.append(lines.joined(separator: "\n"))
            }

            let fullText = reports.joined(separator: "\n\n")
            Task { @MainActor in
                self.validationLogs = fullText
                self.validationStatusText = "Validation complete: \(okCount)/\(targets.count) OK."
            }
        }
    }

    func bundledBinaryStatus() -> [InstallTarget: Bool] {
        Dictionary(uniqueKeysWithValues: InstallTarget.allCases.map { target in
            let path = defaultMinerPath(target: target).path
            let usable = fileManager.fileExists(atPath: path) && fileManager.isExecutableFile(atPath: path)
            return (target, usable)
        })
    }

    private func normalizeSelections(showWarning: Bool) {
        // Saved form state can outlive runtime availability. Normalization pulls
        // the UI back to the closest working configuration before any action.
        if !availableBackends.contains(backend) {
            backend = availableBackends.first ?? .xmrig
            if showWarning {
                warningText = "The selected backend is not currently installed. Setup has been normalized to the nearest working Apple Silicon backend."
            }
        }

        if !availableHardwareChoices.contains(hardware) {
            hardware = availableHardwareChoices.first ?? .cpu
            if showWarning {
                warningText = "This Mac is currently using CPU-only mode because no compatible GPU miner is installed."
            }
        }

        if backend == .xmrig, hardware == .gpu {
            hardware = .cpu
            if showWarning {
                warningText = "XMRig is CPU-only in this launcher. Hardware switched to CPU."
            }
        }
        if backend == .cpuminerScash, hardware == .gpu {
            hardware = .cpu
            if showWarning {
                warningText = "cpuminer-scash is CPU-only. Hardware switched to CPU."
            }
        }
    }

    private func refreshSelection() {
        let filtered = filteredAlgorithms
        if !filtered.contains(where: { $0.id == selectedAlgorithmID }) {
            selectedAlgorithmID = filtered.first?.id ?? ""
        }

        if let cfg = filtered.first(where: { $0.id == selectedAlgorithmID }) {
            if !cfg.ports.contains(selectedPort) {
                selectedPort = cfg.ports.first ?? 3333
            }
        } else {
            selectedPort = 3333
        }
    }

    private func sanitizeCoin(_ raw: String) -> String {
        raw.uppercased().filter { $0.isLetter || $0.isNumber }
    }

    private func sanitizeWorker(_ raw: String) -> String {
        let cleaned = raw.filter { $0.isLetter || $0.isNumber || $0 == "_" || $0 == "-" }
        if cleaned.isEmpty {
            return "macunmineable"
        }
        return cleaned
    }

    private func sanitizeReferral(_ raw: String) -> String {
        String(raw.filter { $0.isLetter || $0.isNumber }.prefix(32))
    }

    private func isAppleSilicon() -> Bool {
        #if arch(arm64)
        true
        #else
        false
        #endif
    }

    private func threadCountFromPercent() -> Int {
        let cpuCount = max(1, ProcessInfo.processInfo.processorCount)
        return max(1, Int(round(Double(cpuCount) * (threadsPercent / 100.0))))
    }

    private func buildXMRigCommand(
        cfg: AlgorithmConfig,
        xmrigAlgo: String,
        coin: String,
        wallet: String,
        worker: String,
        referral: String
    ) -> [String] {
        // unMineable expects "<coin>:<wallet>.<worker>" as the miner username.
        var user = "\(coin):\(wallet).\(worker)"
        if !referral.isEmpty {
            user += "#\(referral)"
        }
        var cmd = [
            effectiveMinerPath(target: .xmrig).path,
            "--no-color",
            "--url", "\(cfg.host):\(selectedPort)",
            "--algo", xmrigAlgo,
            "--user", user,
            "--pass", "x",
            "--keepalive",
        ]
        let hint = max(1, min(100, Int(threadsPercent)))
        cmd += ["--cpu-max-threads-hint", String(hint)]
        return cmd
    }

    private func buildCPUMinerScashCommand(
        cfg: AlgorithmConfig,
        cpuminerAlgo: String,
        coin: String,
        wallet: String,
        worker: String,
        referral: String
    ) -> [String] {
        var user = "\(coin):\(wallet).\(worker)"
        if !referral.isEmpty {
            user += "#\(referral)"
        }
        return [
            effectiveMinerPath(target: .cpuminerScash).path,
            "--algo=\(cpuminerAlgo)",
            "--url=stratum+tcp://\(cfg.host):\(selectedPort)",
            "--user=\(user)",
            "--pass=x",
            "--threads=\(threadCountFromPercent())",
            "--largepages",
            "--no-affinity",
        ]
    }

    private func buildUselethCommand(
        cfg: AlgorithmConfig,
        coin: String,
        wallet: String,
        worker: String,
        referral: String
    ) -> [String] {
        var user = "\(coin):\(wallet).\(worker)"
        if !referral.isEmpty {
            user += "#\(referral)"
        }

        var cmd = [
            effectiveMinerPath(target: .uselethminer).path,
            "--mine",
            "--host", cfg.host,
            "--port", String(selectedPort),
            "--username", user,
            "--password", "x",
            "--threads", String(max(1, threadCountFromPercent())),
        ]

        if hardware == .gpu {
            cmd += ["--flavor", "none", "--flavor-gpu", "metal"]
        } else if hardware == .auto {
            cmd += ["--flavor", "armv8af", "--size", "88", "--flavor-gpu", "metal"]
        } else {
            cmd += ["--flavor", "armv8af", "--size", "88"]
        }

        return cmd
    }

    private func buildSRBCommand(
        cfg: AlgorithmConfig,
        coin: String,
        wallet: String,
        worker: String,
        referral: String
    ) throws -> [String] {
        // Custom secondary miners can run CPU or GPU modes; the command builder
        // selects the matching algorithm and disables the unused execution path.
        var algo: String?
        var disableCPU = false
        var disableGPU = false

        if hardware == .gpu || (hardware == .auto && cfg.srbGpuAlgo != nil) {
            algo = cfg.srbGpuAlgo
            disableCPU = true
        } else if cfg.srbCpuAlgo != nil {
            algo = cfg.srbCpuAlgo
            disableGPU = true
        }

        guard let selectedAlgo = algo else {
            throw NSError(domain: "macunmineable", code: 1, userInfo: [NSLocalizedDescriptionKey: "\(cfg.label) is not supported by SRBMiner for this hardware."])
        }

        var walletPart = "\(coin):\(wallet)"
        if !referral.isEmpty {
            walletPart += "#\(referral)"
        }

        var cmd = [
            effectiveMinerPath(target: .srbminer).path,
            "--algorithm", selectedAlgo,
            "--pool", "\(cfg.host):\(selectedPort)",
            "--wallet", walletPart,
            "--worker", worker,
            "--password", "x",
        ]

        if disableCPU {
            cmd.append("--disable-cpu")
        }
        if disableGPU {
            cmd.append("--disable-gpu")
            cmd += ["--cpu-threads", String(threadCountFromPercent())]
        }
        return cmd
    }

    private func pickBackend(cfg: AlgorithmConfig, available: [String: Bool]) throws -> BackendChoice {
        // Backend selection is separate from payout coin selection. The picker
        // decides which executable can satisfy the chosen algorithm locally.
        switch backend {
        case .xmrig:
            guard available["xmrig"] == true else {
                throw NSError(domain: "macunmineable", code: 2, userInfo: [NSLocalizedDescriptionKey: "XMRig binary is not available."])
            }
            guard cfg.xmrigAlgo != nil else {
                throw NSError(domain: "macunmineable", code: 3, userInfo: [NSLocalizedDescriptionKey: "\(cfg.label) is not supported by XMRig."])
            }
            return .xmrig
        case .cpuminerScash:
            guard available["cpuminer_scash"] == true else {
                throw NSError(domain: "macunmineable", code: 10, userInfo: [NSLocalizedDescriptionKey: "cpuminer-scash binary is not available."])
            }
            guard cfg.cpuminerAlgo != nil else {
                throw NSError(domain: "macunmineable", code: 11, userInfo: [NSLocalizedDescriptionKey: "\(cfg.label) is not supported by cpuminer-scash."])
            }
            if hardware == .gpu {
                throw NSError(domain: "macunmineable", code: 12, userInfo: [NSLocalizedDescriptionKey: "cpuminer-scash is CPU-only."])
            }
            return .cpuminerScash
        case .uselethminer:
            guard available["uselethminer"] == true else {
                throw NSError(domain: "macunmineable", code: 13, userInfo: [NSLocalizedDescriptionKey: "UselethMiner payload is not available."])
            }
            guard cfg.uselethSupported else {
                throw NSError(domain: "macunmineable", code: 14, userInfo: [NSLocalizedDescriptionKey: "\(cfg.label) is not supported by UselethMiner."])
            }
            return .uselethminer
        case .srbminer:
            guard available["srbminer"] == true else {
                throw NSError(domain: "macunmineable", code: 4, userInfo: [NSLocalizedDescriptionKey: "SRBMiner binary is not available."])
            }
            if hardware == .gpu && cfg.srbGpuAlgo == nil {
                throw NSError(domain: "macunmineable", code: 5, userInfo: [NSLocalizedDescriptionKey: "\(cfg.label) has no GPU mode in SRBMiner."])
            }
            if hardware == .cpu && cfg.srbCpuAlgo == nil {
                throw NSError(domain: "macunmineable", code: 6, userInfo: [NSLocalizedDescriptionKey: "\(cfg.label) has no CPU mode in SRBMiner."])
            }
            return .srbminer
        case .auto:
            if hardware == .gpu {
                if available["uselethminer"] == true, cfg.uselethSupported {
                    return .uselethminer
                }
                if available["srbminer"] == true, cfg.srbGpuAlgo != nil {
                    return .srbminer
                }
                throw NSError(domain: "macunmineable", code: 7, userInfo: [NSLocalizedDescriptionKey: "No GPU backend available for \(cfg.label)."])
            }
            if hardware == .cpu {
                if available["xmrig"] == true, cfg.xmrigAlgo != nil {
                    return .xmrig
                }
                if available["cpuminer_scash"] == true, cfg.cpuminerAlgo != nil {
                    return .cpuminerScash
                }
                if available["uselethminer"] == true, cfg.uselethSupported {
                    return .uselethminer
                }
                if available["srbminer"] == true, cfg.srbCpuAlgo != nil {
                    return .srbminer
                }
                throw NSError(domain: "macunmineable", code: 8, userInfo: [NSLocalizedDescriptionKey: "No CPU backend available for \(cfg.label)."])
            }

            if available["uselethminer"] == true, cfg.uselethSupported {
                return .uselethminer
            }
            if available["srbminer"] == true, cfg.srbGpuAlgo != nil {
                return .srbminer
            }
            if available["xmrig"] == true, cfg.xmrigAlgo != nil {
                return .xmrig
            }
            if available["cpuminer_scash"] == true, cfg.cpuminerAlgo != nil {
                return .cpuminerScash
            }
            if available["srbminer"] == true, cfg.srbCpuAlgo != nil {
                return .srbminer
            }
            throw NSError(domain: "macunmineable", code: 9, userInfo: [NSLocalizedDescriptionKey: "No backend available for \(cfg.label)."])
        }
    }

    private func minerAvailable() -> [String: Bool] {
        let paths = effectiveMinerPaths()
        return [
            "xmrig": fileManager.fileExists(atPath: paths["xmrig"] ?? "") && fileManager.isExecutableFile(atPath: paths["xmrig"] ?? ""),
            "cpuminer_scash": fileManager.fileExists(atPath: paths["cpuminer_scash"] ?? "") && fileManager.isExecutableFile(atPath: paths["cpuminer_scash"] ?? ""),
            "uselethminer": fileManager.fileExists(atPath: paths["uselethminer"] ?? "") && fileManager.isExecutableFile(atPath: paths["uselethminer"] ?? ""),
            "srbminer": fileManager.fileExists(atPath: paths["srbminer"] ?? "") && fileManager.isExecutableFile(atPath: paths["srbminer"] ?? ""),
        ]
    }

    private func refreshMinerAvailabilityText() {
        let available = minerAvailable()
        var parts = [
            "xmrig: \(available["xmrig"] == true ? "ready" : "missing")",
            "cpuminer-scash: \(available["cpuminer_scash"] == true ? "ready" : "missing")",
            "uselethminer: \(available["uselethminer"] == true ? "ready" : "missing")",
        ]
        if available["srbminer"] == true {
            parts.append("custom srbminer: ready")
        }
        minerText = parts.joined(separator: " | ")
    }

    private func startNetworkMonitor() {
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isOnline = (path.status == .satisfied)
            }
        }
        monitor.start(queue: networkMonitorQueue)
        networkMonitor = monitor
    }

    private func effectiveMinerPaths() -> [String: String] {
        [
            "xmrig": effectiveMinerPath(target: .xmrig).path,
            "cpuminer_scash": effectiveMinerPath(target: .cpuminerScash).path,
            "uselethminer": effectiveMinerPath(target: .uselethminer).path,
            "srbminer": effectiveMinerPath(target: .srbminer).path,
        ]
    }

    private func hasUsableBinary(target: InstallTarget) -> Bool {
        let path = effectiveMinerPath(target: target).path
        return fileManager.fileExists(atPath: path) && fileManager.isExecutableFile(atPath: path)
    }

    private func effectiveMinerPath(target: InstallTarget) -> URL {
        // Path precedence is explicit: process environment for deterministic
        // automation, then saved user override, then the managed default path.
        let envName: String
        switch target {
        case .xmrig:
            envName = "XMRIG_PATH"
        case .cpuminerScash:
            envName = "CPUMINER_SCASH_PATH"
        case .uselethminer:
            envName = "USELETHMINER_PATH"
        case .srbminer:
            envName = "SRBMINER_PATH"
        }
        if let envValue = ProcessInfo.processInfo.environment[envName], !envValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return URL(fileURLWithPath: envValue)
        }
        if let override = configMinerPaths[target.rawValue], !override.isEmpty {
            return URL(fileURLWithPath: override)
        }
        return defaultMinerPath(target: target)
    }

    private func defaultMinerPath(target: InstallTarget) -> URL {
        switch target {
        case .xmrig:
            return runtimeURL.appendingPathComponent("miners/xmrig/xmrig")
        case .cpuminerScash:
            return runtimeURL.appendingPathComponent("miners/cpuminer-scash/minerd")
        case .uselethminer:
            return URL(fileURLWithPath: "/usr/local/uselethminer/uselethminer")
        case .srbminer:
            return runtimeURL.appendingPathComponent("miners/srbminer/SRBMiner-MULTI")
        }
    }

    private func appendMinerLog(_ text: String) {
        let lines = text
            .split(whereSeparator: \.isNewline)
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !lines.isEmpty else { return }

        for line in lines {
            updateHashrateFromLogLine(line)
            if minerLogs.isEmpty {
                minerLogs = line
            } else {
                minerLogs += "\n\(line)"
            }
        }
    }

    private func updateHashrateFromLogLine(_ line: String) {
        // XMRig and custom miners log speed in different formats. The parser
        // understands the stable forms we care about and ignores the rest.
        let lower = line.lowercased()

        if lower.contains("10s/60s/15m"),
           let tuple = Self.extractXMRigSpeedTuple(line)
        {
            localHashrateText = "\(tuple.tenSecond) \(tuple.unit)"
            effectiveHashrateText = "\(tuple.sixtySecond) \(tuple.unit)"
            appendHashrateSample(tuple.tenSecond)
            return
        }

        if lower.contains("hashrate") || lower.contains("speed") {
            let rates = Self.extractHashrateValues(line)
            if let first = rates.first {
                localHashrateText = first
                appendHashrateSample(first)
            }
            if rates.count > 1 {
                effectiveHashrateText = rates[1]
            } else if let first = rates.first {
                effectiveHashrateText = first
            }
        }
    }

    private func appendInstallLog(_ text: String) {
        let line = text.trimmingCharacters(in: .newlines)
        if line.isEmpty { return }
        if installLogs.isEmpty {
            installLogs = line
        } else {
            installLogs += "\n\(line)"
        }
    }

    private func appendHashrateSample(_ rawValue: String) {
        let value = Self.extractNumericValue(rawValue)
        guard value > 0 else { return }
        hashrateSamples.append(value)
        if hashrateSamples.count > 48 {
            hashrateSamples.removeFirst(hashrateSamples.count - 48)
        }
    }

    // Miner payloads are copied into Application Support so the bundled app can
    // update executables without modifying the app bundle itself. Installer
    // scripts stay in the bundle and are executed from there.
    private func bootstrapRuntime() {
        do {
            try fileManager.createDirectory(at: appSupportURL, withIntermediateDirectories: true)
            try fileManager.createDirectory(at: runtimeURL, withIntermediateDirectories: true)
            try? fileManager.setAttributes([.posixPermissions: NSNumber(value: 0o700)], ofItemAtPath: appSupportURL.path)
            try? fileManager.setAttributes([.posixPermissions: NSNumber(value: 0o700)], ofItemAtPath: runtimeURL.path)
        } catch {
            warningText = "Failed creating app support directories: \(error.localizedDescription)"
            return
        }

        guard let bundleRuntime = Bundle.main.resourceURL?.appendingPathComponent("runtime", isDirectory: true) else {
            warningText = "Missing bundled runtime resources."
            return
        }

        syncRuntimeFolder(named: "miners", from: bundleRuntime)
        ensureExecutableBit(at: runtimeURL.appendingPathComponent("miners/xmrig/xmrig").path)
        ensureExecutableBit(at: runtimeURL.appendingPathComponent("miners/cpuminer-scash/minerd").path)
        ensureExecutableBit(at: runtimeURL.appendingPathComponent("miners/srbminer/SRBMiner-MULTI").path)
    }

    // Existing runtime folders are merged forward rather than replaced so local
    // overrides or downloaded miner binaries survive subsequent app launches.
    private func syncRuntimeFolder(named folder: String, from bundleRuntime: URL) {
        let source = bundleRuntime.appendingPathComponent(folder, isDirectory: true)
        let destination = runtimeURL.appendingPathComponent(folder, isDirectory: true)
        guard fileManager.fileExists(atPath: source.path) else { return }

        if !fileManager.fileExists(atPath: destination.path) {
            do {
                try fileManager.copyItem(at: source, to: destination)
                return
            } catch {
                warningText = "Failed copying \(folder): \(error.localizedDescription)"
                return
            }
        }

        guard let enumerator = fileManager.enumerator(at: source, includingPropertiesForKeys: nil) else {
            return
        }

        for case let src as URL in enumerator {
            let relative = src.path.replacingOccurrences(of: source.path + "/", with: "")
            let dst = destination.appendingPathComponent(relative)
            var isDir: ObjCBool = false
            if fileManager.fileExists(atPath: src.path, isDirectory: &isDir), isDir.boolValue {
                if !fileManager.fileExists(atPath: dst.path) {
                    try? fileManager.createDirectory(at: dst, withIntermediateDirectories: true)
                }
                continue
            }
            if !fileManager.fileExists(atPath: dst.path) {
                try? fileManager.createDirectory(at: dst.deletingLastPathComponent(), withIntermediateDirectories: true)
                try? fileManager.copyItem(at: src, to: dst)
            }
        }
    }

    private func loadConfig() {
        guard fileManager.fileExists(atPath: configURL.path),
              let data = try? Data(contentsOf: configURL),
              let raw = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let minerPaths = raw["miner_paths"] as? [String: String]
        else {
            configMinerPaths = [:]
            xmrigPathOverride = ""
            srbminerPathOverride = ""
            return
        }

        let allowedKeys = Set(InstallTarget.allCases.map(\.rawValue))
        configMinerPaths = minerPaths.reduce(into: [String: String]()) { output, item in
            let key = item.key
            let value = item.value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard allowedKeys.contains(key), !value.isEmpty else { return }
            output[key] = value
        }
        xmrigPathOverride = configMinerPaths["xmrig"] ?? ""
        srbminerPathOverride = configMinerPaths["srbminer"] ?? ""
    }

    private func saveConfig() {
        xmrigPathOverride = configMinerPaths["xmrig"] ?? ""
        srbminerPathOverride = configMinerPaths["srbminer"] ?? ""

        let payload: [String: Any] = ["miner_paths": configMinerPaths]
        do {
            let data = try JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys])
            try data.write(to: configURL, options: [.atomic])
            try? fileManager.setAttributes([.posixPermissions: NSNumber(value: 0o600)], ofItemAtPath: configURL.path)
        } catch {
            warningText = "Failed saving config: \(error.localizedDescription)"
        }
    }

    private func loadFormState() {
        guard let blob = defaults.dictionary(forKey: formDefaultsKey) else { return }

        if let coin = blob["coin"] as? String, !coin.isEmpty {
            coinSymbol = coin
        }
        if let wallet = blob["wallet"] as? String {
            walletAddress = wallet
        }
        if let algorithm = blob["algorithm"] as? String {
            selectedAlgorithmID = algorithm
        }
        if let hardwareRaw = blob["hardware"] as? String, let value = HardwareChoice(rawValue: hardwareRaw) {
            hardware = value
        }
        if let backendRaw = blob["backend"] as? String, let value = BackendChoice(rawValue: backendRaw) {
            backend = value
        }
        if let port = blob["port"] as? Int {
            selectedPort = port
        }
        if let worker = blob["worker"] as? String {
            workerName = worker
        }
        if let referral = blob["referral"] as? String {
            referralCode = referral
        }
        if let threads = blob["threads"] as? Double {
            threadsPercent = max(1, min(100, threads))
        }
    }

    private func saveFormState() {
        let payload: [String: Any] = [
            "coin": coinSymbol,
            "wallet": walletAddress,
            "algorithm": selectedAlgorithmID,
            "hardware": hardware.rawValue,
            "backend": backend.rawValue,
            "port": selectedPort,
            "worker": workerName,
            "referral": referralCode,
            "threads": threadsPercent,
        ]
        defaults.set(payload, forKey: formDefaultsKey)
    }

    private func ensureExecutableBit(at path: String) {
        guard fileManager.fileExists(atPath: path) else { return }
        if !fileManager.isExecutableFile(atPath: path) {
            try? makeExecutable(path: path)
        }
    }

    // Installer scripts stay inside the read-only app bundle. The mutable
    // runtime directory only stores downloaded miner payloads and local config.
    private func bundledInstallerScriptURL(target: InstallTarget) -> URL? {
        let scriptName: String
        switch target {
        case .xmrig:
            scriptName = "install_xmrig.sh"
        case .cpuminerScash:
            scriptName = "install_cpuminer_scash.sh"
        case .uselethminer:
            return nil
        case .srbminer:
            return nil
        }

        if let bundled = Bundle.main.resourceURL?.appendingPathComponent("runtime/scripts/\(scriptName)"),
           fileManager.fileExists(atPath: bundled.path)
        {
            return bundled
        }
        return nil
    }

    private func installerEnvironment(for target: InstallTarget) -> [String: String] {
        var environment = ProcessInfo.processInfo.environment
        environment[installerEnvironmentName(for: target)] = defaultMinerPath(target: target).path
        environment["MACUNMINEABLE_MANAGED_INSTALL"] = "1"
        return environment
    }

    private func installerEnvironmentName(for target: InstallTarget) -> String {
        switch target {
        case .xmrig:
            return "XMRIG_PATH"
        case .cpuminerScash:
            return "CPUMINER_SCASH_PATH"
        case .uselethminer:
            return "USELETHMINER_PATH"
        case .srbminer:
            return "SRBMINER_PATH"
        }
    }

    private func validateCustomBinaryPath(rawInput: String, target: InstallTarget) throws -> URL {
        let expanded = NSString(string: rawInput).expandingTildeInPath
        let resolvedURL = URL(fileURLWithPath: expanded).standardizedFileURL.resolvingSymlinksInPath()
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: resolvedURL.path, isDirectory: &isDirectory) else {
            throw NSError(domain: "macunmineable", code: 15, userInfo: [NSLocalizedDescriptionKey: "Path does not exist: \(resolvedURL.path)"])
        }
        guard !isDirectory.boolValue else {
            throw NSError(domain: "macunmineable", code: 16, userInfo: [NSLocalizedDescriptionKey: "Expected a binary file, but found a directory: \(resolvedURL.path)"])
        }

        if !fileManager.isExecutableFile(atPath: resolvedURL.path) {
            do {
                try makeExecutable(path: resolvedURL.path)
            } catch {
                throw NSError(domain: "macunmineable", code: 17, userInfo: [NSLocalizedDescriptionKey: "Could not set executable bit: \(error.localizedDescription)"])
            }
        }
        guard fileManager.isExecutableFile(atPath: resolvedURL.path) else {
            throw NSError(domain: "macunmineable", code: 18, userInfo: [NSLocalizedDescriptionKey: "File is not executable: \(resolvedURL.path)"])
        }

        let fileInfo = Self.runCapture(executable: "/usr/bin/file", arguments: ["-b", resolvedURL.path])
        let lowered = fileInfo.output.lowercased()
        guard fileInfo.code == 0, lowered.contains("mach-o") || lowered.contains("universal binary") else {
            throw NSError(domain: "macunmineable", code: 19, userInfo: [NSLocalizedDescriptionKey: "\(target.displayName) must point to a native macOS Mach-O executable."])
        }

        return resolvedURL
    }

    private func makeExecutable(path: String) throws {
        let attrs = try fileManager.attributesOfItem(atPath: path)
        let current = (attrs[.posixPermissions] as? NSNumber)?.intValue ?? 0o644
        let updated = current | 0o111
        try fileManager.setAttributes([.posixPermissions: NSNumber(value: updated)], ofItemAtPath: path)
    }

    private func fetchCoins() {
        // Coin discovery is best-effort only. The launcher keeps a safe fallback
        // list locally and replaces it only when the unMineable API returns a
        // bounded successful response.
        guard let url = URL(string: "https://api.unminable.com/v5/coin") else { return }
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 10
        configuration.timeoutIntervalForResource = 20
        URLSession(configuration: configuration).dataTask(with: url) { [weak self] data, response, _ in
            guard let self, let data else { return }
            guard let httpResponse = response as? HTTPURLResponse, (200 ..< 300).contains(httpResponse.statusCode) else {
                return
            }
            guard data.count <= 1_000_000 else { return }
            guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let rawCoins = object["data"] as? [[String: Any]]
            else {
                return
            }

            let mapped: [CoinOption] = rawCoins.compactMap { row in
                guard let symbol = row["symbol"] as? String, !symbol.isEmpty else { return nil }
                let name = (row["name"] as? String) ?? symbol
                return CoinOption(symbol: symbol.uppercased(), name: name)
            }
            .reduce(into: [String: CoinOption]()) { out, coin in
                out[coin.symbol] = coin
            }
            .values
            .sorted { $0.symbol < $1.symbol }

            guard !mapped.isEmpty else { return }
            Task { @MainActor in
                self.coins = mapped
                if !mapped.contains(where: { $0.symbol == self.coinSymbol }) {
                    self.coinSymbol = mapped.first?.symbol ?? "BTC"
                }
            }
        }.resume()
    }

    nonisolated private static func runCapture(executable: String, arguments: [String]) -> (code: Int32, output: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
        } catch {
            return (127, error.localizedDescription)
        }

        process.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(decoding: data, as: UTF8.self)
        return (process.terminationStatus, output)
    }

    nonisolated private static func extractHashrateValues(_ text: String) -> [String] {
        let pattern = #"([0-9]+(?:\.[0-9]+)?)\s*([kKmMgGtTpP]?[hH]/s|[kKmMgGtTpP]?H/s|[kKmMgGtTpP]?h/s)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(location: 0, length: text.utf16.count)
        let matches = regex.matches(in: text, options: [], range: range)
        var out: [String] = []
        for match in matches {
            guard match.numberOfRanges >= 3,
                  let valueRange = Range(match.range(at: 1), in: text),
                  let unitRange = Range(match.range(at: 2), in: text)
            else {
                continue
            }
            let value = String(text[valueRange])
            let unit = String(text[unitRange]).uppercased()
            out.append("\(value) \(unit)")
        }
        return out
    }

    nonisolated private static func extractXMRigSpeedTuple(_ text: String) -> (tenSecond: String, sixtySecond: String, unit: String)? {
        let pattern = #"10s/60s/15m\s+([0-9]+(?:\.[0-9]+)?)\s+([0-9]+(?:\.[0-9]+)?)\s+([0-9]+(?:\.[0-9]+)?)\s+([kKmMgGtTpP]?[hH]/s|[kKmMgGtTpP]?H/s|[kKmMgGtTpP]?h/s)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(location: 0, length: text.utf16.count)
        guard let match = regex.firstMatch(in: text, options: [], range: range),
              match.numberOfRanges >= 5,
              let tenRange = Range(match.range(at: 1), in: text),
              let sixtyRange = Range(match.range(at: 2), in: text),
              let unitRange = Range(match.range(at: 4), in: text)
        else {
            return nil
        }
        return (
            tenSecond: String(text[tenRange]),
            sixtySecond: String(text[sixtyRange]),
            unit: String(text[unitRange]).uppercased()
        )
    }

    nonisolated private static func extractNumericValue(_ text: String) -> Double {
        let pattern = #"[0-9]+(?:\.[0-9]+)?"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return 0 }
        let range = NSRange(location: 0, length: text.utf16.count)
        guard let match = regex.firstMatch(in: text, options: [], range: range),
              let valueRange = Range(match.range(at: 0), in: text)
        else {
            return 0
        }
        return Double(text[valueRange]) ?? 0
    }

    nonisolated private static func firstLine(_ text: String) -> String? {
        text
            .split(whereSeparator: \.isNewline)
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .first(where: { !$0.isEmpty })
    }
}

// MARK: - Shared UI Components

struct PillView: View {
    let text: String
    let running: Bool
    let theme: DashboardTheme

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .bold))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .foregroundStyle(running ? theme.accentStart : theme.secondaryText)
            .background(running ? theme.accentSoft : theme.chromeFill)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(running ? theme.accentStart.opacity(0.45) : theme.chromeStroke, lineWidth: 1)
            )
    }
}

struct NativeSettingsView: View {
    @AppStorage(prefAutoInstallXMRigKey) private var autoInstallXMRig = true
    @AppStorage(prefAutoValidateOnLaunchKey) private var autoValidateOnLaunch = true
    @AppStorage(prefAppearanceModeKey) private var appearanceModeRaw = AppearanceMode.system.rawValue
    @AppStorage(prefPaletteKey) private var paletteRaw = AccentPalette.mint.rawValue

    private var appearanceMode: AppearanceMode {
        AppearanceMode(rawValue: appearanceModeRaw) ?? .system
    }

    private var palette: AccentPalette {
        AccentPalette(rawValue: paletteRaw) ?? .mint
    }

    var body: some View {
        Form {
            Section("Appearance") {
                Picker("Mode", selection: $appearanceModeRaw) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Text(mode.displayName).tag(mode.rawValue)
                    }
                }
                .help("Choose whether the app follows macOS appearance or forces light or dark mode.")
                Picker("Palette", selection: $paletteRaw) {
                    ForEach(AccentPalette.allCases) { option in
                        Text(option.displayName).tag(option.rawValue)
                    }
                }
                .help("Choose the accent colors used by cards, controls, and charts.")
                Text("Current: \(appearanceMode.displayName) / \(palette.displayName)")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Toggle("Auto-install managed miners if missing", isOn: $autoInstallXMRig)
                .help("Install the built-in managed miners automatically when the app detects one is missing.")
            Toggle("Validate binaries on launch", isOn: $autoValidateOnLaunch)
                .help("Run a startup validation pass that checks miner paths, executability, and architecture.")
            Text("Managed Apple Silicon installers cover XMRig and cpuminer-scash. UselethMiner is only enabled after its official macOS package installs to /usr/local/uselethminer.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

            Section("Project") {
                Text("Version: \(AppReleaseInfo.displayString)")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                Text("License: MIT")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                Button("Buy Me a Coffee") {
                    openExternalURL(supportURLString)
                }
                .help("Open the project support page in your default browser.")
            }
        }
        .padding(18)
        .frame(width: 420)
        .preferredColorScheme(appearanceMode.preferredColorScheme)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") {
                    NSApp.keyWindow?.close()
                }
                .help("Close the settings window.")
            }
        }
    }
}

struct MenuBarControlsView: View {
    @AppStorage(prefAutoInstallXMRigKey) private var autoInstallXMRig = true
    @AppStorage(prefAutoValidateOnLaunchKey) private var autoValidateOnLaunch = true

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button("Open macUnmineable") {
                NSApp.activate(ignoringOtherApps: true)
                NSApp.windows.first?.makeKeyAndOrderFront(nil)
            }
            .help("Bring the main macUnmineable window to the front.")
            Button("Settings...") {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                NSApp.activate(ignoringOtherApps: true)
            }
            .help("Open the settings window.")
            Divider()
            Toggle("Auto-install managed miners", isOn: $autoInstallXMRig)
                .help("Install built-in managed miners automatically when they are missing.")
            Toggle("Validate on launch", isOn: $autoValidateOnLaunch)
                .help("Validate miner binaries each time the app launches.")
            Divider()
            Button("Buy Me a Coffee") {
                openExternalURL(supportURLString)
            }
            .help("Open the project support page in your default browser.")
            Button("Quit") {
                NSApp.terminate(nil)
            }
            .help("Quit macUnmineable.")
        }
        .padding(10)
        .frame(width: 260)
    }
}

// MARK: - Secondary Windows

enum SecondaryPanel: String, Identifiable {
    case setup
    case advanced
    case logs
    case info

    var id: String { rawValue }
}

struct DashboardCard<Content: View>: View {
    let padding: CGFloat
    let theme: DashboardTheme
    let content: Content

    init(padding: CGFloat = 22, theme: DashboardTheme, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.theme = theme
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .padding(padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(theme.cardFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(theme.cardStroke, lineWidth: 1)
        )
        .shadow(color: theme.shadow, radius: 28, x: 0, y: 14)
    }
}

struct IconChromeButton: View {
    let systemName: String
    let theme: DashboardTheme
    let helpText: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .semibold))
                .frame(width: 34, height: 34)
                .foregroundStyle(theme.secondaryText)
                .background(
                    Circle()
                        .fill(theme.chromeFill)
                )
                .overlay(
                    Circle()
                        .stroke(theme.chromeStroke, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .help(helpText)
    }
}

struct CoinBadge: View {
    let symbol: String
    let theme: DashboardTheme

    var body: some View {
        Text(symbol)
            .font(.system(size: 19, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: 52, height: 52)
            .background(
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [theme.accentStart, theme.accentEnd],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
    }
}

struct SessionLine: View {
    let label: String
    let value: String
    let theme: DashboardTheme
    var helpText: String? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(label)
                .foregroundStyle(theme.tertiaryText)
            Text(value)
                .foregroundStyle(theme.primaryText)
                .fontWeight(.semibold)
            Spacer(minLength: 0)
        }
        .font(.system(size: 17, weight: .regular, design: .rounded))
        .help(helpText ?? "\(label): \(value)")
    }
}

struct FieldShell<Content: View>: View {
    let title: String
    let theme: DashboardTheme
    let content: Content

    init(title: String, theme: DashboardTheme, @ViewBuilder content: () -> Content) {
        self.title = title
        self.theme = theme
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(theme.tertiaryText)
                .tracking(0.8)
            content
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(theme.fieldFill)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(theme.fieldStroke, lineWidth: 1)
                )
        }
    }
}

struct SelectionFieldLabel: View {
    let text: String
    let theme: DashboardTheme

    var body: some View {
        HStack(spacing: 10) {
            Text(text)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(theme.primaryText)
                .lineLimit(1)
            Spacer()
            Image(systemName: "chevron.down")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(theme.tertiaryText)
        }
    }
}

struct SegmentedChoiceButton: View {
    let title: String
    let selected: Bool
    let theme: DashboardTheme
    let helpText: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(selected ? .white : theme.secondaryText)
                .padding(.vertical, 7)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            selected
                                ? theme.segmentFill
                                : Color.clear
                        )
                )
        }
        .buttonStyle(.plain)
        .help(helpText)
    }
}

struct MetricBlock: View {
    let title: String
    let value: String
    let theme: DashboardTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(theme.secondaryText)
            Text(value)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(theme.primaryText)
        }
    }
}

struct HashrateSparkline: View {
    let values: [Double]
    let theme: DashboardTheme

    var body: some View {
        GeometryReader { proxy in
            let plotted = values.isEmpty ? [0, 0, 0, 0, 0, 0] : values
            let minValue = plotted.min() ?? 0
            let maxValue = plotted.max() ?? 1
            let span = max(maxValue - minValue, 1)

            ZStack {
                Capsule()
                    .fill(theme.accentSoft)
                    .frame(height: 8)

                Path { path in
                    for index in plotted.indices {
                        let x = proxy.size.width * CGFloat(index) / CGFloat(max(plotted.count - 1, 1))
                        let normalized = (plotted[index] - minValue) / span
                        let y = proxy.size.height - (CGFloat(normalized) * (proxy.size.height - 10)) - 5
                        if index == plotted.startIndex {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(
                    theme.accentLine,
                    style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                )
            }
        }
        .frame(height: 34)
    }
}

struct SetupSheetView: View {
    @ObservedObject var model: NativeAppModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let bundled = model.bundledBinaryStatus()
        NavigationStack {
            Form {
                Section("Apple Silicon Runtime") {
                    Text(model.appleSiliconMiningSummary)
                        .foregroundStyle(.secondary)
                        .font(.system(size: 12))
                }

                Section("Official Miner Matrix") {
                    Text("Checked against official upstream releases and startup behavior on March 24, 2026.")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 12))
                    Text("XMRig: macOS arm64 release available")
                    Text("cpuminer-scash: macOS Sonoma arm64 release available")
                    Text("UselethMiner: official macOS arm64 package exists, but upstream requires installation to /usr/local/uselethminer; it is not a managed in-app backend")
                    Text("SRBMiner-MULTI: no normal macOS release asset")
                    Text("nanominer: latest release is Linux/Windows only")
                    Text("BzMiner: latest release is Linux/Windows only")
                    Text("OneZeroMiner: generic tarball is Linux ELF x86-64, not macOS")
                }

                Section("Installed Miner Binaries") {
                    Text("XMRig installed: \(bundled[.xmrig] == true ? "Yes" : "No")")
                    Text("cpuminer-scash installed: \(bundled[.cpuminerScash] == true ? "Yes" : "No")")
                    Text("UselethMiner detected at /usr/local/uselethminer: \(bundled[.uselethminer] == true ? "Yes" : "No")")
                    Text("Custom SRBMiner present: \(model.hasUsableSRBMinerBinary ? "Yes" : "No")")
                }

                Section("Managed Miners") {
                    HStack(spacing: 10) {
                        Button("Install / Update XMRig") {
                            model.install(target: .xmrig, dryRun: false)
                        }
                        .buttonStyle(.bordered)
                        .disabled(model.isInstalling || model.isMining)
                        .help("Download or refresh the managed XMRig binary into the local runtime.")

                        Button("Check XMRig Release") {
                            model.install(target: .xmrig, dryRun: true)
                        }
                        .buttonStyle(.bordered)
                        .disabled(model.isInstalling || model.isMining)
                        .help("Resolve and display the upstream XMRig release without changing local files.")
                    }

                    HStack(spacing: 10) {
                        Button("Install / Update cpuminer-scash") {
                            model.install(target: .cpuminerScash, dryRun: false)
                        }
                        .buttonStyle(.bordered)
                        .disabled(model.isInstalling || model.isMining)
                        .help("Download or refresh the managed cpuminer-scash binary into the local runtime.")

                        Button("Check cpuminer-scash Release") {
                            model.install(target: .cpuminerScash, dryRun: true)
                        }
                        .buttonStyle(.bordered)
                        .disabled(model.isInstalling || model.isMining)
                        .help("Resolve and display the upstream cpuminer-scash release without changing local files.")
                    }

                    Text("Managed miner downloads are verified before install. Tarball-based miners use upstream SHA256 manifests. UselethMiner is excluded here because its upstream macOS package expects a system install path instead of an app-managed runtime copy.")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 12))
                }

                Section("Custom Miner Paths") {
                    pathEditor(
                        title: "XMRig Binary Path",
                        text: $model.xmrigPathOverride,
                        onSave: { model.savePathOverride(target: .xmrig) },
                        onClear: { model.clearPathOverride(target: .xmrig) }
                    )
                    pathEditor(
                        title: "SRBMiner Binary Path",
                        text: $model.srbminerPathOverride,
                        onSave: { model.savePathOverride(target: .srbminer) },
                        onClear: { model.clearPathOverride(target: .srbminer) }
                    )
                    Text("Only add SRBMiner here if you already have a macOS-compatible custom build. The app no longer surfaces it as a normal Apple Silicon installer target.")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 12))
                    Text("UselethMiner is only recognized when the official upstream package has installed it to /usr/local/uselethminer.")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 12))
                    Text("Built-in Apple Silicon miners are limited to the managed backends the app can verify and update safely.")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 12))
                }

                Section("Validation") {
                    Button("Validate Binaries") {
                        model.validateMiners()
                    }
                    .buttonStyle(.bordered)
                    .disabled(model.isInstalling)
                    .help("Check every configured miner path for existence, executability, architecture, and version output.")

                    Text(model.validationStatusText)
                        .foregroundStyle(.secondary)
                        .font(.system(size: 12))
                    TextEditor(text: $model.validationLogs)
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 180)
                        .disabled(true)
                }

                Section("Installer Output") {
                    Text(model.installStatusText)
                        .foregroundStyle(.secondary)
                        .font(.system(size: 12))
                    TextEditor(text: $model.installLogs)
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 200)
                        .disabled(true)
                }
            }
            .navigationTitle("Setup")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .help("Close the setup window.")
                }
            }
        }
        .frame(minWidth: 780, minHeight: 720)
    }

    @ViewBuilder
    private func pathEditor(
        title: String,
        text: Binding<String>,
        onSave: @escaping () -> Void,
        onClear: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            HStack(spacing: 10) {
                TextField("/absolute/path/to/binary", text: text)
                    .help("Paste an absolute path to a native macOS Mach-O miner binary.")
                Button("Save", action: onSave)
                    .buttonStyle(.bordered)
                    .help("Save this custom binary path after validating that it is executable.")
                Button("Clear", action: onClear)
                    .buttonStyle(.bordered)
                    .help("Remove the saved custom path and fall back to the managed runtime binary.")
            }
        }
    }
}

struct AdvancedMiningSheetView: View {
    @ObservedObject var model: NativeAppModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Main screen only needs coin, wallet, algorithm, and hardware.")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 12))
                }

                Section("Connection") {
                    Picker("Pool Port", selection: $model.selectedPort) {
                        ForEach(model.portOptions, id: \.self) { port in
                            Text(String(port)).tag(port)
                        }
                    }
                    .help("Select the unMineable port used for the current algorithm.")
                    .onChange(of: model.selectedPort) { _, _ in
                        model.handleAlgorithmOrPortChange()
                    }

                    if model.availableBackends.count == 1 {
                        Text("Backend: \(model.availableBackends[0].displayName)")
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Backend", selection: $model.backend) {
                            ForEach(model.availableBackends) { backend in
                                Text(backend.displayName).tag(backend)
                            }
                        }
                        .help("Choose which installed miner backend should run the selected algorithm.")
                        .onChange(of: model.backend) { _, _ in
                            model.handleBackendChange()
                        }
                    }
                }

                Section("Worker") {
                    TextField("Worker (optional)", text: $model.workerName)
                        .help("Optional worker label appended to the unMineable username.")
                        .onChange(of: model.workerName) { _, _ in
                            model.handleSimpleFormChange()
                        }
                    TextField("Referral (optional)", text: $model.referralCode)
                        .help("Optional referral code appended to the unMineable username.")
                        .onChange(of: model.referralCode) { _, _ in
                            model.handleSimpleFormChange()
                        }
                }

                Section("CPU") {
                    Text("CPU Usage: \(Int(model.threadsPercent))%")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 12))
                    Slider(value: $model.threadsPercent, in: 1 ... 100, step: 1)
                        .help("Limit CPU thread usage for CPU-capable backends.")
                        .onChange(of: model.threadsPercent) { _, _ in
                            model.handleSimpleFormChange()
                        }
                }
            }
            .navigationTitle("Advanced")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .help("Close the advanced options window.")
                }
            }
        }
        .frame(minWidth: 520, minHeight: 380)
    }
}

struct LogsSheetView: View {
    @ObservedObject var model: NativeAppModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 10) {
                HStack {
                    Spacer()
                    Button("Clear Logs") {
                        model.clearMinerLogs()
                    }
                    .buttonStyle(.bordered)
                    .help("Clear the visible miner log output.")
                }
                TextEditor(text: $model.minerLogs)
                    .font(.system(.body, design: .monospaced))
                    .disabled(true)
            }
            .padding(14)
            .navigationTitle("Logs")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .help("Close the logs window.")
                }
            }
        }
        .frame(minWidth: 860, minHeight: 620)
    }
}

struct InfoSheetView: View {
    @ObservedObject var model: NativeAppModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Pool") {
                    Text("Host: \(model.selectedPoolHost)")
                    Text("Port: \(model.selectedPort)")
                    Button(model.isTestingConnection ? "Testing..." : "Test unMineable Pool Connection") {
                        model.testUnmineableConnection()
                    }
                    .buttonStyle(.bordered)
                    .disabled(model.isTestingConnection)
                    .help("Open a short TCP connection test to the selected unMineable host and port.")
                    Text(model.poolConnectionText)
                        .foregroundStyle(.secondary)
                        .font(.system(size: 12))
                }

                Section("Session") {
                    Text(model.statusText)
                    Text("Coin: \(model.coinSymbol)")
                    Text("Wallet: \(model.displayWallet())")
                    Text("Algorithm: \(model.selectedAlgorithm?.label ?? "-")")
                    Text("Backend: \(model.displayedBackendName)")
                    Text("Worker: \(model.displayWorker())")
                }

                Section("System") {
                    Text(model.minerText)
                    Text(model.systemText)
                    if !model.warningText.isEmpty {
                        Text(model.warningText)
                            .foregroundStyle(.orange)
                    }
                }

                Section("Project") {
                    Text("Version: \(AppReleaseInfo.displayString)")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 12))
                    Button("Buy Me a Coffee") {
                        openExternalURL(supportURLString)
                    }
                    .help("Open the project support page in your default browser.")
                    Text("License and third-party notices are included in the repository.")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 12))
                }
            }
            .navigationTitle("Status")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .help("Close the status window.")
                }
            }
        }
        .frame(minWidth: 540, minHeight: 420)
    }
}

// MARK: - Main Dashboard

struct MineDashboardView: View {
    @ObservedObject var model: NativeAppModel
    @Binding var activePanel: SecondaryPanel?
    let theme: DashboardTheme

    private var localHashrate: String {
        model.isMining ? model.localHashrateText : "0 H/s"
    }

    private var effectiveHashrate: String {
        model.isMining ? model.effectiveHashrateText : "0 H/s"
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                HStack(spacing: 10) {
                    Text("macUnmineable")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(theme.secondaryText)
                    Spacer()
                    PillView(text: model.isOnline ? "Online" : "Offline", running: model.isOnline, theme: theme)
                    IconChromeButton(systemName: "paintpalette.fill", theme: theme, helpText: "Open appearance settings.") {
                        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                        NSApp.activate(ignoringOtherApps: true)
                    }
                    IconChromeButton(systemName: "folder.fill", theme: theme, helpText: "Open miner setup, validation, and install tools.") {
                        activePanel = .setup
                    }
                }

                DashboardCard(theme: theme) {
                    HStack(alignment: .top, spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(localHashrate)
                                .font(.system(size: 54, weight: .bold, design: .rounded))
                                .foregroundStyle(theme.primaryText)
                            Text(model.isMining ? "Live hashrate" : "Not mining")
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundStyle(theme.tertiaryText)
                        }
                        Spacer()
                        CoinBadge(symbol: model.coinSymbol, theme: theme)
                    }
                    .padding(.bottom, 18)

                    VStack(alignment: .leading, spacing: 6) {
                        SessionLine(label: "Address", value: model.displayWallet(), theme: theme, helpText: model.walletAddress.isEmpty ? "Wallet address is not set." : model.walletAddress)
                        SessionLine(label: "Coin", value: model.coinSymbol, theme: theme)
                        SessionLine(label: "Algorithm", value: model.selectedAlgorithm?.label ?? "-", theme: theme)
                        SessionLine(label: "Device", value: model.hardware.displayName, theme: theme)
                        SessionLine(label: "Backend", value: model.displayedBackendName, theme: theme)
                        SessionLine(label: "Worker", value: model.displayWorker(), theme: theme)
                        SessionLine(label: "Port", value: String(model.selectedPort), theme: theme)
                        SessionLine(label: "Pool", value: model.selectedPoolHost, theme: theme, helpText: "Current pool host: \(model.selectedPoolHost)")
                    }
                }

                DashboardCard(theme: theme) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Wallet only. Worker name stays optional in Advanced.")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(theme.tertiaryText)
                        Text(model.appleSiliconMiningSummary)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(theme.secondaryText)

                        HStack(alignment: .top, spacing: 14) {
                            FieldShell(title: "Coin", theme: theme) {
                                Menu {
                                    ForEach(model.coins) { coin in
                                        Button("\(coin.symbol) - \(coin.name)") {
                                            model.coinSymbol = coin.symbol
                                            model.handleSimpleFormChange()
                                        }
                                    }
                                }
                                label: {
                                    SelectionFieldLabel(text: model.coinSymbol, theme: theme)
                                }
                                .buttonStyle(.plain)
                                .help("Choose the payout coin. This does not change the miner backend by itself.")
                            }

                            FieldShell(title: "Algorithm", theme: theme) {
                                Menu {
                                    ForEach(model.filteredAlgorithms) { alg in
                                        Button(alg.label) {
                                            model.selectedAlgorithmID = alg.id
                                            model.handleAlgorithmOrPortChange()
                                        }
                                    }
                                }
                                label: {
                                    SelectionFieldLabel(text: model.selectedAlgorithm?.label ?? "No Match", theme: theme)
                                }
                                .buttonStyle(.plain)
                                .help("Choose the mining algorithm that will connect to the matching unMineable pool.")
                            }
                        }

                        FieldShell(title: "Wallet", theme: theme) {
                            TextField(
                                "",
                                text: $model.walletAddress,
                                prompt: Text("Paste wallet address").foregroundStyle(theme.tertiaryText)
                            )
                                .textFieldStyle(.plain)
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundStyle(theme.primaryText)
                                .tint(theme.accentStart)
                                .help("Paste the payout wallet address. This is the only required identity field.")
                                .onChange(of: model.walletAddress) { _, _ in
                                    model.handleSimpleFormChange()
                                }
                        }

                        FieldShell(title: "Hardware", theme: theme) {
                            if model.availableHardwareChoices.count == 1 {
                                Text("CPU only on this Mac")
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundStyle(theme.primaryText)
                            } else {
                                HStack(spacing: 8) {
                                    ForEach(model.availableHardwareChoices) { hw in
                                        SegmentedChoiceButton(
                                            title: hw.displayName,
                                            selected: model.hardware == hw,
                                            theme: theme,
                                            helpText: "Use \(hw.displayName.lowercased()) mode for the selected miner backend.",
                                            action: {
                                                model.hardware = hw
                                                model.handleHardwareChange()
                                            }
                                        )
                                    }
                                }
                            }
                        }

                        HStack(spacing: 12) {
                            Button(model.isTestingConnection ? "Testing Pool..." : "Test Pool") {
                                model.testUnmineableConnection()
                            }
                            .buttonStyle(.bordered)
                            .disabled(model.isTestingConnection)
                            .help("Test reachability to the selected unMineable pool before mining.")

                            Text(model.poolConnectionText)
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(theme.secondaryText)
                                .lineLimit(2)

                            Spacer()
                        }

                        Text(model.statusText)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(theme.tertiaryText)

                        if !model.warningText.isEmpty {
                            Text(model.warningText)
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.orange)
                        }
                    }
                }

                DashboardCard(padding: 16, theme: theme) {
                    VStack(spacing: 16) {
                        HashrateSparkline(values: model.hashrateSamples, theme: theme)

                        HStack(alignment: .bottom, spacing: 20) {
                            MetricBlock(title: "Local Hashrate", value: localHashrate, theme: theme)
                            MetricBlock(title: "Effective Hashrate", value: effectiveHashrate, theme: theme)
                            Spacer()
                            HStack(spacing: 10) {
                                IconChromeButton(systemName: "globe", theme: theme, helpText: "Open pool, session, and project status.") {
                                    activePanel = .info
                                }
                                IconChromeButton(systemName: "doc.text", theme: theme, helpText: "Open miner output logs.") {
                                    activePanel = .logs
                                }
                                IconChromeButton(systemName: "gearshape", theme: theme, helpText: "Open advanced mining options.") {
                                    activePanel = .advanced
                                }

                                Button(model.isMining ? "Stop" : "Mine") {
                                    if model.isMining {
                                        model.stopMining()
                                    } else {
                                        model.startMining()
                                    }
                                }
                                .buttonStyle(.plain)
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 24)
                                .frame(height: 54)
                                .background(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .fill(
                                            model.isMining
                                                ? theme.stopButtonFill
                                                : theme.idleButtonFill
                                        )
                                )
                                .opacity(model.isInstalling ? 0.5 : 1)
                                .disabled(model.isInstalling)
                                .help(model.isMining ? "Stop the active miner process." : "Start mining with the current coin, wallet, algorithm, and hardware selection.")
                            }
                        }
                    }
                }
            }
            .padding(20)
        }
    }
}

struct NativeContentView: View {
    @StateObject private var model = NativeAppModel()
    @State private var activePanel: SecondaryPanel?
    @AppStorage(prefAppearanceModeKey) private var appearanceModeRaw = AppearanceMode.system.rawValue
    @AppStorage(prefPaletteKey) private var paletteRaw = AccentPalette.mint.rawValue
    @Environment(\.colorScheme) private var systemColorScheme

    private var appearanceMode: AppearanceMode {
        AppearanceMode(rawValue: appearanceModeRaw) ?? .system
    }

    private var palette: AccentPalette {
        AccentPalette(rawValue: paletteRaw) ?? .mint
    }

    private var resolvedColorScheme: ColorScheme {
        appearanceMode.preferredColorScheme ?? systemColorScheme
    }

    private var theme: DashboardTheme {
        DashboardTheme.make(colorScheme: resolvedColorScheme, palette: palette)
    }

    var body: some View {
        MineDashboardView(model: model, activePanel: $activePanel, theme: theme)
            .background(
                ZStack {
                    LinearGradient(
                        colors: [
                            theme.backgroundTop,
                            theme.backgroundBottom,
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )

                    Circle()
                        .fill(theme.ghostOrbFill)
                        .frame(width: 180, height: 180)
                        .offset(x: -340, y: 260)

                    Circle()
                        .fill(theme.orbFill)
                        .frame(width: 260, height: 260)
                        .offset(x: 360, y: -260)
                }
                .ignoresSafeArea()
            )
            .sheet(item: $activePanel) { panel in
                switch panel {
                case .setup:
                    SetupSheetView(model: model)
                case .advanced:
                    AdvancedMiningSheetView(model: model)
                case .logs:
                    LogsSheetView(model: model)
                case .info:
                    InfoSheetView(model: model)
                }
            }
            .preferredColorScheme(appearanceMode.preferredColorScheme)
            .frame(minWidth: 920, minHeight: 740)
    }
}

@main
struct MacUnmineableNativeApp: App {
    var body: some Scene {
        WindowGroup("macUnmineable") {
            NativeContentView()
        }
        .windowStyle(.hiddenTitleBar)

        MenuBarExtra("macUnmineable", systemImage: "bitcoinsign.circle.fill") {
            MenuBarControlsView()
        }

        Settings {
            NativeSettingsView()
        }
    }
}
