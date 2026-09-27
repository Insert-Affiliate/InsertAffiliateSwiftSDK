#if canImport(UIKit) && canImport(SwiftUI)
import SwiftUI
import UIKit

// Drop-in "Refer a friend" screen. Copy and colour come from the options, then
// the portal settings, then the defaults below. Store rules: share sheet only,
// no Contacts access, and nothing in the app is gated behind sharing.

/// Every label on the drop-in "Refer a friend" screen, so an app can translate or
/// reword it. Leave a field nil (or blank) to keep the English default. Keep the
/// placeholders: `{email}` in `codeSentNotice` and `{date}` in `premiumUntil`.
/// `headline` and `rewardText` are not here: they come from the portal and from
/// `ReferAFriendOptions`.
public struct ReferralStrings: Sendable, Equatable {
    // Joining
    public var emailLabel: String?
    public var nameLabel: String?
    public var joinButton: String?
    // Email code step
    public var codeLabel: String?
    public var codeSentNotice: String?
    public var verifyButton: String?
    public var resendButton: String?
    public var codeResentNotice: String?
    public var differentEmailButton: String?
    // Joined
    public var codeLabelTitle: String?
    public var copyButton: String?
    public var copiedNotice: String?
    public var shareButton: String?
    public var referralsLabel: String?
    public var earnedLabel: String?
    public var premiumUntil: String?
    public var rewardsHeading: String?
    public var redeemButton: String?
    public var dashboardLink: String?
    // Frame and states
    public var closeButton: String?
    /// Read out while the screen loads; the screen itself shows a spinner.
    public var loading: String?
    public var tryAgainButton: String?
    // Errors, by the server's error code
    public var errorProgramDisabled: String?
    public var errorAffiliateLimitReached: String?
    public var errorInvalidCode: String?
    public var errorTooManyCodes: String?
    public var errorRateLimited: String?
    public var errorInvalidEmail: String?
    public var errorNetwork: String?
    public var errorServer: String?

    public init(
        emailLabel: String? = nil,
        nameLabel: String? = nil,
        joinButton: String? = nil,
        codeLabel: String? = nil,
        codeSentNotice: String? = nil,
        verifyButton: String? = nil,
        resendButton: String? = nil,
        codeResentNotice: String? = nil,
        differentEmailButton: String? = nil,
        codeLabelTitle: String? = nil,
        copyButton: String? = nil,
        copiedNotice: String? = nil,
        shareButton: String? = nil,
        referralsLabel: String? = nil,
        earnedLabel: String? = nil,
        premiumUntil: String? = nil,
        rewardsHeading: String? = nil,
        redeemButton: String? = nil,
        dashboardLink: String? = nil,
        closeButton: String? = nil,
        loading: String? = nil,
        tryAgainButton: String? = nil,
        errorProgramDisabled: String? = nil,
        errorAffiliateLimitReached: String? = nil,
        errorInvalidCode: String? = nil,
        errorTooManyCodes: String? = nil,
        errorRateLimited: String? = nil,
        errorInvalidEmail: String? = nil,
        errorNetwork: String? = nil,
        errorServer: String? = nil
    ) {
        self.emailLabel = emailLabel
        self.nameLabel = nameLabel
        self.joinButton = joinButton
        self.codeLabel = codeLabel
        self.codeSentNotice = codeSentNotice
        self.verifyButton = verifyButton
        self.resendButton = resendButton
        self.codeResentNotice = codeResentNotice
        self.differentEmailButton = differentEmailButton
        self.codeLabelTitle = codeLabelTitle
        self.copyButton = copyButton
        self.copiedNotice = copiedNotice
        self.shareButton = shareButton
        self.referralsLabel = referralsLabel
        self.earnedLabel = earnedLabel
        self.premiumUntil = premiumUntil
        self.rewardsHeading = rewardsHeading
        self.redeemButton = redeemButton
        self.dashboardLink = dashboardLink
        self.closeButton = closeButton
        self.loading = loading
        self.tryAgainButton = tryAgainButton
        self.errorProgramDisabled = errorProgramDisabled
        self.errorAffiliateLimitReached = errorAffiliateLimitReached
        self.errorInvalidCode = errorInvalidCode
        self.errorTooManyCodes = errorTooManyCodes
        self.errorRateLimited = errorRateLimited
        self.errorInvalidEmail = errorInvalidEmail
        self.errorNetwork = errorNetwork
        self.errorServer = errorServer
    }

