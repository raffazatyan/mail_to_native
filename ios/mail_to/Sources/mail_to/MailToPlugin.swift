import Flutter
import LinkPresentation
import MessageUI
import UIKit

/// Known third-party mail apps and their compose deep links.
///
/// iOS cannot enumerate installed apps, so every candidate has to be listed
/// here and declared in the host app's `LSApplicationQueriesSchemes` —
/// `canOpenURL` answers `false` for undeclared schemes.
private struct KnownMailApp {
    let id: String
    let name: String
    let scheme: String
    /// Everything before the query string, e.g. `googlegmail:///co?`.
    let composePrefix: String
    /// Query key for the recipient list — not `to` everywhere.
    let recipientKey: String
    /// Query key for the message body — not `body` everywhere.
    let bodyKey: String

    init(
        id: String, name: String, scheme: String, composePrefix: String,
        recipientKey: String = "to", bodyKey: String = "body"
    ) {
        self.id = id
        self.name = name
        self.scheme = scheme
        self.composePrefix = composePrefix
        self.recipientKey = recipientKey
        self.bodyKey = bodyKey
    }
}

private let knownMailApps: [KnownMailApp] = [
    KnownMailApp(
        id: "gmail", name: "Gmail", scheme: "googlegmail",
        composePrefix: "googlegmail:///co?"),
    KnownMailApp(
        id: "outlook", name: "Outlook", scheme: "ms-outlook",
        composePrefix: "ms-outlook://compose?"),
    KnownMailApp(
        id: "spark", name: "Spark", scheme: "readdle-spark",
        composePrefix: "readdle-spark://compose?", recipientKey: "recipient"),
    KnownMailApp(
        id: "yahoo", name: "Yahoo Mail", scheme: "ymail",
        composePrefix: "ymail://mail/compose?"),
    KnownMailApp(
        id: "airmail", name: "Airmail", scheme: "airmail",
        composePrefix: "airmail://compose?", bodyKey: "plainBody"),
    KnownMailApp(
        id: "fastmail", name: "Fastmail", scheme: "fastmail",
        composePrefix: "fastmail://mail/compose?"),
    KnownMailApp(
        id: "proton", name: "Proton Mail", scheme: "protonmail",
        composePrefix: "protonmail://mailto:?"),
    // Mail.ru publishes no compose scheme — this is the community-reported one
    // and is UNVERIFIED. If the app is installed but never shows up in the
    // picker, the scheme below is wrong; detection simply skips it, so a bad
    // guess cannot break the other clients.
    KnownMailApp(
        id: "mailru", name: "Mail.ru", scheme: "mailru-mail",
        composePrefix: "mailru-mail://compose?"),
]

private let appleMailId = "apple_mail"

