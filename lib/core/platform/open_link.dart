import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Where a link opens, which is a product decision rather than a matter of
/// style.
enum LinkTarget {
  /// Outside the application, in whatever application the system picks.
  ///
  /// It is the right thing when what is on the other side **is not a page**: a
  /// signed PDF opens in the system viewer, which is where it can be saved,
  /// printed or sent wherever it needs to go. Bringing it inside would take all
  /// of that away from the person.
  systemApp,

  /// Inside the application, in the system browser.
  ///
  /// Custom Tabs on Android and `SFSafariViewController` on iOS. **It is still
  /// the real browser** — its engine, its process, the person's own cookies,
  /// their password manager and their anti-fraud protection — only drawn inside
  /// this application, with the back button returning to the screen it came
  /// from instead of leaving the application in the background.
  ///
  /// Not to be confused with a `WebView`, which is an engine we host ourselves,
  /// with its own cookie jar and no password manager, and into which the page's
  /// JavaScript can be injected and read. That would make us part of that
  /// page's security boundary, which is exactly what we do not want in front of
  /// an anti-abuse check. **Nothing that asks for a password may go in a
  /// `WebView`.**
  inAppBrowser,
}

/// Opening a link.
///
/// It is exposed as a function so a test can check that something opens without
/// launching a real browser. It returns whether it could.
///
/// It lives in `core` rather than inside a feature because two already use it —
/// a shipment's manifest and a centre's registration — and this repository has
/// paid the same lesson six times: what is hidden inside one screen ends up
/// duplicated in the next.
///
/// **The default target is outside.** Anybody who wants the in-app browser has
/// to ask for it, so that bringing a page inside is a decision written on the
/// screen that takes it rather than something inherited by accident.
typedef OpenLink = Future<bool> Function(String url, {LinkTarget target});

final openLinkProvider = Provider<OpenLink>(
  (ref) => (url, {target = LinkTarget.systemApp}) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    return launchUrl(
      uri,
      mode: switch (target) {
        LinkTarget.systemApp => LaunchMode.externalApplication,
        LinkTarget.inAppBrowser => LaunchMode.inAppBrowserView,
      },
    );
  },
);
