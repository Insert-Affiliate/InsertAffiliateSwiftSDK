#if canImport(UIKit) && canImport(SwiftUI)
import SwiftUI
import UIKit

// Drop-in "Refer a friend" screen. Copy and colour come from the options, then
// the portal settings, then the defaults below. Store rules: share sheet only,
// no Contacts access, and nothing in the app is gated behind sharing.

/// Options for the drop-in "Refer a friend" screen.
public struct ReferAFriendOptions {
    /// Prefills the email field (usually the app's signed-in user).
    public var email: String?
    /// Prefills the name field.
    public var name: String?
    /// The user's RevenueCat app user id or Adapty customer user id, so rewards can be given automatically.
    public var appUserId: String?
    /// The user's own Google Play subscription purchase token (Android only).
    public var playPurchaseToken: String?
    /// Share sheet message. May use `{link}` and `{code}` placeholders.
    public var shareMessage: String?
    /// `#RRGGBB`. Overrides the portal colour.
    public var primaryColor: String?
    /// Overrides the portal headline.
    public var headline: String?
    /// Overrides the portal reward text.
    public var rewardText: String?
    /// A custom font name (e.g. one bundled with your app). Uses the system font when nil.
    public var fontName: String?
    /// Corner radius of buttons and fields.
    public var cornerRadius: CGFloat
    /// Called when the screen is closed.
    public var onClose: (() -> Void)?

    public init(
        email: String? = nil,
        name: String? = nil,
        appUserId: String? = nil,
        playPurchaseToken: String? = nil,
        shareMessage: String? = nil,
        primaryColor: String? = nil,
        headline: String? = nil,
        rewardText: String? = nil,
        fontName: String? = nil,
        cornerRadius: CGFloat = 12,
        onClose: (() -> Void)? = nil
    ) {
        self.email = email
        self.name = name
        self.appUserId = appUserId
        self.playPurchaseToken = playPurchaseToken
        self.shareMessage = shareMessage
        self.primaryColor = primaryColor
        self.headline = headline
        self.rewardText = rewardText
        self.fontName = fontName
        self.cornerRadius = cornerRadius
        self.onClose = onClose
    }
}

extension InsertAffiliateSwift {
    /// Presents the drop-in "Refer a friend" screen from a UIKit view controller.
    /// - Parameter from: the view controller to present from; defaults to the top-most one.
    @available(iOS 15.0, *)
    @MainActor
    public static func showReferAFriend(from viewController: UIViewController? = nil, options: ReferAFriendOptions = ReferAFriendOptions()) {
        guard let presenter = viewController ?? topViewController() else {
            print("[Insert Affiliate] Cannot show Refer a friend: no view controller to present from")
            return
        }
        let host = ReferAFriendHostingController(options: options)
        presenter.present(host, animated: true)
    }
}

@available(iOS 15.0, *)
final class ReferAFriendHostingController: UIHostingController<ReferAFriendView> {
    private var onClose: (() -> Void)?

    init(options: ReferAFriendOptions) {
        // The screen's Close button dismisses this controller; onClose then fires
        // from viewDidDisappear so a swipe-down dismiss reports it too.
        var viewOptions = options
        viewOptions.onClose = nil
        onClose = options.onClose
        super.init(rootView: ReferAFriendView(options: viewOptions))
        rootView = ReferAFriendView(options: viewOptions) { [weak self] in
            self?.dismiss(animated: true)
        }
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isBeingDismissed {
            let callback = onClose
            onClose = nil
            callback?()
        }
    }
}

/// The drop-in "Refer a friend" screen. Present it as a sheet in SwiftUI, or use
/// `InsertAffiliateSwift.showReferAFriend(from:options:)` from UIKit.
@available(iOS 15.0, *)
public struct ReferAFriendView: View {
    @StateObject private var model: ReferAFriendModel
    @Environment(\.dismiss) private var environmentDismiss
    private let options: ReferAFriendOptions
    private let dismissAction: (() -> Void)?

    public init(options: ReferAFriendOptions = ReferAFriendOptions()) {
        self.init(options: options, dismissAction: nil)
    }

    init(options: ReferAFriendOptions, dismissAction: (() -> Void)?) {
        self.options = options
        self.dismissAction = dismissAction
        _model = StateObject(wrappedValue: ReferAFriendModel(options: options))
    }

    private var theme: Color { model.themeColor }