    /// The English text the screen shows for every label.
    public static let defaults = ReferralStrings(
        emailLabel: "Email",
        nameLabel: "Name",
        joinButton: "Get my link",
        codeLabel: "6-digit code",
        codeSentNotice: "You already have an account. We emailed a 6-digit code to {email}.",
        verifyButton: "Verify",
        resendButton: "Send a new code",
        codeResentNotice: "We sent a new code. Check your email.",
        differentEmailButton: "Use a different email",
        codeLabelTitle: "Your code",
        copyButton: "Copy",
        copiedNotice: "Copied",
        shareButton: "Share",
        referralsLabel: "Referrals",
        earnedLabel: "Earned",
        premiumUntil: "Free premium until {date}",
        rewardsHeading: "Your rewards",
        redeemButton: "Redeem",
        dashboardLink: "Open my dashboard",
        closeButton: "Close",
        loading: "Loading...",
        tryAgainButton: "Try again",
        errorProgramDisabled: "Referrals are not available in this app right now.",
        errorAffiliateLimitReached: "The referral program is full right now. Please try again later.",
        errorInvalidCode: "That code is wrong or has expired. Check your email or send a new code.",
        errorTooManyCodes: "Too many attempts. Please wait a while and try again.",
        errorRateLimited: "Too many attempts. Please wait a while and try again.",
        errorInvalidEmail: "Please enter a valid email address.",
        errorNetwork: "Could not connect. Check your internet connection and try again.",
        errorServer: "Something went wrong. Please try again."
    )

