import AppKit
import Foundation
import Network
import SwiftUI

// This file contains the entire native macOS app. The project intentionally
// stays dependency-light, so the model, theme system, runtime management, and
// SwiftUI views all live in one file and are separated with MARK sections.

// MARK: - Domain Models

/// Represents a cryptocurrency coin available for payout on unMineable.
struct CoinOption: Identifiable, Hashable, Codable {
    let symbol: String
    let name: String

    var id: String { symbol }

    var displayLabel: String {
        "\(symbol) - \(name)"
    }
}

/// Defines the configuration for a mining algorithm.
/// This includes the unMineable pool endpoint (host/ports) and the specific
/// flags required by backend miners (XMRig or cpuminer-scash).
struct AlgorithmConfig: Identifiable, Hashable {
    let id: String
    let label: String
    let host: String
    let ports: [Int]
    let xmrigAlgo: String?
    let cpuminerAlgo: String?
}

/// Root response for unMineable's address lookup API.
/// This is the first step in fetching wallet stats: resolving a public address to an internal account UUID.
struct UnmineableAddressLookupResponse: Decodable {
    let data: UnmineableAddressLookupData
}

struct LossyString: Decodable {
    let value: String

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            value = string
        } else if let int = try? container.decode(Int.self) {
            value = String(int)
        } else if let double = try? container.decode(Double.self) {
            value = String(double)
        } else {
            value = ""
        }
    }
}

struct UnmineableAddressLookupData: Decodable {
    let uuid: String?
    let address: String?
    let network: String?
    let paymentThreshold: String?
    let balance: String?
    let balancePayable: String?
    let miningFee: String?
    let fresh: Bool?
    let inactive: Bool?
    let enabled: Bool?
    let enabledAutoOnly: Bool?

    enum CodingKeys: String, CodingKey {
        case uuid
        case address
        case network
        case paymentThreshold = "payment_threshold"
        case balance
        case balancePayable = "balance_payable"
        case miningFee = "mining_fee"
        case fresh
        case inactive
        case enabled
        case enabledAutoOnly = "enabled_auto_only"
    }
}

struct UnmineableAccountStatsResponse: Decodable {
    let data: UnmineableAccountStatsData
}

struct UnmineableAccountStatsData: Decodable {
    let balanceMining: String?
    let balanceReferral: String?
    let balance: String?
    let paid: String?
    let lastPayment: LossyString?
    let paymentThreshold: String?
    let miningFee: String?
    let coin: String?
    let network: String?

    enum CodingKeys: String, CodingKey {
        case balanceMining = "balance_mining"
        case balanceReferral = "balance_referral"
        case balance
        case paid
        case lastPayment = "last_payment"
        case paymentThreshold = "payment_threshold"
        case miningFee = "mining_fee"
        case coin
        case network
    }
}

struct UnmineableAccountSummaryResponse: Decodable {
    let data: UnmineableAccountSummaryData
}

struct UnmineableAccountSummaryData: Decodable {
    let timestamp: Double?
    let raw: UnmineableAccountSummaryRaw?
}

struct UnmineableAccountSummaryRaw: Decodable {
    let workerCount: Int?
    let algorithmCount: Int?
    let hr: [String: String]?

    enum CodingKeys: String, CodingKey {
        case workerCount = "worker_count"
        case algorithmCount = "algorithm_count"
        case hr
    }
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

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .auto: return "Auto"
        case .xmrig: return "XMRig"
        case .cpuminerScash: return "cpuminer-scash"
        }
    }
}

enum InstallTarget: String, CaseIterable {
    case xmrig
    case cpuminerScash = "cpuminer_scash"

    var displayName: String {
        switch self {
        case .xmrig: return "XMRig"
        case .cpuminerScash: return "cpuminer-scash"
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

/// Centralized theme definition for the mining dashboard.
/// It manages palette-dependent colors for background, cards, fields, and accents,
/// ensuring a consistent look across light and dark modes.
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
    .init(id: "rx", label: "RandomX", host: "rx.unmineable.com", ports: [3333, 13333, 4445], xmrigAlgo: "rx", cpuminerAlgo: "randomx"),
    .init(id: "ghostrider", label: "GhostRider", host: "ghostrider.unmineable.com", ports: [3333, 13333], xmrigAlgo: "gr", cpuminerAlgo: nil),
    .init(id: "kp", label: "KawPow", host: "kp.unmineable.com", ports: [3333, 13333], xmrigAlgo: "kawpow", cpuminerAlgo: nil),
]

private let prefAutoInstallXMRigKey = "macunmineable.pref.autoInstallXmrig"
private let prefAutoValidateOnLaunchKey = "macunmineable.pref.autoValidateOnLaunch"
private let prefAppearanceModeKey = "macunmineable.pref.appearanceMode"
private let prefPaletteKey = "macunmineable.pref.palette"
private let coinCatalogCacheKey = "macunmineable.coinCatalogCache.v1"
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

/// The primary view model for the native macOS application.
/// It manages the state of the mining process, handles network requests for coin catalogs
/// and wallet stats, and coordinates the execution of miner binaries.
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
    @Published var coinCatalogStatusText: String = "Using bundled fallback catalog (8 coins)."
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
    @Published var cpuminerPathOverride: String = ""
    // Wallet/account stats mirror the public unMineable stats pages. These
    // values are wallet-level aggregates, so they can include work submitted
    // by this app and by any other miners pointed at the same address.
    @Published var walletStatsStatusText: String = "Enter a wallet address to load unMineable stats."
    @Published var walletResolvedNetworkText: String = "-"
    @Published var walletBalanceText: String = "--"
    @Published var walletThresholdText: String = "--"
    @Published var walletPaidText: String = "--"
    @Published var walletLastPaymentText: String = "No payouts yet"
    @Published var walletAggregateHashrateText: String = "--"
    @Published var walletWorkerCountText: String = "--"
    @Published var walletAlgorithmCountText: String = "--"
    @Published var walletStatsTimestampText: String = ""
    @Published var isRefreshingWalletStats: Bool = false
    @Published var isMining: Bool = false
    @Published var isInstalling: Bool = false
    @Published var isTestingConnection: Bool = false

    private var minerProcess: Process?
    private var installProcess: Process?
    private var minerBackend: BackendChoice = .auto
    private var configMinerPaths: [String: String] = [:]
    private var walletStatsRefreshTimer: Timer?
    private var pendingWalletStatsRefresh: DispatchWorkItem?

    private let fileManager = FileManager.default
    private let appSupportURL: URL
    private let runtimeURL: URL
    private let configURL: URL
    private let defaults = UserDefaults.standard
    private var networkMonitor: NWPathMonitor?
    private let networkMonitorQueue = DispatchQueue(label: "macunmineable.network-monitor")

    private let formDefaultsKey = "macunmineable.native.form.v1"

    /// Initializes the model, bootstraps the local runtime environment, and restores previous session state.
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

        loadCachedCoins()
        bootstrapRuntime()
        loadConfig()
        loadFormState()
        normalizeSelections(showWarning: false)
        refreshSelection()
        refreshMinerAvailabilityText()
        fetchCoins()
        scheduleWalletStatsRefresh(immediate: true)
        startNetworkMonitor()
        if defaults.bool(forKey: prefAutoInstallXMRigKey) {
            ensureManagedMinersInstalledIfNeeded()
        } else if defaults.bool(forKey: prefAutoValidateOnLaunchKey) {
            validateMiners()
        }
    }

