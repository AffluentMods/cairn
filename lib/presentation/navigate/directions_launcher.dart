// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:url_launcher/url_launcher.dart';

/// Open driving directions to a trailhead in the user's own maps app
/// (Addendum A4.4). The `geo:` intent lets Organic Maps, OsmAnd, or Google Maps
/// handle it; the web fallback is a plain URL, so the community build links no
/// Google library. Returns false if nothing could handle it.
Future<bool> openDirections(double lat, double lon, {String? label}) async {
  final query = label == null
      ? '$lat,$lon'
      : '$lat,$lon(${Uri.encodeComponent(label)})';
  final geo = Uri.parse('geo:$lat,$lon?q=$query');
  if (await canLaunchUrl(geo)) {
    return launchUrl(geo, mode: LaunchMode.externalApplication);
  }
  final web = Uri.https('www.google.com', '/maps/dir/', {
    'api': '1',
    'destination': '$lat,$lon',
  });
  return launchUrl(web, mode: LaunchMode.externalApplication);
}
