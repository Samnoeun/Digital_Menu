import 'dart:io';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:open_filex/open_filex.dart';
import 'package:universal_html/html.dart' as html;  // for kIsWeb
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../models/order_history_model.dart';

class DownloadOrderHistoryService {
  static Future<File?> generateOrderHistoryReport(
      List<OrderHistory> orders, String filterName, String format) async {
    try {
      // Skip permission check for web
      if (!kIsWeb && !await _requestStoragePermission()) {
        return null;
      }

      // Handle web platform differently
      if (kIsWeb) {
        return await _generateWebReport(orders, filterName, format);
      }

      // Mobile platform code
      final directory = await getDownloadsDirectory();
      if (directory == null) return null;
      if (!directory.existsSync()) directory.createSync(recursive: true);

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final sanitizedFilterName = _sanitizeFileName(filterName);

      // Handle DOCX format request - convert to PDF since we don't have DOCX support
      final effectiveFormat =
          format.toLowerCase() == 'docx' ? 'pdf' : format.toLowerCase();
      final fileName = 'order_report_${sanitizedFilterName}_$timestamp.$effectiveFormat';
      final filePath = '${directory.path}/$fileName';

      final file = File(filePath);
      File resultFile;

      switch (effectiveFormat) {
        case 'xlsx':
          resultFile = await _generateExcelReport(
              orders, filterName, directory, sanitizedFilterName, timestamp);
          break;
        case 'pdf':
          resultFile = await _generatePdfReport(
              orders, filterName, directory, sanitizedFilterName, timestamp);
          break;
        default:
          resultFile = await _generateExcelReport(
              orders, filterName, directory, sanitizedFilterName, timestamp);
          break;
      }

      await OpenFilex.open(resultFile.path);
      return resultFile;
    } catch (e, stackTrace) {
      print('Error generating report: $e\n$stackTrace');
      return null;
    }
  }

  // Web-specific report generation
  static Future<File?> _generateWebReport(
      List<OrderHistory> orders, String filterName, String format) async {
    try {
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final sanitizedFilterName = _sanitizeFileName(filterName);
      final effectiveFormat =
          format.toLowerCase() == 'docx' ? 'pdf' : format.toLowerCase();
      final fileName = 'order_report_${sanitizedFilterName}_$timestamp.$effectiveFormat';

      List<int>? fileBytes;
      String mimeType;

      switch (effectiveFormat) {
        case 'xlsx':
          fileBytes = await _generateExcelBytes(orders, filterName);
          mimeType =
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
          break;
        case 'pdf':
          fileBytes = await _generatePdfBytes(orders, filterName);
          mimeType = 'application/pdf';
          break;
        default:
          fileBytes = await _generateExcelBytes(orders, filterName);
          mimeType =
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
          break;
      }

      if (fileBytes != null) {
        final blob = html.Blob([fileBytes], mimeType);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement()
          ..href = url
          ..download = fileName
          ..style.display = 'none';
        html.document.body?.children.add(anchor);
        anchor.click();
        html.document.body?.children.remove(anchor);
        html.Url.revokeObjectUrl(url);
      }

      return null;
    } catch (e, stackTrace) {
      print('Error generating web report: $e\n$stackTrace');
      return null;
    }
  }

  static Future<File> _generateExcelReport(
      List<OrderHistory> orders,
      String filterName,
      Directory directory,
      String sanitizedFilterName,
      String timestamp) async {
    final excel = Excel.createExcel();
    final sheet = excel['Order History'];
    final excelData = _buildExcelData(orders, filterName);

    final headerStyle = CellStyle(
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final titleStyle = CellStyle(
      bold: true,
      fontSize: 16,
      horizontalAlign: HorizontalAlign.Center,
    );

    final normalStyle = CellStyle(
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
    );

    for (var i = 0; i < excelData.length; i++) {
      for (var j = 0; j < excelData[i].length; j++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(
            columnIndex: j, rowIndex: i));
        cell.value = TextCellValue(excelData[i][j].toString());
        if (i == 0) {
          cell.cellStyle = titleStyle;
        } else if (i == 3) {
          cell.cellStyle = headerStyle;
        } else {
          cell.cellStyle = normalStyle;
        }
      }
    }

    sheet.setColumnWidth(0, 8);
    sheet.setColumnWidth(1, 30);
    sheet.setColumnWidth(2, 12);
    sheet.setColumnWidth(3, 15);
    sheet.setColumnWidth(4, 15);

    final fileName = 'order_report_${sanitizedFilterName}_$timestamp.xlsx';
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(excel.encode()!);
    return file;
  }

  static Future<List<int>> _generateExcelBytes(
      List<OrderHistory> orders, String filterName) async {
    final excel = Excel.createExcel();
    final sheet = excel['Order History'];
    final excelData = _buildExcelData(orders, filterName);

    for (var i = 0; i < excelData.length; i++) {
      for (var j = 0; j < excelData[i].length; j++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(
            columnIndex: j, rowIndex: i));
        cell.value = TextCellValue(excelData[i][j].toString());
      }
    }

    sheet.setColumnWidth(0, 8);
    sheet.setColumnWidth(1, 30);
    sheet.setColumnWidth(2, 12);
    sheet.setColumnWidth(3, 15);
    sheet.setColumnWidth(4, 15);