public class MailToPlugin: NSObject, FlutterPlugin {
    private var pendingComposeResult: FlutterResult?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "mail_to", binaryMessenger: registrar.messenger())
        let instance = MailToPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "installedApps":
            result(installedApps().map(encode))

        case "compose":
            guard let args = call.arguments as? [String: Any] else {
                result(invalidArguments())
                return
            }
            compose(args: args, result: result)

        case "pickApp":
            let args = call.arguments as? [String: Any] ?? [:]
            pickApp(
                title: args["title"] as? String,
                cancelLabel: args["cancelLabel"] as? String,
                emptyMessage: args["emptyMessage"] as? String,
                okLabel: args["okLabel"] as? String,
                otherAppsLabel: args["otherAppsLabel"] as? String,
                showEmptyAlert: args["showEmptyAlert"] as? Bool ?? true,
                showOtherApps: args["showOtherApps"] as? Bool ?? true,
                result: result
            )

        case "share":
            guard let args = call.arguments as? [String: Any] else {
                result(invalidArguments())
                return
            }
            let metadata = args["metadata"] as? [String: Any]
            share(
                subject: args["subject"] as? String ?? "",
                body: args["body"] as? String ?? "",
                headerTitle: metadata?["title"] as? String,
                headerSubtitle: metadata?["subtitle"] as? String,
                headerIcon: (metadata?["icon"] as? FlutterStandardTypedData)?.data,
                image: (metadata?["image"] as? FlutterStandardTypedData)?.data,
                result: result
            )

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Detection

    /// Apple Mail first (when usable), then the known apps in declaration order.
    private func installedApps() -> [(id: String, name: String, native: Bool)] {
        var apps: [(id: String, name: String, native: Bool)] = []

        if MFMailComposeViewController.canSendMail() {
            apps.append((appleMailId, "Apple Mail", true))
        }

        for app in knownMailApps {
            guard let probe = URL(string: "\(app.scheme):"),
                UIApplication.shared.canOpenURL(probe)
            else { continue }
            apps.append((app.id, app.name, false))
        }

        return apps
    }

    private func encode(_ app: (id: String, name: String, native: Bool)) -> [String: Any] {
        ["id": app.id, "name": app.name, "usesNativeComposer": app.native]
    }

    // MARK: - Compose

    private func compose(args: [String: Any], result: @escaping FlutterResult) {
        let appId = args["appId"] as? String
        let subject = args["subject"] as? String ?? ""
        let body = args["body"] as? String ?? ""
        let to = args["to"] as? [String] ?? []
        let cc = args["cc"] as? [String] ?? []
        let bcc = args["bcc"] as? [String] ?? []
        let isHtml = args["isHtml"] as? Bool ?? false

        if appId == appleMailId {
            composeWithAppleMail(
                subject: subject, body: body, to: to, cc: cc, bcc: bcc,
                isHtml: isHtml, result: result)
            return
        }

        // No app id, or an unknown one: fall back to the default `mailto:`
        // handler, which is whichever app the user set as default.
        let known = knownMailApps.first { $0.id == appId }
        let prefix = known?.composePrefix ?? "mailto:?"

        guard
            let url = URL(
                string: prefix
                    + query(
                        subject: subject, body: body, to: to, cc: cc, bcc: bcc,
                        recipientKey: known?.recipientKey ?? "to",
                        bodyKey: known?.bodyKey ?? "body"))
        else {
            result(false)
            return
        }

        UIApplication.shared.open(url, options: [:]) { opened in
            result(opened)
        }
    }

    private func query(
        subject: String, body: String, to: [String], cc: [String], bcc: [String],
        recipientKey: String, bodyKey: String
    ) -> String {
        var parts: [String] = []
        if !to.isEmpty {
            parts.append("\(recipientKey)=\(encoded(to.joined(separator: ",")))")
        }
        if !cc.isEmpty { parts.append("cc=\(encoded(cc.joined(separator: ",")))") }
        if !bcc.isEmpty { parts.append("bcc=\(encoded(bcc.joined(separator: ",")))") }
        parts.append("subject=\(encoded(subject))")
        parts.append("\(bodyKey)=\(encoded(body))")
        return parts.joined(separator: "&")
    }

    /// Percent-encodes for a query value. `+` and `&` must go too: mail apps
    /// render a literal `+` as a space otherwise.
    private func encoded(_ value: String) -> String {
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "+&=?#")
        return value.addingPercentEncoding(withAllowedCharacters: allowed) ?? ""
    }

    private func composeWithAppleMail(
        subject: String, body: String, to: [String], cc: [String], bcc: [String],
        isHtml: Bool, result: @escaping FlutterResult
    ) {
        guard MFMailComposeViewController.canSendMail() else {
            result(false)
            return
        }
        // A compose sheet is already up — don't stack a second one.
        guard pendingComposeResult == nil, let presenter = Self.topViewController() else {
            result(false)
            return
        }

        pendingComposeResult = result

        let controller = MFMailComposeViewController()
        controller.mailComposeDelegate = self
        controller.setSubject(subject)
        controller.setMessageBody(body, isHTML: isHtml)
        if !to.isEmpty { controller.setToRecipients(to) }
        if !cc.isEmpty { controller.setCcRecipients(cc) }
        if !bcc.isEmpty { controller.setBccRecipients(bcc) }
        presenter.present(controller, animated: true)
    }

    // MARK: - Picker

    /// `.alert` style so the list lands centred on screen on both iPhone and
    /// iPad, where `.actionSheet` would need a popover anchor.
    ///
    /// With no mail app installed this puts up a one-button alert and answers
    /// `nil`, so callers need no branch of their own.
    private func pickApp(
        title: String?, cancelLabel: String?, emptyMessage: String?, okLabel: String?,
        otherAppsLabel: String?, showEmptyAlert: Bool, showOtherApps: Bool,
        result: @escaping FlutterResult
    ) {
        let apps = installedApps()
        guard let presenter = Self.topViewController() else {
            result(nil)
            return
        }

        if apps.isEmpty && !showEmptyAlert {
            result(nil)
            return
        }

        var answered = false
        let answer: ([String: Any]?) -> Void = { value in
            guard !answered else { return }
            answered = true
            result(value)
        }

        let alert = UIAlertController(
            title: title ?? "Choose a mail app",
            // The empty state keeps the same alert, with the reason as its body.
            message: apps.isEmpty
                ? (emptyMessage ?? "No mail app is installed on this device.") : nil,
            preferredStyle: .alert
        )

        for app in apps {
            alert.addAction(
                UIAlertAction(title: app.name, style: .default) { [weak self] _ in
                    guard let self else { return }
                    answer(self.encode(app))
                })
        }

        if showOtherApps {
            alert.addAction(
                UIAlertAction(title: otherAppsLabel ?? "Other apps…", style: .default) { _ in
                    answer(Self.otherAppsEntry)
                })
        }

        // Empty state closes with OK; the populated one with Cancel.
        alert.addAction(
            UIAlertAction(
                title: apps.isEmpty ? (okLabel ?? "OK") : (cancelLabel ?? "Cancel"),
                style: .cancel
            ) { _ in
                answer(nil)
            })

        presenter.present(alert, animated: true)
    }

    private static let otherAppsEntry: [String: Any] = [
        "id": "__other_apps__",
        "name": "Other apps",
        "usesNativeComposer": false,
        "isOther": true,
    ]

    // MARK: - Share sheet

    private func share(
        subject: String, body: String, headerTitle: String?, headerSubtitle: String?,
        headerIcon: Data?, image: Data?, result: @escaping FlutterResult
    ) {
        guard let presenter = Self.topViewController() else {
            result(false)
            return
        }

        let picture = image.flatMap(UIImage.init(data:))
        // The rendered picture makes a better thumbnail than the app icon.
        let icon = headerIcon.flatMap(UIImage.init(data:)) ?? picture ?? Self.appIcon()
        let source = SubjectActivityItemSource(
            subject: subject,
            body: body,
            headerTitle: headerTitle ?? subject,
            headerSubtitle: headerSubtitle,
            headerIcon: icon
        )

        // Text first so it stays the mail body and the metadata source; the
        // picture rides along as an attachment / photo.
        var items: [Any] = [source]
        if let picture {
            items.append(picture)
        }

        let controller = UIActivityViewController(
            activityItems: items, applicationActivities: nil)

        // iPad presents this as a popover and crashes without an anchor.
        if let popover = controller.popoverPresentationController {
            popover.sourceView = presenter.view
            popover.sourceRect = CGRect(
                x: presenter.view.bounds.midX, y: presenter.view.bounds.midY,
                width: 0, height: 0)
            popover.permittedArrowDirections = []
        }

        presenter.present(controller, animated: true) {
            result(true)
        }
    }

    // MARK: - Helpers

    /// The host app's own icon, for the share-sheet header.
    ///
    /// Asset-catalog app icons are not addressable by their catalog name, so
    /// the actual filename is read out of `CFBundleIcons`.
    private static func appIcon() -> UIImage? {
        guard
            let icons = Bundle.main.object(forInfoDictionaryKey: "CFBundleIcons")
                as? [String: Any],
            let primary = icons["CFBundlePrimaryIcon"] as? [String: Any],
            let files = primary["CFBundleIconFiles"] as? [String],
            let lastFile = files.last
        else {
            return nil
        }

        return UIImage(named: lastFile)
    }

    private func invalidArguments() -> FlutterError {
        FlutterError(
            code: "INVALID_ARGUMENTS", message: "Expected a message map.", details: nil)
    }

    private static func topViewController() -> UIViewController? {
        let scene =
            UIApplication.shared.connectedScenes
            .first { $0.activationState == .foregroundActive } as? UIWindowScene

        guard let window = scene?.windows.first(where: { $0.isKeyWindow }) else {
            return nil
        }

        var top = window.rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }
}