    private func font(_ style: Font.TextStyle, size: CGFloat) -> Font {
        if let name = options.fontName, !name.isEmpty {
            return .custom(name, size: size, relativeTo: style)
        }
        return .system(style)
    }

    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    content
                    if let message = model.errorMessage {
                        Text(message)
                            .font(font(.footnote, size: 13))
                            .foregroundColor(.red)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if let notice = model.noticeMessage {
                        Text(notice)
                            .font(font(.footnote, size: 13))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { close() }
                        .foregroundColor(theme)
                }
            }
        }
        .navigationViewStyle(.stack)
        .tint(theme)
        .task { await model.load() }
        .onAppear { model.screenAppeared() }
        // A swipe-down dismiss of a SwiftUI sheet only shows up here.
        .onDisappear { model.reportClose() }
    }

    private func close() {
        model.reportClose()
        if let dismissAction = dismissAction {
            dismissAction()
        } else {
            environmentDismiss()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(model.headline)
                .font(font(.title2, size: 22).weight(.bold))
            if !model.rewardText.isEmpty {
                Text(model.rewardText)
                    .font(font(.body, size: 17))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch model.step {
        case .loading:
            HStack {
                Spacer()
                ProgressView()
                Spacer()
            }
            .padding(.vertical, 40)
        case .unavailable:
            EmptyView()
        case .loadFailed:
            primaryButton("Try again") { await model.load() }
        case .notEnrolled:
            enrolForm
        case .verifyCode:
            codeForm
        case .enrolled(let affiliate):
            enrolledView(affiliate)
        }
    }

    private var enrolForm: some View {
        VStack(alignment: .leading, spacing: 12) {
            field("Name", text: $model.name)
                .textContentType(.name)
            field("Email", text: $model.email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
            primaryButton("Get my link") { await model.enrol() }
                .disabled(model.email.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }

    private var codeForm: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("You already have an account. We emailed a 6-digit code to \(model.email).")
                .font(font(.callout, size: 16))
                .fixedSize(horizontal: false, vertical: true)
            field("6-digit code", text: $model.code)
                .textContentType(.oneTimeCode)
                .keyboardType(.numberPad)
            primaryButton("Verify") { await model.verify() }
                .disabled(!model.hasCompleteCode)
            Button("Send a new code") {
                Task { await model.resendCode() }
            }
            .font(font(.callout, size: 16))
            .foregroundColor(theme)
            .disabled(model.isBusy)
            Button("Use a different email") { model.useDifferentEmail() }
                .font(font(.callout, size: 16))
                .foregroundColor(theme)
                .disabled(model.isBusy)
        }
    }

    private func enrolledView(_ affiliate: InsertAffiliateSwift.AffiliateDetails) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Your code")
                    .font(font(.caption, size: 12))
                    .foregroundColor(.secondary)
                HStack {
                    Text(affiliate.affiliateShortCode)
                        .font(font(.title3, size: 20).weight(.semibold).monospaced())
                        .textSelection(.enabled)
                    Spacer()
                    Button(model.copied ? "Copied" : "Copy") { model.copyCode() }
                        .foregroundColor(theme)
                }
                if model.hasLink {
                    Text(affiliate.deeplinkUrl)
                        .font(font(.footnote, size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .textSelection(.enabled)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: options.cornerRadius)
                    .fill(theme.opacity(0.08))
            )

            primaryButton("Share") { model.share() }

            if let stats = model.stats {
                HStack(spacing: 12) {
                    statTile(title: "Referrals", value: "\(stats.referralCount)")
                    statTile(title: "Earned", value: model.formattedEarned(stats))
                }
            }

            if let premiumText = model.premiumUntilText {
                Text(premiumText)
                    .font(font(.callout, size: 16).weight(.semibold))
                    .foregroundColor(theme)
            }

            // Google Play codes (from an Android phone) can't be redeemed here.
            if let codes = model.stats?.rewardCodes.filter(\.isAppStore), !codes.isEmpty {
                rewardsList(codes)
            }

            if let url = model.dashboardURL {
                Link("Open my dashboard", destination: url)
                    .font(font(.callout, size: 16))
                    .foregroundColor(theme)
            }
        }
    }

    private func rewardsList(_ codes: [InsertAffiliateSwift.ReferralRewardCode]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your rewards")
                .font(font(.caption, size: 12))
                .foregroundColor(.secondary)
            ForEach(codes, id: \.code) { reward in
                HStack {
                    Text(reward.code)
                        .font(font(.body, size: 17).weight(.semibold).monospaced())
                        .textSelection(.enabled)
                    Spacer()
                    Button("Redeem") { UIApplication.shared.open(reward.redeemUrl) }
                        .foregroundColor(theme)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: options.cornerRadius)
                        .stroke(Color.secondary.opacity(0.3))
                )
            }
        }
    }

    private func statTile(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(font(.title3, size: 20).weight(.bold))
            Text(title)
                .font(font(.caption, size: 12))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: options.cornerRadius)
                .stroke(Color.secondary.opacity(0.3))
        )
    }

    private func field(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .font(font(.body, size: 17))
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: options.cornerRadius)
                    .stroke(Color.secondary.opacity(0.4))
            )
    }

    private func primaryButton(_ title: String, action: @escaping @MainActor () async -> Void) -> some View {
        Button {
            Task { await action() }
        } label: {
            ZStack {
                Text(title).opacity(model.isBusy ? 0 : 1)
                if model.isBusy {
                    ProgressView().tint(.white)
                }
            }
            .font(font(.headline, size: 17))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: options.cornerRadius)
                    .fill(theme)
            )
        }
        .disabled(model.isBusy)
    }
}

