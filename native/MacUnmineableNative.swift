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
    case srbminer

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .auto: return "Auto"
        case .xmrig: return "XMRig"
        case .srbminer: return "SRBMiner"
        }
    }
}

enum InstallTarget: String {
    case xmrig
    case srbminer
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
    .init(id: "rx", label: "RandomX", host: "rx.unmineable.com", ports: [3333, 13333, 4445], xmrigAlgo: "rx", srbCpuAlgo: "randomx", srbGpuAlgo: nil),
    .init(id: "ghostrider", label: "GhostRider", host: "ghostrider.unmineable.com", ports: [3333, 13333], xmrigAlgo: "gr", srbCpuAlgo: "ghostrider", srbGpuAlgo: nil),
    .init(id: "etchash", label: "Etchash", host: "etchash.unmineable.com", ports: [3333, 13333], xmrigAlgo: nil, srbCpuAlgo: nil, srbGpuAlgo: "etchash"),
    .init(id: "ethash", label: "Ethash", host: "ethash.unmineable.com", ports: [3333, 13333], xmrigAlgo: nil, srbCpuAlgo: nil, srbGpuAlgo: "ethash"),
    .init(id: "kp", label: "KawPow", host: "kp.unmineable.com", ports: [3333, 13333], xmrigAlgo: "kawpow", srbCpuAlgo: nil, srbGpuAlgo: "kawpow"),
    .init(id: "autolykos", label: "Autolykos", host: "autolykos.unmineable.com", ports: [3333, 13333], xmrigAlgo: nil, srbCpuAlgo: nil, srbGpuAlgo: "autolykos2"),
]

private let prefAutoInstallXMRigKey = "macunmineable.pref.autoInstallXmrig"
private let prefAutoValidateOnLaunchKey = "macunmineable.pref.autoValidateOnLaunch"
private let prefAppearanceModeKey = "macunmineable.pref.appearanceMode"
private let prefPaletteKey = "macunmineable.pref.palette"
private let supportURLString = "https://buymeacoffee.com/einnovoeg"

