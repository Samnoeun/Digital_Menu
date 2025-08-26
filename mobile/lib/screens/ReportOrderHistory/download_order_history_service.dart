import 'dart:io';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:open_filex/open_filex.dart';
import '../../models/order_history_model.dart';

class DownloadOrderHistoryService {
  static Future<File?> generateOrderHistoryReport(
      List<OrderHistory> orders, String filterName, String format) async {
    try {
      if (!await _requestStoragePermission()) {
        print('Permission denied for storage access');
        return null;
      }

      final directory = await getDownloadsDirectory();
      if (directory == null) {
        print('Error: Downloads directory not available');
        return null;
      }

      if (!directory.existsSync()) {
        directory.createSync(recursive: true);
      }

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final sanitizedFilterName = _sanitizeFileName(filterName);
      final fileExtension = format.toLowerCase();
      final fileName = 'order_report_${sanitizedFilterName}_$timestamp.$fileExtension';
      final filePath = '${directory.path}/$fileName';

      final file = File(filePath);
      if (file.existsSync()) {
        print('Warning: File already exists at $filePath, overwriting');
      }

      File resultFile;
      switch (format.toLowerCase()) {
        case 'xlsx':
          resultFile = await _generateExcelReport(orders, filterName, directory, sanitizedFilterName, timestamp);
          break;
        case 'pdf':
          resultFile = await _generatePdfReport(orders, filterName, directory, sanitizedFilterName, timestamp);
          break;
        case 'docx':
          // DOCX not supported, fall back to PDF
          print('DOCX format not supported, generating PDF instead');
          resultFile = await _generatePdfReport(orders, filterName, directory, sanitizedFilterName, timestamp);
          break;
        case 'csv':
        default:
          resultFile = await _generateCsvReport(orders, filterName, directory, sanitizedFilterName, timestamp);
          break;
      }

      final openResult = await OpenFilex.open(resultFile.path);
      if (openResult.type != ResultType.done) {
        print('Failed to open file: ${openResult.message}');
      }

      print('Report saved to: ${resultFile.path}');
      return resultFile;
    } catch (e, stackTrace) {
      print('Error generating report: $e\n$stackTrace');
      return null;
    }
  }

  static Future<File> _generateCsvReport(
      List<OrderHistory> orders, String filterName, Directory directory,
      String sanitizedFilterName, String timestamp) async {
    final csvData = _buildTableData(orders, filterName);
    final csv = const ListToCsvConverter().convert(csvData);

    final fileName = 'order_report_${sanitizedFilterName}_$timestamp.csv';
    final filePath = '${directory.path}/$fileName';
    print('File path: $filePath');

    final file = File(filePath);
    await file.writeAsString('\uFEFF$csv', encoding: utf8);
    return file;
  }