@available(iOS 15.0, *)
@MainActor
final class ReferAFriendModel: ObservableObject {
    enum Step: Equatable {
        case loading
        case unavailable
        case loadFailed
        case notEnrolled
        case verifyCode
        case enrolled(InsertAffiliateSwift.AffiliateDetails)
    }

    static let defaultHeadline = "Refer a friend"
    static let defaultColor = "#6A0DAD"

    @Published var step: Step = .loading
    @Published var name: String
    @Published var email: String
    @Published var code = ""
    @Published var isBusy = false
    @Published var copied = false
    @Published var errorMessage: String?
    @Published var noticeMessage: String?
    @Published var stats: InsertAffiliateSwift.MyAffiliateDetails?
    @Published private var config: InsertAffiliateSwift.ReferralProgramConfig?

    private let options: ReferAFriendOptions
    // Set once the referrer's account has been sent, so it's saved at most once per screen.
    private var accountSaved = false
    // Set once onClose has fired, so the Close button and the disappear that follows
    // report a single close.
    private var closeReported = false

    init(options: ReferAFriendOptions) {
        self.options = options
        self.name = options.name ?? ""
        self.email = options.email ?? ""
    }

    var headline: String {
        firstNonEmpty(options.headline, config?.headline) ?? Self.defaultHeadline
    }

    var rewardText: String {
        firstNonEmpty(options.rewardText, config?.rewardText) ?? ""
    }

    var themeColor: Color {
        Self.color(hex: options.primaryColor) ?? Self.color(hex: config?.primaryColor) ?? Self.color(hex: Self.defaultColor)!
    }

    var hasLink: Bool {
        guard case .enrolled(let affiliate) = step else { return false }
        return affiliate.deeplinkUrl.lowercased().hasPrefix("http")
    }

    var dashboardURL: URL? {
        guard let text = stats?.dashboardUrl, !text.isEmpty else { return nil }
        return URL(string: text)
    }

    /// "Free premium until {date}" while the referrer's reward premium is running.
    var premiumUntilText: String? {
        Self.premiumUntilText(stats?.premiumUntil, now: Date())
    }

    static func premiumUntilText(_ premiumUntil: Date?, now: Date, locale: Locale = .current) -> String? {
        guard let premiumUntil = premiumUntil, premiumUntil > now else { return nil }
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return "Free premium until \(formatter.string(from: premiumUntil))"
    }

    /// True once the code field holds exactly six digits.
    var hasCompleteCode: Bool {
        InsertAffiliateSwift.normalizedVerificationCode(code).count == 6
    }

    /// The referrer's accounts from the screen options, sent on enrol and verify.
    var accountOptions: InsertAffiliateSwift.ReferrerAccountOptions {
        InsertAffiliateSwift.ReferrerAccountOptions(appUserId: options.appUserId, playPurchaseToken: options.playPurchaseToken)
    }

    /// True when the app passed an account id that hasn't been saved yet on this screen.
    var needsAccountSave: Bool {
        guard !accountSaved else { return false }
        return [options.appUserId, options.playPurchaseToken].contains {
            !($0?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "").isEmpty
        }
    }

    func screenAppeared() {
        closeReported = false
    }

    /// Calls `onClose` once per time the screen is shown.
    func reportClose() {
        guard !closeReported else { return }
        closeReported = true
        options.onClose?()
    }

    func load() async {
        step = .loading
        errorMessage = nil
        async let configRequest = InsertAffiliateSwift.getReferralProgramConfig()
        async let detailsRequest = InsertAffiliateSwift.loadMyAffiliateDetails()
        let (loadedConfig, details) = await (configRequest, detailsRequest)
        apply(details, config: loadedConfig)
    }