private func openExternalURL(_ rawValue: String) {
    guard let url = URL(string: rawValue) else { return }
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
    // optionally installs/validates XMRig depending on user preferences.
    init() {
        defaults.register(defaults: [
            prefAutoInstallXMRigKey: true,
            prefAutoValidateOnLaunchKey: true,
        ])
        let supportRoot = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        appSupportURL = supportRoot.appendingPathComponent("macUnmineable", isDirectory: true)
        runtimeURL = appSupportURL.appendingPathComponent("runtime", isDirectory: true)
        configURL = appSupportURL.appendingPathComponent("local_config.json", isDirectory: false)
        systemText = "\(ProcessInfo.processInfo.hostName) | \(ProcessInfo.processInfo.operatingSystemVersionString)"

        bootstrapRuntime()
        loadConfig()
        loadFormState()
        normalizeSelections(showWarning: false)
        refreshSelection()
        refreshMinerAvailabilityText()
        fetchCoins()
        startNetworkMonitor()
        if defaults.bool(forKey: prefAutoInstallXMRigKey) {
            ensureXMRigInstalledIfNeeded()
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
        let srbminerReady = hasUsableSRBMinerBinary
        switch backend {
        case .xmrig:
            if hardware == .gpu {
                return []
            }
            return algorithms.filter { $0.xmrigAlgo != nil }
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
                return srbminerReady ? algorithms.filter { $0.srbGpuAlgo != nil } : []
            case .cpu:
                return algorithms.filter { $0.xmrigAlgo != nil || (srbminerReady && $0.srbCpuAlgo != nil) }
            case .auto:
                return algorithms.filter { $0.xmrigAlgo != nil || (srbminerReady && ($0.srbCpuAlgo != nil || $0.srbGpuAlgo != nil)) }
            }
        }
    }

    var hasUsableSRBMinerBinary: Bool {
        let path = effectiveMinerPath(target: .srbminer).path
        return fileManager.fileExists(atPath: path) && fileManager.isExecutableFile(atPath: path)
    }

    var availableBackends: [BackendChoice] {
        if hasUsableSRBMinerBinary {
            return [.auto, .xmrig, .srbminer]
        }
        return isAppleSilicon() ? [.xmrig] : [.auto, .xmrig]
    }

    var availableHardwareChoices: [HardwareChoice] {
        if hasUsableSRBMinerBinary {
            return [.auto, .cpu, .gpu]
        }
        return isAppleSilicon() ? [.cpu] : [.auto, .cpu]
    }

    var appleSiliconMiningSummary: String {
        if hasUsableSRBMinerBinary {
            return "XMRig is the default Apple Silicon path. Custom SRBMiner support is available because a local binary is present. Your payout coin, algorithm, and backend are separate settings."
        }
        if !isAppleSilicon() {
            return "This Mac is currently running with XMRig only. Add a compatible custom miner if you want additional algorithms. Your payout coin and backend are separate settings."
        }
        return "Apple Silicon mode: XMRig CPU only. Supported algorithms here are RandomX, GhostRider, and KawPow. Your payout coin and backend are separate settings."
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
        if picked == .xmrig {
            guard let xmrigAlgo = cfg.xmrigAlgo else {
                warningText = "\(cfg.label) is not supported by XMRig."
                return
            }
            command = buildXMRigCommand(cfg: cfg, xmrigAlgo: xmrigAlgo, coin: coin, wallet: wallet, worker: worker, referral: referral)
            mode = "cpu"
        } else {
            do {
                command = try buildSRBCommand(cfg: cfg, coin: coin, wallet: wallet, worker: worker, referral: referral)
                mode = command.contains("--disable-cpu") ? "gpu" : "cpu"
            } catch {
                warningText = error.localizedDescription
                return
            }
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
        process.currentDirectoryURL = runtimeURL

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

        guard target == .xmrig else {
            installStatusText = "No official installer is available for custom secondary miners."
            warningText = "Add a compatible custom miner path manually instead of using an installer."
            return
        }
        let scriptURL = runtimeURL.appendingPathComponent("scripts/install_xmrig.sh")

        guard fileManager.fileExists(atPath: scriptURL.path), fileManager.isExecutableFile(atPath: scriptURL.path) else {
            warningText = "Installer not found or not executable: \(scriptURL.path)"
            return
        }

        installLogs = ""
        installStatusText = "Installing \(target.rawValue)..."
        isInstalling = true

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = [scriptURL.path] + (dryRun ? ["--dry-run"] : [])
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
                    self?.installStatusText = "Install/check completed for \(target.rawValue)."
                } else {
                    self?.installStatusText = "Install failed for \(target.rawValue) (exit \(proc.terminationStatus))."
                }
                self?.refreshMinerAvailabilityText()
                self?.validateMiners()
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

    func ensureXMRigInstalledIfNeeded() {
        let envOverride = ProcessInfo.processInfo.environment["XMRIG_PATH"]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !envOverride.isEmpty {
            refreshMinerAvailabilityText()
            if defaults.bool(forKey: prefAutoValidateOnLaunchKey) {
                validateMiners()
            }
            return
        }

        let xmrigPath = effectiveMinerPath(target: .xmrig).path
        let isReady = fileManager.fileExists(atPath: xmrigPath) && fileManager.isExecutableFile(atPath: xmrigPath)
        if isReady {
            refreshMinerAvailabilityText()
            if defaults.bool(forKey: prefAutoValidateOnLaunchKey) {
                validateMiners()
            }
            return
        }

        installStatusText = "XMRig missing. Installing automatically..."
        install(target: .xmrig, dryRun: false)
    }

    func savePathOverride(target: InstallTarget) {
        warningText = ""
        let rawInput: String
        switch target {
        case .xmrig:
            rawInput = xmrigPathOverride
        case .srbminer:
            rawInput = srbminerPathOverride
        }

        let trimmed = rawInput.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            clearPathOverride(target: target)
            return
        }

        let expanded = NSString(string: trimmed).expandingTildeInPath
        let pathURL = URL(fileURLWithPath: expanded)
        guard fileManager.fileExists(atPath: pathURL.path) else {
            warningText = "Path does not exist: \(pathURL.path)"
            return
        }

        if !fileManager.isExecutableFile(atPath: pathURL.path) {
            do {
                try makeExecutable(path: pathURL.path)
            } catch {
                warningText = "Could not set executable bit: \(error.localizedDescription)"
                return
            }
        }
        guard fileManager.isExecutableFile(atPath: pathURL.path) else {
            warningText = "File is not executable: \(pathURL.path)"
            return
        }

        configMinerPaths[target.rawValue] = pathURL.path
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
        case .srbminer:
            srbminerPathOverride = ""
        }
        saveConfig()
        refreshMinerAvailabilityText()
        validateMiners()
    }

    func validateMiners() {
        let paths = effectiveMinerPaths()
        DispatchQueue.global(qos: .utility).async {
            var reports: [String] = []
            var okCount = 0
            let targets = ["xmrig", "srbminer"]

            for target in targets {
                let path = paths[target] ?? ""
                let exists = FileManager.default.fileExists(atPath: path)
                let executable = exists && FileManager.default.isExecutableFile(atPath: path)

                var lines: [String] = []
                var ok = false
                lines.append("\(target.uppercased()): \(executable ? "CHECK" : "MISSING")")
                lines.append("  path: \(path)")
                lines.append("  exists: \(exists) | executable: \(executable)")

                if executable {
                    let arch = Self.runCapture(executable: "/usr/bin/file", arguments: ["-b", path])
                    if arch.code == 0, let first = Self.firstLine(arch.output), !first.isEmpty {
                        lines.append("  architecture: \(first)")
                    }

                    let version = Self.runCapture(executable: path, arguments: ["--version"])
                    if let first = Self.firstLine(version.output), !first.isEmpty {
                        lines.append("  version: \(first)")
                        ok = true
                    } else if version.code == 0 {
                        lines.append("  warning: version output was empty.")
                        ok = true
                    } else {
                        lines.append("  warning: version check exit code \(version.code).")
                    }
                } else {
                    lines.append("  warning: binary missing or not executable.")
                }

                if ok {
                    okCount += 1
                    lines[0] = "\(target.uppercased()): OK"
                }

                reports.append(lines.joined(separator: "\n"))
            }

            let fullText = reports.joined(separator: "\n\n")
            Task { @MainActor in
                self.validationLogs = fullText
                self.validationStatusText = "Validation complete: \(okCount)/2 OK."
            }
        }
    }

    func bundledBinaryStatus() -> (xmrig: Bool, srbminer: Bool) {
        let xmrigPath = defaultMinerPath(target: .xmrig).path
        let srbPath = defaultMinerPath(target: .srbminer).path
        let xmrig = fileManager.fileExists(atPath: xmrigPath) && fileManager.isExecutableFile(atPath: xmrigPath)
        let srb = fileManager.fileExists(atPath: srbPath) && fileManager.isExecutableFile(atPath: srbPath)
        return (xmrig, srb)
    }

    private func normalizeSelections(showWarning: Bool) {
        // Saved form state can outlive runtime availability. Normalization pulls
        // the UI back to the closest working configuration before any action.
        if !availableBackends.contains(backend) {
            backend = availableBackends.first ?? .xmrig
            if showWarning {
                warningText = "This Mac is currently using XMRig-only mode because no compatible secondary miner is installed."
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
            let cpuCount = ProcessInfo.processInfo.processorCount
            let threadCount = max(1, Int(round(Double(cpuCount) * (threadsPercent / 100.0))))
            cmd += ["--cpu-threads", String(threadCount)]
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
                if available["srbminer"] == true, cfg.srbGpuAlgo != nil {
                    return .srbminer
                }
                throw NSError(domain: "macunmineable", code: 7, userInfo: [NSLocalizedDescriptionKey: "No GPU backend available for \(cfg.label)."])
            }
            if hardware == .cpu {
                if available["xmrig"] == true, cfg.xmrigAlgo != nil {
                    return .xmrig
                }
                if available["srbminer"] == true, cfg.srbCpuAlgo != nil {
                    return .srbminer
                }
                throw NSError(domain: "macunmineable", code: 8, userInfo: [NSLocalizedDescriptionKey: "No CPU backend available for \(cfg.label)."])
            }

            if available["srbminer"] == true, cfg.srbGpuAlgo != nil {
                return .srbminer
            }
            if available["xmrig"] == true, cfg.xmrigAlgo != nil {
                return .xmrig
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
            "srbminer": fileManager.fileExists(atPath: paths["srbminer"] ?? "") && fileManager.isExecutableFile(atPath: paths["srbminer"] ?? ""),
        ]
    }

    private func refreshMinerAvailabilityText() {
        let available = minerAvailable()
        if available["srbminer"] == true {
            minerText = "xmrig: \(available["xmrig"] == true ? "ready" : "missing") | custom srbminer: ready"
        } else if isAppleSilicon() {
            minerText = "xmrig: \(available["xmrig"] == true ? "ready" : "missing") | apple-silicon mode: CPU/XMRig only"
        } else {
            minerText = "xmrig: \(available["xmrig"] == true ? "ready" : "missing") | srbminer: not installed"
        }
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
            "srbminer": effectiveMinerPath(target: .srbminer).path,
        ]
    }

    private func effectiveMinerPath(target: InstallTarget) -> URL {
        let envName = target == .xmrig ? "XMRIG_PATH" : "SRBMINER_PATH"
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

    // Runtime resources are copied into Application Support so the bundled app
    // can update installer scripts or miner binaries without modifying the app
    // bundle itself. That keeps the bundle read-only and user updates mutable.
    private func bootstrapRuntime() {
        do {
            try fileManager.createDirectory(at: appSupportURL, withIntermediateDirectories: true)
            try fileManager.createDirectory(at: runtimeURL, withIntermediateDirectories: true)
        } catch {
            warningText = "Failed creating app support directories: \(error.localizedDescription)"
            return
        }

        guard let bundleRuntime = Bundle.main.resourceURL?.appendingPathComponent("runtime", isDirectory: true) else {
            warningText = "Missing bundled runtime resources."
            return
        }

        syncRuntimeFolder(named: "scripts", from: bundleRuntime)
        syncRuntimeFolder(named: "miners", from: bundleRuntime)
        ensureExecutableBit(at: runtimeURL.appendingPathComponent("scripts/install_xmrig.sh").path)
        ensureExecutableBit(at: runtimeURL.appendingPathComponent("miners/xmrig/xmrig").path)
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

        configMinerPaths = minerPaths
        xmrigPathOverride = minerPaths["xmrig"] ?? ""
        srbminerPathOverride = minerPaths["srbminer"] ?? ""
    }

    private func saveConfig() {
        xmrigPathOverride = configMinerPaths["xmrig"] ?? ""
        srbminerPathOverride = configMinerPaths["srbminer"] ?? ""

        let payload: [String: Any] = ["miner_paths": configMinerPaths]
        do {
            let data = try JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys])
            try data.write(to: configURL, options: [.atomic])
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

    private func makeExecutable(path: String) throws {
        let attrs = try fileManager.attributesOfItem(atPath: path)
        let current = (attrs[.posixPermissions] as? NSNumber)?.intValue ?? 0o644
        let updated = current | 0o111
        try fileManager.setAttributes([.posixPermissions: NSNumber(value: updated)], ofItemAtPath: path)
    }

    private func fetchCoins() {
        guard let url = URL(string: "https://api.unminable.com/v5/coin") else { return }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self, let data else { return }
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
                Picker("Palette", selection: $paletteRaw) {
                    ForEach(AccentPalette.allCases) { option in
                        Text(option.displayName).tag(option.rawValue)
                    }
                }
                Text("Current: \(appearanceMode.displayName) / \(palette.displayName)")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Toggle("Auto-install XMRig if missing", isOn: $autoInstallXMRig)
            Toggle("Validate binaries on launch", isOn: $autoValidateOnLaunch)
            Text("SRBMiner macOS binaries may be unavailable in official releases.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

            Section("Project") {
                Text("License: MIT")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                Button("Buy Me a Coffee") {
                    openExternalURL(supportURLString)
                }
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
            Button("Settings...") {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                NSApp.activate(ignoringOtherApps: true)
            }
            Divider()
            Toggle("Auto-install XMRig", isOn: $autoInstallXMRig)
            Toggle("Validate on launch", isOn: $autoValidateOnLaunch)
            Divider()
            Button("Buy Me a Coffee") {
                openExternalURL(supportURLString)
            }
            Button("Quit") {
                NSApp.terminate(nil)
            }
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
                    Text("Checked against official upstream releases on March 12, 2026.")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 12))
                    Text("XMRig: macOS arm64 release available")
                    Text("SRBMiner-MULTI: no normal macOS release asset")
                    Text("nanominer: latest release is Linux/Windows only")
                    Text("BzMiner: latest release is Linux/Windows only")
                    Text("OneZeroMiner: generic tarball is Linux ELF x86-64, not macOS")
                }

                Section("Bundled Binaries") {
                    Text("XMRig bundled: \(bundled.xmrig ? "Yes" : "No")")
                    Text("Custom SRBMiner present: \(model.hasUsableSRBMinerBinary ? "Yes" : "No")")
                }

                Section("Installers") {
                    HStack(spacing: 10) {
                        Button("Install / Update XMRig") {
                            model.install(target: .xmrig, dryRun: false)
                        }
                        .buttonStyle(.bordered)
                        .disabled(model.isInstalling || model.isMining)

                        Button("Check XMRig Release") {
                            model.install(target: .xmrig, dryRun: true)
                        }
                        .buttonStyle(.bordered)
                        .disabled(model.isInstalling || model.isMining)
                    }
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
                }

                Section("Validation") {
                    Button("Validate Binaries") {
                        model.validateMiners()
                    }
                    .buttonStyle(.bordered)
                    .disabled(model.isInstalling)

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
                Button("Save", action: onSave)
                    .buttonStyle(.bordered)
                Button("Clear", action: onClear)
                    .buttonStyle(.bordered)
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
                        .onChange(of: model.backend) { _, _ in
                            model.handleBackendChange()
                        }
                    }
                }

                Section("Worker") {
                    TextField("Worker (optional)", text: $model.workerName)
                        .onChange(of: model.workerName) { _, _ in
                            model.handleSimpleFormChange()
                        }
                    TextField("Referral (optional)", text: $model.referralCode)
                        .onChange(of: model.referralCode) { _, _ in
                            model.handleSimpleFormChange()
                        }
                }

                Section("CPU") {
                    Text("CPU Usage: \(Int(model.threadsPercent))%")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 12))
                    Slider(value: $model.threadsPercent, in: 1 ... 100, step: 1)
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
                    Button("Buy Me a Coffee") {
                        openExternalURL(supportURLString)
                    }
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
                    IconChromeButton(systemName: "paintpalette.fill", theme: theme) {
                        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                        NSApp.activate(ignoringOtherApps: true)
                    }
                    IconChromeButton(systemName: "folder.fill", theme: theme) {
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
                        SessionLine(label: "Address", value: model.displayWallet(), theme: theme)
                        SessionLine(label: "Coin", value: model.coinSymbol, theme: theme)
                        SessionLine(label: "Algorithm", value: model.selectedAlgorithm?.label ?? "-", theme: theme)
                        SessionLine(label: "Device", value: model.hardware.displayName, theme: theme)
                        SessionLine(label: "Backend", value: model.displayedBackendName, theme: theme)
                        SessionLine(label: "Worker", value: model.displayWorker(), theme: theme)
                        SessionLine(label: "Port", value: String(model.selectedPort), theme: theme)
                        SessionLine(label: "Pool", value: model.selectedPoolHost, theme: theme)
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
                                IconChromeButton(systemName: "globe", theme: theme) {
                                    activePanel = .info
                                }
                                IconChromeButton(systemName: "doc.text", theme: theme) {
                                    activePanel = .logs
                                }
                                IconChromeButton(systemName: "gearshape", theme: theme) {
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