    deinit {
        networkMonitor?.cancel()
        walletStatsRefreshTimer?.invalidate()
        pendingWalletStatsRefresh?.cancel()
    }

    // The visible algorithm list is intentionally constrained by the current
    // backend/hardware selection so the UI never offers combinations that the
    // runtime cannot actually execute on this Mac.
    var filteredAlgorithms: [AlgorithmConfig] {
        let xmrigReady = hasUsableXMRigBinary
        let cpuminerReady = hasUsableCPUMinerScashBinary
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
        case .auto:
            guard hardware != .gpu else { return [] }
            return algorithms.filter {
                (xmrigReady && $0.xmrigAlgo != nil)
                    || (cpuminerReady && $0.cpuminerAlgo != nil)
            }
        }
    }

    var hasUsableXMRigBinary: Bool {
        hasUsableBinary(target: .xmrig)
    }

    var hasUsableCPUMinerScashBinary: Bool {
        hasUsableBinary(target: .cpuminerScash)
    }

    var availableBackends: [BackendChoice] {
        let ready: [BackendChoice] = [
            hasUsableXMRigBinary ? .xmrig : nil,
            hasUsableCPUMinerScashBinary ? .cpuminerScash : nil,
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
        if backends.isEmpty {
            return "Apple Silicon mode: install the managed backends from Setup to enable XMRig and cpuminer-scash. This launcher only advertises backends that it can bundle, verify, and update safely on macOS."
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

    var selectedCoin: CoinOption? {
        coins.first(where: { $0.symbol == coinSymbol })
            ?? fallbackCoins.first(where: { $0.symbol == coinSymbol })
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
        scheduleWalletStatsRefresh()
    }

    func selectCoin(_ coin: CoinOption) {
        coinSymbol = coin.symbol
        handleSimpleFormChange()
    }

    func refreshCoinCatalog() {
        fetchCoins(userInitiated: true)
    }

    func refreshWalletStatsNow() {
        scheduleWalletStatsRefresh(immediate: true)
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

    // Wallet lookups are debounced so typing in the address field does not
    // hammer the public API on every keystroke, while still allowing explicit
    // refreshes and periodic polling once a wallet is active.
    private func scheduleWalletStatsRefresh(immediate: Bool = false) {
        pendingWalletStatsRefresh?.cancel()
        let wallet = walletAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        let coin = sanitizeCoin(coinSymbol)
        guard !wallet.isEmpty, !coin.isEmpty else {
            walletStatsRefreshTimer?.invalidate()
            resetWalletStats(status: "Enter a wallet address to load unMineable stats.")
            return
        }

        let work = DispatchWorkItem { [weak self] in
            self?.refreshWalletStats(for: wallet, coin: coin)
        }
        pendingWalletStatsRefresh = work
        DispatchQueue.main.asyncAfter(deadline: .now() + (immediate ? 0 : 0.6), execute: work)
    }

    // The wallet stats flow matches the official site: resolve an address to
    // an account UUID first, then query the account-level stats and summary
    // endpoints for balances, payout history, workers, and aggregate hashrate.
    private func refreshWalletStats(for wallet: String, coin: String) {
        guard matchesCurrentWalletSelection(wallet: wallet, coin: coin) else { return }
        guard let lookupURL = walletLookupURL(wallet: wallet, coin: coin) else {
            resetWalletStats(status: "Could not build the wallet stats request.")
            return
        }

        isRefreshingWalletStats = true
        walletStatsStatusText = "Refreshing wallet stats..."

        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 10
        configuration.timeoutIntervalForResource = 20
        let session = URLSession(configuration: configuration)

        session.dataTask(with: lookupURL) { [weak self] data, response, error in
            guard let self else { return }

            guard error == nil, let data, let http = response as? HTTPURLResponse, (200 ..< 300).contains(http.statusCode) else {
                Task { @MainActor in
                    guard self.matchesCurrentWalletSelection(wallet: wallet, coin: coin) else { return }
                    self.isRefreshingWalletStats = false
                    self.walletStatsStatusText = "Could not load wallet stats from unMineable."
                }
                return
            }

            let decoder = JSONDecoder()
            guard let lookup = try? decoder.decode(UnmineableAddressLookupResponse.self, from: data) else {
                Task { @MainActor in
                    guard self.matchesCurrentWalletSelection(wallet: wallet, coin: coin) else { return }
                    self.isRefreshingWalletStats = false
                    self.walletStatsStatusText = "Wallet stats response could not be parsed."
                }
                return
            }

            let uuid = (lookup.data.uuid ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !uuid.isEmpty else {
                Task { @MainActor in
                    guard self.matchesCurrentWalletSelection(wallet: wallet, coin: coin) else { return }
                    self.isRefreshingWalletStats = false
                    self.walletStatsStatusText = "unMineable did not return a wallet stats record for this address yet."
                    self.walletResolvedNetworkText = lookup.data.network ?? "-"
                    self.walletBalanceText = lookup.data.balance ?? "--"
                    self.walletThresholdText = lookup.data.paymentThreshold ?? "--"
                    self.walletPaidText = "--"
                    self.walletLastPaymentText = "No payouts yet"
                    self.walletAggregateHashrateText = "--"
                    self.walletWorkerCountText = "--"
                    self.walletAlgorithmCountText = "--"
                    self.walletStatsTimestampText = ""
                }
                return
            }

            guard let statsURL = URL(string: "https://api.unmineable.com/v5/account/\(uuid)/stats"),
                  let summaryURL = URL(string: "https://api.unmineable.com/v5/account/\(uuid)/summary")
            else {
                Task { @MainActor in
                    guard self.matchesCurrentWalletSelection(wallet: wallet, coin: coin) else { return }
                    self.isRefreshingWalletStats = false
                    self.walletStatsStatusText = "Could not build the detailed wallet stats requests."
                }
                return
            }

            let group = DispatchGroup()
            var decodedStats: UnmineableAccountStatsResponse?
            var decodedSummary: UnmineableAccountSummaryResponse?

            group.enter()
            session.dataTask(with: statsURL) { data, response, _ in
                defer { group.leave() }
                guard let data, let http = response as? HTTPURLResponse, (200 ..< 300).contains(http.statusCode) else { return }
                decodedStats = try? decoder.decode(UnmineableAccountStatsResponse.self, from: data)
            }.resume()

            group.enter()
            session.dataTask(with: summaryURL) { data, response, _ in
                defer { group.leave() }
                guard let data, let http = response as? HTTPURLResponse, (200 ..< 300).contains(http.statusCode) else { return }
                decodedSummary = try? decoder.decode(UnmineableAccountSummaryResponse.self, from: data)
            }.resume()

            group.notify(queue: .main) {
                Task { @MainActor in
                    guard self.matchesCurrentWalletSelection(wallet: wallet, coin: coin) else { return }

                    let stats = decodedStats?.data
                    let summary = decodedSummary?.data
                    self.walletResolvedNetworkText = lookup.data.network ?? stats?.network ?? "-"
                    self.walletBalanceText = stats?.balance ?? lookup.data.balance ?? "--"
                    self.walletThresholdText = stats?.paymentThreshold ?? lookup.data.paymentThreshold ?? "--"
                    self.walletPaidText = stats?.paid ?? "0"
                    self.walletLastPaymentText = self.formatLastPayment(stats?.lastPayment)
                    self.walletAggregateHashrateText = self.formatAggregateHashrate(summary?.raw)
                    self.walletWorkerCountText = self.formatCount(summary?.raw?.workerCount)
                    self.walletAlgorithmCountText = self.formatCount(summary?.raw?.algorithmCount)
                    self.walletStatsTimestampText = self.formatWalletStatsTimestamp(summary?.timestamp)
                    self.walletStatsStatusText = self.makeWalletStatsStatus(
                        stats: stats,
                        summary: summary,
                        wallet: wallet,
                        coin: coin
                    )
                    self.isRefreshingWalletStats = false
                    self.restartWalletStatsTimer()
                }
            }
        }.resume()
    }

    private func restartWalletStatsTimer() {
        walletStatsRefreshTimer?.invalidate()
        walletStatsRefreshTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.scheduleWalletStatsRefresh(immediate: true)
            }
        }
    }

    private func resetWalletStats(status: String) {
        walletStatsStatusText = status
        walletResolvedNetworkText = "-"
        walletBalanceText = "--"
        walletThresholdText = "--"
        walletPaidText = "--"
        walletLastPaymentText = "No payouts yet"
        walletAggregateHashrateText = "--"
        walletWorkerCountText = "--"
        walletAlgorithmCountText = "--"
        walletStatsTimestampText = ""
        isRefreshingWalletStats = false
    }

    private func matchesCurrentWalletSelection(wallet: String, coin: String) -> Bool {
        walletAddress.trimmingCharacters(in: .whitespacesAndNewlines) == wallet && sanitizeCoin(coinSymbol) == coin
    }

    private func walletLookupURL(wallet: String, coin: String) -> URL? {
        let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
        guard let encodedWallet = wallet.addingPercentEncoding(withAllowedCharacters: allowed) else {
            return nil
        }
        var components = URLComponents(string: "https://api.unmineable.com/v5/address/\(encodedWallet)")
        components?.queryItems = [URLQueryItem(name: "coin", value: coin)]
        return components?.url
    }

    private func makeWalletStatsStatus(
        stats: UnmineableAccountStatsData?,
        summary: UnmineableAccountSummaryData?,
        wallet: String,
        coin: String
    ) -> String {
        var details: [String] = []
        if let count = summary?.raw?.workerCount {
            details.append("\(count) active worker\(count == 1 ? "" : "s")")
        }
        if let algorithmCount = summary?.raw?.algorithmCount {
            details.append("\(algorithmCount) active algorithm\(algorithmCount == 1 ? "" : "s")")
        }
        if let balance = stats?.balance, !balance.isEmpty {
            details.append("balance \(balance) \(coin)")
        }
        if details.isEmpty {
            return "Wallet stats loaded for \(displayWalletValue(wallet))."
        }
        return "Wallet stats loaded for \(displayWalletValue(wallet)) on \(stats?.network ?? coin): \(details.joined(separator: " | "))."
    }

    private func displayWalletValue(_ wallet: String) -> String {
        if wallet.count <= 24 {
            return wallet
        }
        return "\(wallet.prefix(10))...\(wallet.suffix(10))"
    }

    private func formatAggregateHashrate(_ raw: UnmineableAccountSummaryRaw?) -> String {
        guard let entries = raw?.hr, !entries.isEmpty else {
            return "--"
        }
        return entries
            .sorted { $0.key < $1.key }
            .map { "\(formatAlgorithmDisplayName($0.key)) \($0.value)" }
            .joined(separator: " | ")
    }

    private func formatAlgorithmDisplayName(_ raw: String) -> String {
        switch raw.lowercased() {
        case "ghostrider": return "GhostRider"
        case "randomx": return "RandomX"
        case "kawpow": return "KawPow"
        case "autolykos": return "Autolykos"
        case "etchash": return "Etchash"
        case "ethash": return "Ethash"
        default:
            return raw
                .split(separator: "_")
                .map { $0.prefix(1).uppercased() + $0.dropFirst() }
                .joined(separator: " ")
        }
    }

    private func formatCount(_ value: Int?) -> String {
        guard let value else { return "--" }
        return String(value)
    }

    private func formatWalletStatsTimestamp(_ milliseconds: Double?) -> String {
        guard let milliseconds else { return "" }
        let date = Date(timeIntervalSince1970: milliseconds / 1000.0)
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return "Updated \(formatter.string(from: date))"
    }

    private func formatLastPayment(_ raw: LossyString?) -> String {
        guard let value = raw?.value.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
            return "No payouts yet"
        }
        if let numeric = Double(value) {
            let seconds = numeric > 1_000_000_000_000 ? numeric / 1000.0 : numeric
            let date = Date(timeIntervalSince1970: seconds)
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
        return value
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

    /// Starts the mining process using the currently selected options.
    /// It validates the input, selects the appropriate backend binary, and launches the process.
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
            saveFormState()
        } catch {
            pipe.fileHandleForReading.readabilityHandler = nil
            warningText = "Failed to start miner: \(error.localizedDescription)"
            appendMinerLog("[system] Failed to start miner: \(error.localizedDescription)")
        }
    }

    /// Terminates the active miner process.
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

    /// Executes the installer script for a specific miner backend.
    /// - Parameters:
    ///   - target: The miner backend to install/update.
    ///   - dryRun: If true, only checks for updates without installing.
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
        case .cpuminerScash:
            rawInput = cpuminerPathOverride
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
        case .cpuminerScash:
            cpuminerPathOverride = ""
        }
        saveConfig()
        refreshMinerAvailabilityText()
        validateMiners()
    }

    /// Performs a read-only validation pass on all configured miner binaries.
    /// It checks for file existence, executability, architecture, and version output.
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

                    let version = Self.runCapture(executable: path, arguments: ["--version"])
                    if let first = Self.firstLine(version.output), !first.isEmpty {
                        lines.append("  version: \(first)")
                        ok = true
                    } else if version.code == 0 {
                        lines.append("  warning: version output was empty.")
                    } else {
                        lines.append("  warning: version check exit code \(version.code).")
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
        case .auto:
            if hardware == .gpu {
                throw NSError(domain: "macunmineable", code: 7, userInfo: [NSLocalizedDescriptionKey: "No GPU backend available for \(cfg.label)."])
            }
            if hardware == .cpu {
                if available["xmrig"] == true, cfg.xmrigAlgo != nil {
                    return .xmrig
                }
                if available["cpuminer_scash"] == true, cfg.cpuminerAlgo != nil {
                    return .cpuminerScash
                }
                throw NSError(domain: "macunmineable", code: 8, userInfo: [NSLocalizedDescriptionKey: "No CPU backend available for \(cfg.label)."])
            }

            if available["xmrig"] == true, cfg.xmrigAlgo != nil {
                return .xmrig
            }
            if available["cpuminer_scash"] == true, cfg.cpuminerAlgo != nil {
                return .cpuminerScash
            }
            throw NSError(domain: "macunmineable", code: 9, userInfo: [NSLocalizedDescriptionKey: "No backend available for \(cfg.label)."])
        }
    }

    private func minerAvailable() -> [String: Bool] {
        let paths = effectiveMinerPaths()
        return [
            "xmrig": fileManager.fileExists(atPath: paths["xmrig"] ?? "") && fileManager.isExecutableFile(atPath: paths["xmrig"] ?? ""),
            "cpuminer_scash": fileManager.fileExists(atPath: paths["cpuminer_scash"] ?? "") && fileManager.isExecutableFile(atPath: paths["cpuminer_scash"] ?? ""),
        ]
    }

    private func refreshMinerAvailabilityText() {
        let available = minerAvailable()
        let parts = [
            "xmrig: \(available["xmrig"] == true ? "ready" : "missing")",
            "cpuminer-scash: \(available["cpuminer_scash"] == true ? "ready" : "missing")",
        ]
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
            cpuminerPathOverride = ""
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
        cpuminerPathOverride = configMinerPaths["cpuminer_scash"] ?? ""
    }

    private func saveConfig() {
        xmrigPathOverride = configMinerPaths["xmrig"] ?? ""
        cpuminerPathOverride = configMinerPaths["cpuminer_scash"] ?? ""

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

    private func loadCachedCoins() {
        guard let data = defaults.data(forKey: coinCatalogCacheKey),
              let cached = try? JSONDecoder().decode([CoinOption].self, from: data)
        else {
            coinCatalogStatusText = "Using bundled fallback catalog (\(fallbackCoins.count) coins)."
            return
        }

        let normalized = Self.normalizeCoinCatalog(cached)
        guard !normalized.isEmpty else {
            coinCatalogStatusText = "Using bundled fallback catalog (\(fallbackCoins.count) coins)."
            return
        }

        coins = normalized
        coinCatalogStatusText = "Loaded cached coin catalog (\(normalized.count) coins)."
    }

    private func saveCoinCache(_ mapped: [CoinOption]) {
        guard let data = try? JSONEncoder().encode(mapped) else { return }
        defaults.set(data, forKey: coinCatalogCacheKey)
    }

    nonisolated private static func normalizeCoinCatalog(_ rawCoins: [CoinOption]) -> [CoinOption] {
        rawCoins
            .reduce(into: [String: CoinOption]()) { out, coin in
                let symbol = coin.symbol.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
                let name = coin.name.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !symbol.isEmpty else { return }
                out[symbol] = CoinOption(symbol: symbol, name: name.isEmpty ? symbol : name)
            }
            .values
            .sorted { $0.symbol < $1.symbol }
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

    /// Fetches the live coin catalog from the unMineable API.
    /// - Parameter userInitiated: If true, updates the status text to reflect a manual refresh.
    private func fetchCoins(userInitiated: Bool = false) {
        // Coin discovery is best-effort only. The launcher keeps a safe fallback
        // list locally and replaces it only when the unMineable API returns a
        // bounded successful response.
        if userInitiated {
            coinCatalogStatusText = "Refreshing coin catalog..."
        }
        guard let url = URL(string: "https://api.unmineable.com/v5/coin") else { return }
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 10
        configuration.timeoutIntervalForResource = 20
        URLSession(configuration: configuration).dataTask(with: url) { [weak self] data, response, _ in
            guard let self, let data else {
                if userInitiated {
                    Task { @MainActor in
                        self?.coinCatalogStatusText = "Could not refresh coin catalog. Keeping local catalog (\(self?.coins.count ?? fallbackCoins.count) coins)."
                    }
                }
                return
            }
            guard let httpResponse = response as? HTTPURLResponse, (200 ..< 300).contains(httpResponse.statusCode) else {
                if userInitiated {
                    Task { @MainActor in
                        self.coinCatalogStatusText = "Coin catalog request failed. Keeping local catalog (\(self.coins.count) coins)."
                    }
                }
                return
            }
            guard data.count <= 1_000_000 else {
                if userInitiated {
                    Task { @MainActor in
                        self.coinCatalogStatusText = "Coin catalog response was unexpectedly large. Keeping local catalog (\(self.coins.count) coins)."
                    }
                }
                return
            }
            guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let rawCoins = object["data"] as? [[String: Any]]
            else {
                if userInitiated {
                    Task { @MainActor in
                        self.coinCatalogStatusText = "Coin catalog response could not be parsed. Keeping local catalog (\(self.coins.count) coins)."
                    }
                }
                return
            }

            let mapped: [CoinOption] = Self.normalizeCoinCatalog(rawCoins.compactMap { row in
                guard let symbol = row["symbol"] as? String, !symbol.isEmpty else { return nil }
                let name = (row["name"] as? String) ?? symbol
                return CoinOption(symbol: symbol, name: name)
            })

            guard !mapped.isEmpty else { return }
            Task { @MainActor in
                self.coins = mapped
                self.saveCoinCache(mapped)
                self.coinCatalogStatusText = "Loaded \(mapped.count) coins from unMineable."
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
    @State private var isAnimating = false

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
            .opacity(running && isAnimating ? 0.6 : 1.0)
            .onAppear {
                if running {
                    withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                        isAnimating = true
                    }
                }
            }
            .onChange(of: running) { _, newValue in
                if newValue {
                    withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                        isAnimating = true
                    }
                } else {
                    isAnimating = false
                }
            }
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
            Text("Managed Apple Silicon installers currently cover XMRig and cpuminer-scash only. The launcher hides unsupported macOS miner backends instead of presenting dead paths.")
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
    case coinPicker
    case setup
    case advanced
    case logs
    case info

    var id: String { rawValue }
}

enum SetupTab: String, CaseIterable, Identifiable {
    case overview
    case miners
    case paths
    case validation
    case installer

    var id: String { rawValue }

    var title: String {
        switch self {
        case .overview: return "Overview"
        case .miners: return "Miners"
        case .paths: return "Paths"
        case .validation: return "Validation"
        case .installer: return "Installer"
        }
    }

    var helpText: String {
        switch self {
        case .overview: return "Show runtime status, official miner support, and detected binaries."
        case .miners: return "Show managed miner install and update actions."
        case .paths: return "Show custom miner path overrides and related guidance."
        case .validation: return "Show binary validation tools and validation output."
        case .installer: return "Show installer task output."
        }
    }
}

enum MainDashboardTab: String, CaseIterable, Identifiable {
    case mine
    case wallet

    var id: String { rawValue }

    var title: String {
        switch self {
        case .mine: return "Mine"
        case .wallet: return "Wallet"
        }
    }

    var systemImage: String {
        switch self {
        case .mine: return "bolt.fill"
        case .wallet: return "chart.bar.fill"
        }
    }

    var helpText: String {
        switch self {
        case .mine:
            return "Show the mining form, hashrate, and session controls."
        case .wallet:
            return "Show wallet balance, payout threshold, and aggregate wallet stats from unMineable."
        }
    }
}

struct DashboardCard<Content: View>: View {
    let padding: CGFloat
    let theme: DashboardTheme
    let content: Content

    init(padding: CGFloat = 20, theme: DashboardTheme, @ViewBuilder content: () -> Content) {
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
        .shadow(color: theme.shadow, radius: 24, x: 0, y: 12)
    }
}

struct ChromeIconGlyph: View {
    let systemName: String
    let theme: DashboardTheme

    var body: some View {
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
}

struct IconChromeButton: View {
    let systemName: String
    let theme: DashboardTheme
    let helpText: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ChromeIconGlyph(systemName: systemName, theme: theme)
        }
        .buttonStyle(.plain)
        .help(helpText)
    }
}

struct ThemeChromeMenu: View {
    let theme: DashboardTheme
    @AppStorage(prefAppearanceModeKey) private var appearanceModeRaw = AppearanceMode.system.rawValue
    @AppStorage(prefPaletteKey) private var paletteRaw = AccentPalette.mint.rawValue

    var body: some View {
        Menu {
            Section("Appearance") {
                ForEach(AppearanceMode.allCases) { mode in
                    Button(mode.rawValue == appearanceModeRaw ? "✓ \(mode.displayName)" : mode.displayName) {
                        appearanceModeRaw = mode.rawValue
                    }
                }
            }

            Section("Palette") {
                ForEach(AccentPalette.allCases) { option in
                    Button(option.rawValue == paletteRaw ? "✓ \(option.displayName)" : option.displayName) {
                        paletteRaw = option.rawValue
                    }
                }
            }

            Divider()

            Button("Open Appearance Settings…") {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                NSApp.activate(ignoringOtherApps: true)
            }
        } label: {
            ChromeIconGlyph(systemName: "paintpalette.fill", theme: theme)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .help("Change the appearance mode or accent palette.")
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
    var copyValue: String? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(label)
                .foregroundStyle(theme.tertiaryText)
            Text(value)
                .foregroundStyle(theme.primaryText)
                .fontWeight(.semibold)
                .lineLimit(1)

            if let copyValue = copyValue, !copyValue.isEmpty {
                Button(action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(copyValue, forType: .string)
                }) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 11))
                        .foregroundStyle(theme.accentStart)
                }
                .buttonStyle(.plain)
                .help("Copy to clipboard")
            }

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
    var detail: String? = nil
    let theme: DashboardTheme

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(text)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(theme.primaryText)
                    .lineLimit(1)
                if let detail, !detail.isEmpty {
                    Text(detail)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(theme.tertiaryText)
                        .lineLimit(1)
                }
            }
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
                .contentTransition(.numericText())
                .animation(.spring(), value: value)
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