  static Future<File> _generateExcelReport(
      List<OrderHistory> orders, String filterName, Directory directory,
      String sanitizedFilterName, String timestamp) async {
    final excel = Excel.createExcel();
    final sheet = excel['Order History'];

    final excelData = _buildTableData(orders, filterName);
    for (var i = 0; i < excelData.length; i++) {
      for (var j = 0; j < excelData[i].length; j++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: j, rowIndex: i));
        cell.value = excelData[i][j].toString();
      }
    }

    // Set column widths manually for better readability
    sheet.setColumnWidth(0, 12);  // Order ID
    sheet.setColumnWidth(1, 15);  // Table Number
    sheet.setColumnWidth(2, 25);  // Item Name
    sheet.setColumnWidth(3, 12);  // Quantity
    sheet.setColumnWidth(4, 20);  // Special Note
    sheet.setColumnWidth(5, 15);  // Category
    sheet.setColumnWidth(6, 15);  // Item Count
    sheet.setColumnWidth(7, 15);  // Price
    sheet.setColumnWidth(8, 15);  // Status
    sheet.setColumnWidth(9, 12);  // Date
    sheet.setColumnWidth(10, 12); // Time

    final fileName = 'order_report_${sanitizedFilterName}_$timestamp.xlsx';
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(excel.encode()!);
    return file;
  }

  static Future<File> _generatePdfReport(
      List<OrderHistory> orders, String filterName, Directory directory,
      String sanitizedFilterName, String timestamp) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape, // Use landscape for better table layout
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

  static List<pw.Widget> _buildPdfContent(List<OrderHistory> orders, String filterName) {
    final content = <pw.Widget>[];

    content.add(
      pw.Header(
        level: 0,
        child: pw.Text(
          'ORDER HISTORY REPORT',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
      ),
    );

    content.add(pw.Text('Generated on: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}'));
    content.add(pw.Text('Filter Applied: $filterName'));
    content.add(pw.Text('Total Orders: ${orders.length}'));
    content.add(pw.SizedBox(height: 20));

    final headers = [
      'Order ID', 'Table Number', 'Item Name', 'Quantity', 'Special Note',
      'Category', 'Item Count', 'Price', 'Status', 'Date', 'Time'
    ];
    
    final tableData = orders.expand((order) {
      final orderItemCount = order.orderItems.fold(0, (sum, item) => sum + item.quantity);
      return order.orderItems.map((orderItem) {
        return [
          order.id.toString(),
          order.tableNumber.toString(),
          orderItem.itemName,
          orderItem.quantity.toString(),
          orderItem.specialNote.isNotEmpty ? orderItem.specialNote : 'N/A',
          _getItemCategoryFromItemName(orderItem.itemName),
          orderItemCount.toString(),
          '\$${orderItem.price.toStringAsFixed(2)}',
          order.status.toUpperCase(),
          DateFormat('yyyy-MM-dd').format(order.createdAt),
          DateFormat('HH:mm:ss').format(order.createdAt),
        ];
      });
    }).toList();

    content.add(
      pw.Table.fromTextArray(
        headers: headers,
        data: tableData,
        cellAlignment: pw.Alignment.centerLeft,
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
        cellStyle: const pw.TextStyle(fontSize: 7),
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

  static List<List<dynamic>> _buildTableData(List<OrderHistory> orders, String filterName) {
    final csvData = <List<dynamic>>[];

    // Report header
    csvData.add(['ORDER HISTORY REPORT']);
    csvData.add(['Generated on: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}']);
    csvData.add(['Filter Applied: $filterName']);
    csvData.add(['Total Orders: ${orders.length}']);
    csvData.add([]);

    // Column headers
    csvData.add([
      'Order ID', 'Table Number', 'Item Name', 'Quantity', 'Special Note',
      'Category', 'Item Count', 'Price', 'Status', 'Date', 'Time'
    ]);

    // Order details
    for (var order in orders) {
      final orderItemCount = order.orderItems.fold(0, (sum, item) => sum + item.quantity);
      
      for (var orderItem in order.orderItems) {
        csvData.add([
          order.id,
          order.tableNumber,
          orderItem.itemName,
          orderItem.quantity,
          orderItem.specialNote.isNotEmpty ? orderItem.specialNote : 'N/A',
          _getItemCategoryFromItemName(orderItem.itemName),
          orderItemCount,
          '\$${orderItem.price.toStringAsFixed(2)}',
          order.status.toUpperCase(),
          DateFormat('yyyy-MM-dd').format(order.createdAt),
          DateFormat('HH:mm:ss').format(order.createdAt),
        ]);
      }
      csvData.add(List.filled(11, '-')); // Separator line
    }

    // Summary section
    csvData.add([]);
    csvData.add(['REPORT SUMMARY']);
    csvData.add(['Total Orders: ${orders.length}']);
    
    final totalItems = orders.fold(
        0, (sum, order) => sum + order.orderItems.fold(0, (itemSum, item) => itemSum + item.quantity));
    csvData.add(['Total Items: $totalItems']);

    final totalRevenue = orders.fold(
        0.0, (sum, order) => sum + order.orderItems.fold(0.0, (itemSum, item) => itemSum + (item.price * item.quantity)));
    csvData.add(['Total Revenue: \$${totalRevenue.toStringAsFixed(2)}']);

    final statusCounts = <String, int>{};
    for (var order in orders) {
      statusCounts[order.status] = (statusCounts[order.status] ?? 0) + 1;
    }
    statusCounts.forEach((status, count) {
      csvData.add(['$status Orders: $count']);
    });

    return csvData;
  }

  static String _sanitizeFileName(String name) {
    if (name.isEmpty) return 'report';
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_-]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .substring(0, name.length.clamp(0, 100));
  }

  static String _getItemCategoryFromItemName(String itemName) {
    final lowerName = itemName.toLowerCase();

    if (lowerName.contains('main') || lowerName.contains('entree') || lowerName.contains('steak') || lowerName.contains('pasta')) return 'Main Course';
    if (lowerName.contains('salad')) return 'Salad';
    if (lowerName.contains('soup')) return 'Soup';
    if (lowerName.contains('dessert') || lowerName.contains('cake') || lowerName.contains('ice cream')) return 'Dessert';
    if (lowerName.contains('drink') || lowerName.contains('beverage') || lowerName.contains('coffee') || lowerName.contains('tea') || lowerName.contains('juice')) return 'Beverage';
    if (lowerName.contains('appetizer') || lowerName.contains('starter') || lowerName.contains('snack')) return 'Appetizer';
    if (lowerName.contains('side') || lowerName.contains('accompaniment') || lowerName.contains('fries') || lowerName.contains('rice')) return 'Side Dish';

    return 'Other';
  }

  static Future<bool> _requestStoragePermission() async {
    try {
      if (Platform.isAndroid) {
        final isAndroid13OrAbove = await _isAndroid13OrAbove();
        if (isAndroid13OrAbove) {
          return true;
        } else {
          final status = await Permission.storage.status;
          if (!status.isGranted) {
            final newStatus = await Permission.storage.request();
            if (!newStatus.isGranted) {
              print('Storage permission denied');
              return false;
            }
          }
        }
        return true;
      } else if (Platform.isIOS) {
        return true;
      }
      print('Unsupported platform');
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
      final sdkInt = androidInfo.version.sdkInt;
      print('Detected Android SDK version: $sdkInt');
      return sdkInt >= 33;
    } catch (e) {
      print('Error checking Android version: $e');
      return false;
    }
  }
}