import Flutter
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
        composePrefix: "readdle-spark://compose?"),
    KnownMailApp(
        id: "yahoo", name: "Yahoo Mail", scheme: "ymail",
        composePrefix: "ymail://mail/compose?"),
    KnownMailApp(
        id: "airmail", name: "Airmail", scheme: "airmail",
        composePrefix: "airmail://compose?"),
    KnownMailApp(
        id: "fastmail", name: "Fastmail", scheme: "fastmail",
        composePrefix: "fastmail://mail/compose?"),
    KnownMailApp(
        id: "proton", name: "Proton Mail", scheme: "protonmail",
        composePrefix: "protonmail://mailto:?"),
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
                    + query(subject: subject, body: body, to: to, cc: cc, bcc: bcc))
        else {
            result(false)
            return
        }

        UIApplication.shared.open(url, options: [:]) { opened in
            result(opened)
        }
    }

    private func query(
        subject: String, body: String, to: [String], cc: [String], bcc: [String]
    ) -> String {
        var parts: [String] = []
        if !to.isEmpty { parts.append("to=\(encoded(to.joined(separator: ",")))") }
        if !cc.isEmpty { parts.append("cc=\(encoded(cc.joined(separator: ",")))") }
        if !bcc.isEmpty { parts.append("bcc=\(encoded(bcc.joined(separator: ",")))") }
        parts.append("subject=\(encoded(subject))")
        parts.append("body=\(encoded(body))")
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
    private func pickApp(title: String?, cancelLabel: String?, result: @escaping FlutterResult) {
        let apps = installedApps()
        guard !apps.isEmpty, let presenter = Self.topViewController() else {
            result(nil)
            return
        }

        let alert = UIAlertController(
            title: title ?? "Choose a mail app", message: nil, preferredStyle: .alert)

        var answered = false
        let answer: ([String: Any]?) -> Void = { value in
            guard !answered else { return }
            answered = true
            result(value)
        }

        for app in apps {
            alert.addAction(
                UIAlertAction(title: app.name, style: .default) { [weak self] _ in
                    guard let self else { return }
                    answer(self.encode(app))
                })
        }
        alert.addAction(
            UIAlertAction(title: cancelLabel ?? "Cancel", style: .cancel) { _ in
                answer(nil)
            })

        presenter.present(alert, animated: true)
    }

    // MARK: - Helpers

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