    /// The English default for one label.
    public static func defaultText(_ key: KeyPath<ReferralStrings, String?>) -> String {
        return defaults[keyPath: key] ?? ""
    }
}

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
    /// The screen's labels. Every field is optional and falls back to the English default.
    public var strings: ReferralStrings?
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
        strings: ReferralStrings? = nil,
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
        self.strings = strings
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
                    Button(model.text(\.closeButton)) { close() }
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
                    .accessibilityLabel(Text(model.text(\.loading)))
                Spacer()
            }
            .padding(.vertical, 40)
        case .unavailable:
            EmptyView()
        case .loadFailed:
            primaryButton(model.text(\.tryAgainButton)) { await model.load() }
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
            field(model.text(\.nameLabel), text: $model.name)
                .textContentType(.name)
            field(model.text(\.emailLabel), text: $model.email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
            primaryButton(model.text(\.joinButton)) { await model.enrol() }
                .disabled(model.email.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }

    private var codeForm: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(model.codeSentNotice)
                .font(font(.callout, size: 16))
                .fixedSize(horizontal: false, vertical: true)
            field(model.text(\.codeLabel), text: $model.code)
                .textContentType(.oneTimeCode)
                .keyboardType(.numberPad)
            primaryButton(model.text(\.verifyButton)) { await model.verify() }
                .disabled(!model.hasCompleteCode)
            Button(model.text(\.resendButton)) {
                Task { await model.resendCode() }
            }
            .font(font(.callout, size: 16))
            .foregroundColor(theme)
            .disabled(model.isBusy)
            Button(model.text(\.differentEmailButton)) { model.useDifferentEmail() }
                .font(font(.callout, size: 16))
                .foregroundColor(theme)
                .disabled(model.isBusy)
        }
    }

    private func enrolledView(_ affiliate: InsertAffiliateSwift.AffiliateDetails) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(model.text(\.codeLabelTitle))
                    .font(font(.caption, size: 12))
                    .foregroundColor(.secondary)
                HStack {
                    Text(affiliate.affiliateShortCode)
                        .font(font(.title3, size: 20).weight(.semibold).monospaced())
                        .textSelection(.enabled)
                    Spacer()
                    Button(model.text(model.copied ? \.copiedNotice : \.copyButton)) { model.copyCode() }
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

            primaryButton(model.text(\.shareButton)) { model.share() }

            if let stats = model.stats {
                HStack(spacing: 12) {
                    statTile(title: model.text(\.referralsLabel), value: "\(stats.referralCount)")
                    statTile(title: model.text(\.earnedLabel), value: model.formattedEarned(stats))
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
                Link(model.text(\.dashboardLink), destination: url)
                    .font(font(.callout, size: 16))
                    .foregroundColor(theme)
            }
        }
    }

    private func rewardsList(_ codes: [InsertAffiliateSwift.ReferralRewardCode]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(model.text(\.rewardsHeading))
                .font(font(.caption, size: 12))
                .foregroundColor(.secondary)
            ForEach(codes, id: \.code) { reward in
                HStack {
                    Text(reward.code)
                        .font(font(.body, size: 17).weight(.semibold).monospaced())
                        .textSelection(.enabled)
                    Spacer()
                    Button(model.text(\.redeemButton)) { UIApplication.shared.open(reward.redeemUrl) }
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

    /// The app's wording for a label, or the English default.
    func text(_ key: KeyPath<ReferralStrings, String?>) -> String {
        return firstNonEmpty(options.strings?[keyPath: key]) ?? ReferralStrings.defaultText(key)
    }

    /// "We emailed a 6-digit code to {email}." for the address the code went to.
    var codeSentNotice: String {
        text(\.codeSentNotice).replacingOccurrences(of: "{email}", with: email)
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
        Self.premiumUntilText(stats?.premiumUntil, now: Date(), template: text(\.premiumUntil))
    }

    static func premiumUntilText(
        _ premiumUntil: Date?,
        now: Date,
        template: String = ReferralStrings.defaultText(\.premiumUntil),
        locale: Locale = .current
    ) -> String? {
        guard let premiumUntil = premiumUntil, premiumUntil > now else { return nil }
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return template.replacingOccurrences(of: "{date}", with: formatter.string(from: premiumUntil))
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
        guard let companyCode = InsertAffiliateSwift.syncCompanyCode, !companyCode.isEmpty else {
            print("[Insert Affiliate] Refer a friend needs the SDK initialized with your company code before it is shown.")
            errorMessage = message(for: "NOT_INITIALIZED", fallback: nil)
            step = .unavailable
            return
        }
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
            errorMessage = message(for: "NETWORK_ERROR", fallback: nil)
            step = .loadFailed
            return
        case .serverError:
            errorMessage = message(for: nil, fallback: nil)
            step = .loadFailed
            return
        case .notConnected:
            break
        }

        if loadedConfig?.enabled == false {
            errorMessage = message(for: "PROGRAM_DISABLED", fallback: nil)
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
                self.noticeMessage = self.text(\.codeResentNotice)
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
            errorMessage = message(for: result.errorCode, fallback: result.errorMessage)
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

    // NOT_INITIALIZED is a mistake in the app, so the user sees the same wording as
    // a switched-off program while the developer message goes to the log.
    func message(for errorCode: String?, fallback: String?) -> String {
        switch errorCode {
        case "PROGRAM_DISABLED", "NOT_INITIALIZED":
            return text(\.errorProgramDisabled)
        case "AFFILIATE_LIMIT_REACHED":
            return text(\.errorAffiliateLimitReached)
        case "INVALID_CODE":
            return text(\.errorInvalidCode)
        case "TOO_MANY_CODES":
            return text(\.errorTooManyCodes)
        case "RATE_LIMITED":
            return text(\.errorRateLimited)
        case "INVALID_EMAIL":
            return text(\.errorInvalidEmail)
        case "NETWORK_ERROR":
            return text(\.errorNetwork)
        default:
            if let fallback = fallback, !fallback.isEmpty {
                return fallback
            }
            return text(\.errorServer)
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