struct WrappedNote: View {
    let text: String

    var body: some View {
        Text(text)
            .foregroundStyle(.secondary)
            .font(.system(size: 12))
            .fixedSize(horizontal: false, vertical: true)
            .textSelection(.enabled)
    }
}

struct ReadOnlyLogPanel: View {
    let text: String

    var body: some View {
        ScrollView([.vertical, .horizontal]) {
            Text(text.isEmpty ? "No output yet." : text)
                .font(.system(.body, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
                .padding(12)
        }
        .frame(minHeight: 180)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }
}

struct SetupSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 15, weight: .bold, design: .rounded))
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.primary.opacity(0.035))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }
}

struct SetupTabButton: View {
    let tab: SetupTab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(tab.title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(isSelected ? Color.white : Color.primary.opacity(0.78))
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isSelected ? Color.accentColor : Color.primary.opacity(0.06))
                )
        }
        .buttonStyle(.plain)
        .help(tab.helpText)
    }
}

struct MainDashboardTabButton: View {
    let tab: MainDashboardTab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: tab.systemImage)
                    .font(.system(size: 12, weight: .bold))
                Text(tab.title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(isSelected ? Color.white : Color.primary.opacity(0.8))
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? Color.accentColor : Color.primary.opacity(0.06))
            )
        }
        .buttonStyle(.plain)
        .help(tab.helpText)
    }
}