/// Carries the subject and the header preview into the share sheet.
///
/// A plain `String` activity item has no subject — mail apps opened from the
/// sheet would start with an empty subject line — and no `LPLinkMetadata`, so
/// the header degrades to a bare app icon with no title.
private final class SubjectActivityItemSource: NSObject, UIActivityItemSource {
    private let subject: String
    private let body: String
    private let headerTitle: String
    private let headerSubtitle: String?
    private let headerIcon: UIImage?

    init(
        subject: String,
        body: String,
        headerTitle: String,
        headerSubtitle: String?,
        headerIcon: UIImage?
    ) {
        self.subject = subject
        self.body = body
        self.headerTitle = headerTitle
        self.headerSubtitle = headerSubtitle
        self.headerIcon = headerIcon
    }

    func activityViewControllerPlaceholderItem(_ controller: UIActivityViewController) -> Any {
        body
    }

    func activityViewController(
        _ controller: UIActivityViewController,
        itemForActivityType activityType: UIActivity.ActivityType?
    ) -> Any? {
        body
    }

    func activityViewController(
        _ controller: UIActivityViewController,
        subjectForActivityType activityType: UIActivity.ActivityType?
    ) -> String {
        subject
    }

    /// Fills the header strip above the app grid: icon, bold title, subtitle.
    ///
    /// `originalURL` is what iOS renders as the grey second line — a shared
    /// link would show its domain there. A file URL puts arbitrary text in the
    /// same slot.
    func activityViewControllerLinkMetadata(
        _ controller: UIActivityViewController
    ) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.title = headerTitle

        if let headerIcon {
            metadata.iconProvider = NSItemProvider(object: headerIcon)
        }
        if let headerSubtitle, !headerSubtitle.isEmpty {
            metadata.originalURL = URL(fileURLWithPath: headerSubtitle)
        }

        return metadata
    }
}

extension MailToPlugin: MFMailComposeViewControllerDelegate {
    public func mailComposeController(
        _ controller: MFMailComposeViewController,
        didFinishWith result: MFMailComposeResult,
        error: Error?
    ) {
        controller.dismiss(animated: true) { [weak self] in
            let flutterResult = self?.pendingComposeResult
            self?.pendingComposeResult = nil
            flutterResult?(error == nil)
        }
    }
}
