import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

bool downloadReportFile(String content, String fileName, String mimeType) {
  final prefix = mimeType.startsWith('text/csv') ? '\uFEFF' : '';
  final blob = web.Blob(
    ['$prefix$content'.toJS].toJS,
    web.BlobPropertyBag(type: mimeType),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = fileName;
  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
  return true;
}

bool printReport(String printableHtml) {
  final blob = web.Blob(
    [printableHtml.toJS].toJS,
    web.BlobPropertyBag(type: 'text/html;charset=utf-8'),
  );
  final url = web.URL.createObjectURL(blob);
  final printWindow = web.window.open(url, '_blank');
  if (printWindow == null) {
    web.URL.revokeObjectURL(url);
    return false;
  }
  Timer(const Duration(minutes: 10), () => web.URL.revokeObjectURL(url));
  return true;
}