struct DashboardHeaderView: View {
    @ObservedObject var model: NativeAppModel
    @Binding var selectedTab: MainDashboardTab
    @Binding var activePanel: SecondaryPanel?
    let theme: DashboardTheme

    var body: some View {
        HStack(spacing: 12) {
            Text("macUnmineable")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(theme.secondaryText)

            HStack(spacing: 8) {
                ForEach(MainDashboardTab.allCases) { tab in
                    MainDashboardTabButton(tab: tab, isSelected: selectedTab == tab) {
                        selectedTab = tab
                    }
                }
            }
            .frame(maxWidth: 320)

            Spacer()

            PillView(text: model.isOnline ? "Online" : "Offline", running: model.isOnline, theme: theme)
            ThemeChromeMenu(theme: theme)
            IconChromeButton(systemName: "line.3.horizontal.decrease.circle.fill", theme: theme, helpText: "Open setup tabs for overview, miner management, paths, validation, and installer tools.") {
                activePanel = .setup
            }
        }
    }
}

struct CoinPickerSheetView: View {
    @ObservedObject var model: NativeAppModel
    @Environment(\.dismiss) private var dismiss
    @State private var searchText: String = ""

    private var filteredCoins: [CoinOption] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return model.coins }
        return model.coins.filter { coin in
            coin.symbol.localizedCaseInsensitiveContains(trimmed)
                || coin.name.localizedCaseInsensitiveContains(trimmed)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(model.coinCatalogStatusText)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                        Text("\(filteredCoins.count) of \(model.coins.count) coins")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(.tertiary)
                    }
                    Spacer()
                    Button("Refresh Catalog") {
                        model.refreshCoinCatalog()
                    }
                    .buttonStyle(.bordered)
                    .help("Reload the payout coin catalog from unMineable.")
                }

                TextField("Search by symbol or name", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .help("Filter the payout coin catalog by symbol or coin name.")

                List(filteredCoins) { coin in
                    Button {
                        model.selectCoin(coin)
                        dismiss()
                    } label: {
                        HStack(spacing: 12) {
                            Text(coin.symbol)
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .frame(width: 72, alignment: .leading)
                            Text(coin.name)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(.primary)
                            Spacer()
                            if coin.symbol == model.coinSymbol {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .help("Select \(coin.displayLabel) as the payout coin.")
                }
                .listStyle(.inset)
            }
            .padding(16)
            .navigationTitle("Choose Coin")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .help("Close the coin picker.")
                }
            }
        }
        .frame(minWidth: 560, minHeight: 640)
    }
}