    /// Moves the screen to the step for a loaded (or failed) details request.
    func apply(_ details: InsertAffiliateSwift.MyAffiliateDetailsLoad, config loadedConfig: InsertAffiliateSwift.ReferralProgramConfig?) {
        config = loadedConfig

        switch details {
        case .loaded(let details):
            stats = details
            step = .enrolled(details.affiliate)
            // Already a referrer: save their account so any waiting rewards are given.
            if needsAccountSave {
                accountSaved = true
                let account = accountOptions
                Task {
                    await InsertAffiliateSwift.setReferrerAccount(appUserId: account.appUserId, playPurchaseToken: account.playPurchaseToken)
                }
            }
            return
        case .networkError:
            // Still connected; the stats just couldn't be loaded.
            errorMessage = Self.message(for: "NETWORK_ERROR", fallback: nil)
            step = .loadFailed
            return
        case .serverError:
            errorMessage = Self.message(for: nil, fallback: nil)
            step = .loadFailed
            return
        case .notConnected:
            break
        }

        if loadedConfig?.enabled == false {
            errorMessage = Self.message(for: "PROGRAM_DISABLED", fallback: nil)
            step = .unavailable
        } else {
            step = .notEnrolled
        }
    }

    func enrol() async {
        await run {
            let result = await InsertAffiliateSwift.createAffiliateForUser(email: self.email, name: self.name, options: self.accountOptions)
            await self.handle(result)
        }
    }

    func verify() async {
        await run {
            let result = await InsertAffiliateSwift.verifyAffiliateCode(email: self.email, code: self.code, name: self.name, options: self.accountOptions)
            await self.handle(result)
        }
    }

    /// Back from the code step to the email form.
    func useDifferentEmail() {
        guard !isBusy, step == .verifyCode else { return }
        code = ""
        errorMessage = nil
        noticeMessage = nil
        step = .notEnrolled
    }

    func resendCode() async {
        await run {
            let result = await InsertAffiliateSwift.createAffiliateForUser(email: self.email, name: self.name, options: self.accountOptions)
            if result.status == .verificationRequired {
                self.code = ""
                self.noticeMessage = "We sent a new code. Check your email."
            } else {
                await self.handle(result)
            }
        }
    }

    func copyCode() {
        guard case .enrolled(let affiliate) = step else { return }
        UIPasteboard.general.string = affiliate.affiliateShortCode
        copied = true
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            self.copied = false
        }
    }

    func share() {
        guard case .enrolled(let affiliate) = step else { return }
        let text = InsertAffiliateSwift.buildReferralShareText(
            affiliate: affiliate,
            companyName: config?.companyName ?? "",
            message: options.shareMessage
        )
        _ = InsertAffiliateSwift.presentReferralShareSheet(text: text, from: nil)
    }

    func formattedEarned(_ details: InsertAffiliateSwift.MyAffiliateDetails) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = details.currency
        return formatter.string(from: NSNumber(value: details.totalEarned)) ?? String(format: "%.2f %@", details.totalEarned, details.currency)
    }

    private func handle(_ result: InsertAffiliateSwift.ReferralEnrolmentResult) async {
        switch result.status {
        case .verificationRequired:
            code = ""
            step = .verifyCode
        case .created, .connected:
            code = ""
            // Enrol and verify already sent the account.
            accountSaved = true
            let details = await InsertAffiliateSwift.getMyAffiliateDetails()
            stats = details
            if let affiliate = details?.affiliate ?? result.affiliate {
                step = .enrolled(affiliate)
            }
        case .error:
            errorMessage = Self.message(for: result.errorCode, fallback: result.errorMessage)
        }
    }

    private func run(_ work: @escaping @MainActor () async -> Void) async {
        guard !isBusy else { return }
        isBusy = true
        errorMessage = nil
        noticeMessage = nil
        await work()
        isBusy = false
    }

    private func firstNonEmpty(_ values: String?...) -> String? {
        values.compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }.first { !$0.isEmpty }
    }

    static func message(for errorCode: String?, fallback: String?) -> String {
        switch errorCode {
        case "PROGRAM_DISABLED":
            return "Referrals are not available in this app right now."
        case "AFFILIATE_LIMIT_REACHED":
            return "The referral program is full right now. Please try again later."
        case "INVALID_CODE":
            return "That code is wrong or has expired. Check your email or send a new code."
        case "TOO_MANY_CODES", "RATE_LIMITED":
            return "Too many attempts. Please wait a while and try again."
        case "INVALID_EMAIL":
            return "Please enter a valid email address."
        case "NETWORK_ERROR":
            return "Could not connect. Check your internet connection and try again."
        default:
            if let fallback = fallback, !fallback.isEmpty {
                return fallback
            }
            return "Something went wrong. Please try again."
        }
    }

    static func color(hex: String?) -> Color? {
        guard let hex = hex?.trimmingCharacters(in: .whitespaces), hex.hasPrefix("#"), hex.count == 7,
              let value = UInt32(hex.dropFirst(), radix: 16) else {
            return nil
        }
        return Color(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }
}
#endif