    return excel.save()!;
  }

  static List<List<dynamic>> _buildExcelData(
      List<OrderHistory> orders, String filterName) {
    final excelData = <List<dynamic>>[];

    excelData.add(['ORDER HISTORY REPORT']);
    excelData.add(
        ['Generated on: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}']);
    excelData.add([]);

    excelData.add(['NO', 'Item Name', 'Quantity', 'Price', 'Date']);
    int idCounter = 1;

    for (var order in orders) {
      for (var orderItem in order.orderItems) {
        excelData.add([
          idCounter++,
          orderItem.itemName,
          orderItem.quantity,
          orderItem.price,
          DateFormat('yyyy-MM-dd').format(order.createdAt),
        ]);
      }
    }

    excelData.add([]);
    excelData.add(['REPORT SUMMARY']);
    excelData.add(['Total Orders: ${orders.length}']);

    final totalItems = orders.fold(
        0, (sum, order) => sum + order.orderItems.fold(0, (itemSum, item) => itemSum + item.quantity));
    excelData.add(['Total Items: $totalItems']);

    final totalRevenue = orders.fold(
        0.0, (sum, order) => sum + order.orderItems.fold(0.0, (itemSum, item) => itemSum + (item.price * item.quantity)));
    excelData.add(['Total Revenue: \$${totalRevenue.toStringAsFixed(2)}']);

    final statusCounts = <String, int>{};
    for (var order in orders) {
      statusCounts[order.status] = (statusCounts[order.status] ?? 0) + 1;
    }
    statusCounts.forEach((status, count) {
      excelData.add(['$status Orders: $count']);
    });

    return excelData;
  }

  static Future<File> _generatePdfReport(
      List<OrderHistory> orders,
      String filterName,
      Directory directory,
      String sanitizedFilterName,
      String timestamp) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return _buildPdfContent(orders, filterName);
        },
      ),
    );

    final fileName = 'order_report_${sanitizedFilterName}_$timestamp.pdf';
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static Future<List<int>> _generatePdfBytes(
      List<OrderHistory> orders, String filterName) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return _buildPdfContent(orders, filterName);
        },
      ),
    );
    return await pdf.save();
  }

  static List<pw.Widget> _buildPdfContent(
      List<OrderHistory> orders, String filterName) {
    final content = <pw.Widget>[];

    content.add(
      pw.Text(
        'ORDER HISTORY REPORT',
        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        textAlign: pw.TextAlign.center,
      ),
    );

    content.add(pw.SizedBox(height: 10));
    content.add(pw.Text('Generated on: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}'));
    content.add(pw.SizedBox(height: 20));

    final headers = ['NO', 'Item Name', 'Quantity', 'Price', 'Date'];
    int idCounter = 1;

    final tableData = orders.expand((order) {
      return order.orderItems.map((orderItem) {
        return [
          (idCounter++).toString(),
          orderItem.itemName,
          orderItem.quantity.toString(),
          '\$${orderItem.price.toStringAsFixed(2)}',
          DateFormat('yyyy-MM-dd').format(order.createdAt),
        ];
      });
    }).toList();

    content.add(
      pw.Table.fromTextArray(
        headers: headers,
        data: tableData,
        cellAlignment: pw.Alignment.centerLeft,
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
        cellStyle: const pw.TextStyle(fontSize: 9),
      ),
    );

    content.add(pw.SizedBox(height: 20));
    content.add(
      pw.Header(
        level: 1,
        child: pw.Text(
          'REPORT SUMMARY',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
      ),
    );

    content.add(pw.Text('Total Orders: ${orders.length}'));
    final totalItems = orders.fold(
        0, (sum, order) => sum + order.orderItems.fold(0, (itemSum, item) => itemSum + item.quantity));
    content.add(pw.Text('Total Items: $totalItems'));

    final totalRevenue = orders.fold(
        0.0, (sum, order) => sum + order.orderItems.fold(0.0, (itemSum, item) => itemSum + (item.price * item.quantity)));
    content.add(pw.Text('Total Revenue: \$${totalRevenue.toStringAsFixed(2)}'));

    final statusCounts = <String, int>{};
    for (var order in orders) {
      statusCounts[order.status] = (statusCounts[order.status] ?? 0) + 1;
    }
    statusCounts.forEach((status, count) {
      content.add(pw.Text('$status Orders: $count'));
    });

    return content;
  }

  static String _sanitizeFileName(String name) {
    if (name.isEmpty) return 'report';
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_-]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .substring(0, name.length.clamp(0, 100));
  }

  static Future<bool> _requestStoragePermission() async {
    try {
      if (kIsWeb) return true;

      if (Platform.isAndroid) {
        final isAndroid13OrAbove = await _isAndroid13OrAbove();
        if (isAndroid13OrAbove) return true;

        final status = await Permission.storage.status;
        if (!status.isGranted) {
          final newStatus = await Permission.storage.request();
          if (!newStatus.isGranted) return false;
        }
        return true;
      } else if (Platform.isIOS) {
        return true;
      }
      return false;
    } catch (e) {
      print('Permission error: $e');
      return false;
    }
  }

  static Future<bool> _isAndroid13OrAbove() async {
    try {
      if (!Platform.isAndroid) return false;
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.version.sdkInt >= 33;
    } catch (e) {
      print('Error checking Android version: $e');
      return false;
    }
  }
}