struct SetupSheetView: View {
    @ObservedObject var model: NativeAppModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: SetupTab = .overview

    var body: some View {
        let bundled = model.bundledBinaryStatus()
        NavigationStack {
            VStack(spacing: 0) {
                VStack(spacing: 12) {
                    HStack(spacing: 8) {
                        ForEach(SetupTab.allCases) { tab in
                            SetupTabButton(tab: tab, isSelected: selectedTab == tab) {
                                selectedTab = tab
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 18)
                }

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        switch selectedTab {
                        case .overview:
                            SetupSection(title: "Apple Silicon Runtime") {
                                WrappedNote(text: model.appleSiliconMiningSummary)
                                WrappedNote(text: model.coinCatalogStatusText)
                            }

                            SetupSection(title: "Official Miner Matrix") {
                                WrappedNote(text: "Checked against official upstream releases and local startup behavior on April 7, 2026.")
                                WrappedNote(text: "XMRig: official macOS arm64 release available and locally verified against unMineable RandomX, GhostRider, and KawPow pools.")
                                WrappedNote(text: "cpuminer-scash: official macOS Sonoma arm64 release available and locally verified as a native RandomX-capable Apple Silicon binary.")
                                WrappedNote(text: "nanominer: latest release is Linux/Windows only")
                                WrappedNote(text: "BzMiner: latest release is Linux/Windows only")
                                WrappedNote(text: "OneZeroMiner: generic tarball is Linux ELF x86-64, not macOS")
                            }

                            SetupSection(title: "Installed Miner Binaries") {
                                LabeledContent("XMRig installed", value: bundled[.xmrig] == true ? "Yes" : "No")
                                LabeledContent("cpuminer-scash installed", value: bundled[.cpuminerScash] == true ? "Yes" : "No")
                                WrappedNote(text: "Only the bundled managed backends are surfaced here. Unsupported external miners are kept out of the launcher to avoid false promises on Apple Silicon.")
                            }

                        case .miners:
                            SetupSection(title: "Managed Miners") {
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

                                WrappedNote(text: "Managed miner downloads are verified before install. Tarball-based miners use upstream SHA256 manifests. The app only offers installers for backends it can verify and maintain safely on Apple Silicon.")
                            }

                        case .paths:
                            SetupSection(title: "Custom Miner Paths") {
                                pathEditor(
                                    title: "XMRig Binary Path",
                                    text: $model.xmrigPathOverride,
                                    onSave: { model.savePathOverride(target: .xmrig) },
                                    onClear: { model.clearPathOverride(target: .xmrig) }
                                )
                                pathEditor(
                                    title: "cpuminer-scash Binary Path",
                                    text: $model.cpuminerPathOverride,
                                    onSave: { model.savePathOverride(target: .cpuminerScash) },
                                    onClear: { model.clearPathOverride(target: .cpuminerScash) }
                                )
                                WrappedNote(text: "Custom path overrides are intended for replacing the bundled XMRig or cpuminer-scash binaries with another compatible native macOS Mach-O build.")
                                WrappedNote(text: "Unsupported external miners are deliberately hidden from this launcher rather than exposed as unverified options.")
                            }

                        case .validation:
                            SetupSection(title: "Validation") {
                                Button("Validate Binaries") {
                                    model.validateMiners()
                                }
                                .buttonStyle(.bordered)
                                .disabled(model.isInstalling)
                                .help("Check every configured miner path for existence, executability, architecture, and version output.")

                                Text(model.validationStatusText)
                                    .foregroundStyle(.secondary)
                                    .font(.system(size: 12))
                                ReadOnlyLogPanel(text: model.validationLogs)
                            }

                        case .installer:
                            SetupSection(title: "Installer Output") {
                                Text(model.installStatusText)
                                    .foregroundStyle(.secondary)
                                    .font(.system(size: 12))
                                ReadOnlyLogPanel(text: model.installLogs)
                            }
                        }
                    }
                    .padding(18)
                }

                Divider()

                HStack {
                    Spacer()
                    Button("Close") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    .help("Close the setup window.")
                }
                .padding(16)
            }
            .navigationTitle("Setup")
        }
        .frame(minWidth: 960, minHeight: 760)
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
            TextField("/absolute/path/to/binary", text: text)
                .help("Paste an absolute path to a native macOS Mach-O miner binary.")
            HStack(spacing: 10) {
                Spacer()
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
                    Text("Wallet network: \(model.walletResolvedNetworkText)")
                    Text("Algorithm: \(model.selectedAlgorithm?.label ?? "-")")
                    Text("Backend: \(model.displayedBackendName)")
                    Text("Worker: \(model.displayWorker())")
                }

                Section("Wallet Stats") {
                    Button(model.isRefreshingWalletStats ? "Refreshing..." : "Refresh Wallet Stats") {
                        model.refreshWalletStatsNow()
                    }
                    .buttonStyle(.bordered)
                    .disabled(model.isRefreshingWalletStats || model.walletAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .help("Refresh wallet balance, payout threshold, and aggregate unMineable wallet activity.")
                    Text(model.walletStatsStatusText)
                        .foregroundStyle(.secondary)
                        .font(.system(size: 12))
                    Text("Current balance: \(model.walletBalanceText)")
                    Text("Threshold: \(model.walletThresholdText)")
                    Text("Wallet aggregate: \(model.walletAggregateHashrateText)")
                    Text("Active workers: \(model.walletWorkerCountText)")
                    Text("Active algorithms: \(model.walletAlgorithmCountText)")
                    Text("Total paid: \(model.walletPaidText)")
                    Text("Last payment: \(model.walletLastPaymentText)")
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
            VStack(spacing: 12) {
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
                    .padding(.bottom, 14)

                    VStack(alignment: .leading, spacing: 5) {
                        SessionLine(label: "Address", value: model.displayWallet(), theme: theme, helpText: model.walletAddress.isEmpty ? "Wallet address is not set." : model.walletAddress, copyValue: model.walletAddress)
                        SessionLine(label: "Coin", value: model.coinSymbol, theme: theme)
                        SessionLine(label: "Algorithm", value: model.selectedAlgorithm?.label ?? "-", theme: theme)
                        SessionLine(label: "Device", value: model.hardware.displayName, theme: theme)
                        SessionLine(label: "Backend", value: model.displayedBackendName, theme: theme)
                        SessionLine(label: "Worker", value: model.displayWorker(), theme: theme)
                        SessionLine(label: "Port", value: String(model.selectedPort), theme: theme)
                        SessionLine(label: "Pool", value: model.selectedPoolHost, theme: theme, helpText: "Current pool host: \(model.selectedPoolHost)", copyValue: model.selectedPoolHost)
                    }
                }

                DashboardCard(theme: theme) {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Wallet only. Worker name stays optional in Advanced.")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(theme.tertiaryText)
                        Text(model.appleSiliconMiningSummary)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(theme.secondaryText)
                        Text(model.coinCatalogStatusText)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(theme.tertiaryText)

                        HStack(alignment: .top, spacing: 14) {
                            FieldShell(title: "Coin", theme: theme) {
                                Button {
                                    activePanel = .coinPicker
                                } label: {
                                    SelectionFieldLabel(
                                        text: model.coinSymbol,
                                        detail: model.selectedCoin?.name,
                                        theme: theme
                                    )
                                }
                                .buttonStyle(.plain)
                                .help("Open the full searchable payout coin catalog from unMineable.")
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
                    VStack(spacing: 12) {
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
            .padding(16)
        }
    }
}

struct WalletStatsDashboardView: View {
    @ObservedObject var model: NativeAppModel
    @Binding var activePanel: SecondaryPanel?
    let theme: DashboardTheme

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                DashboardCard(theme: theme) {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(alignment: .firstTextBaseline, spacing: 12) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Wallet Stats")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundStyle(theme.primaryText)
                                Text("Uses the coin and wallet currently selected in the Mine tab.")
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundStyle(theme.tertiaryText)
                            }
                            Spacer()
                            Button(model.isRefreshingWalletStats ? "Refreshing..." : "Refresh Wallet Stats") {
                                model.refreshWalletStatsNow()
                            }
                            .buttonStyle(.bordered)
                            .disabled(model.isRefreshingWalletStats || model.walletAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            .help("Refresh wallet balance, payout threshold, and aggregate unMineable wallet activity.")
                        }

                        Text(model.walletStatsStatusText)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(theme.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)

                        HStack(alignment: .bottom, spacing: 20) {
                            MetricBlock(title: "Current Balance", value: model.walletBalanceText, theme: theme)
                            MetricBlock(title: "Threshold", value: model.walletThresholdText, theme: theme)
                            Spacer(minLength: 0)
                        }

                        if !model.walletStatsTimestampText.isEmpty {
                            Text(model.walletStatsTimestampText)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(theme.tertiaryText)
                        }
                    }
                }

                DashboardCard(theme: theme) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Selected Wallet")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(theme.primaryText)

                        SessionLine(label: "Address", value: model.displayWallet(), theme: theme, helpText: model.walletAddress.isEmpty ? "Wallet address is not set." : model.walletAddress, copyValue: model.walletAddress)
                        SessionLine(label: "Coin", value: model.coinSymbol, theme: theme, helpText: "Current payout coin selection.")
                        SessionLine(label: "Network", value: model.walletResolvedNetworkText, theme: theme, helpText: "Network reported by unMineable for the selected wallet and coin.")
                        SessionLine(label: "Algorithm", value: model.selectedAlgorithm?.label ?? "-", theme: theme, helpText: "Current mining algorithm selection from the Mine tab.")
                        SessionLine(label: "Pool", value: model.selectedPoolHost, theme: theme, helpText: "Pool host for the current algorithm selection.", copyValue: model.selectedPoolHost)
                    }
                }

                DashboardCard(theme: theme) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Aggregate Wallet Activity")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(theme.primaryText)

                        SessionLine(label: "Wallet Aggregate", value: model.walletAggregateHashrateText, theme: theme, helpText: "Aggregate hashrate reported by unMineable for this wallet. This can include this app and any other miners pointed at the same address.")
                        SessionLine(label: "Active Workers", value: model.walletWorkerCountText, theme: theme, helpText: "Active workers reported by unMineable for this wallet.")
                        SessionLine(label: "Algorithms", value: model.walletAlgorithmCountText, theme: theme, helpText: "Distinct active algorithms reported by unMineable for this wallet.")
                        SessionLine(label: "Total Paid", value: model.walletPaidText, theme: theme, helpText: "Total paid amount reported by unMineable for this wallet and selected coin.")
                        SessionLine(label: "Last Payment", value: model.walletLastPaymentText, theme: theme, helpText: "Last payout date reported by unMineable for this wallet.")
                    }
                }

                DashboardCard(padding: 16, theme: theme) {
                    HStack(alignment: .center, spacing: 12) {
                        Button("Open Status") {
                            activePanel = .info
                        }
                        .buttonStyle(.bordered)
                        .help("Open the detailed pool, session, and project status sheet.")

                        Button("Open Setup") {
                            activePanel = .setup
                        }
                        .buttonStyle(.bordered)
                        .help("Open setup tabs for miner management, path overrides, validation, and installer logs.")

                        Spacer()

                        Text("Wallet stats are read-only and come from unMineable's public API.")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(theme.tertiaryText)
                    }
                }
            }
            .padding(16)
        }
    }
}

struct NativeContentView: View {
    @StateObject private var model = NativeAppModel()
    @State private var activePanel: SecondaryPanel?
    @State private var selectedTab: MainDashboardTab = .mine
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
        VStack(spacing: 0) {
            DashboardHeaderView(model: model, selectedTab: $selectedTab, activePanel: $activePanel, theme: theme)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 6)

            Group {
                switch selectedTab {
                case .mine:
                    MineDashboardView(model: model, activePanel: $activePanel, theme: theme)
                case .wallet:
                    WalletStatsDashboardView(model: model, activePanel: $activePanel, theme: theme)
                }
            }
        }
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
                case .coinPicker:
                    CoinPickerSheetView(model: model)
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
