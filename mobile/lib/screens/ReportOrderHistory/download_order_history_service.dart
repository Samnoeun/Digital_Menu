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
        default:
          // Default to Excel if format is not recognized
          print('Format $format not recognized, generating Excel instead');
          resultFile = await _generateExcelReport(orders, filterName, directory, sanitizedFilterName, timestamp);
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

  static Future<File> _generateExcelReport(
      List<OrderHistory> orders, String filterName, Directory directory,
      String sanitizedFilterName, String timestamp) async {
    final excel = Excel.createExcel();
    final sheet = excel['Order History'];

    // Get the same data structure as the PDF
    final excelData = _buildExcelData(orders, filterName);
    
    // Write data to Excel sheet
    for (var i = 0; i < excelData.length; i++) {
      for (var j = 0; j < excelData[i].length; j++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: j, rowIndex: i));
        cell.value = TextCellValue(excelData[i][j].toString());
      }
    }

    // Set column widths for the new column order
    sheet.setColumnWidth(0, 8);  
    sheet.setColumnWidth(1, 30);  
    sheet.setColumnWidth(2, 12);  
    sheet.setColumnWidth(3, 15);  
    sheet.setColumnWidth(4, 20);  
    sheet.setColumnWidth(5, 15);  

    final fileName = 'order_report_${sanitizedFilterName}_$timestamp.xlsx';
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(excel.encode()!);
    return file;
  }

  static List<List<dynamic>> _buildExcelData(List<OrderHistory> orders, String filterName) {
    final excelData = <List<dynamic>>[];

    // Report header (same as PDF)
    excelData.add(['ORDER HISTORY REPORT']);
    excelData.add(['Generated on: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}']);
    excelData.add(['Filter Applied: $filterName']);
    excelData.add(['Total Orders: ${orders.length}']);
    excelData.add([]);

    // Column headers (same as PDF)
    excelData.add([
      'ID', 'Item Name', 'Quantity', 'Price', 'Category', 'Date'
    ]);

    // Generate simple sequential IDs (same as PDF)
    int idCounter = 1;
    
    // Order details (same as PDF)
    for (var order in orders) {
      for (var orderItem in order.orderItems) {
        excelData.add([
          idCounter++, 
          orderItem.itemName, 
          orderItem.quantity,
          orderItem.price, 
          _getItemCategoryFromItemName(orderItem.itemName), 
          DateFormat('yyyy-MM-dd').format(order.createdAt), 
        ]);
      }
    }

    // Summary section (same as PDF)
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
      List<OrderHistory> orders, String filterName, Directory directory,
      String sanitizedFilterName, String timestamp) async {
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

    // Updated headers with only the requested columns
    final headers = [
      'ID', 'Item Name', 'Quantity', 'Price', 'Category', 'Date'
    ];
    
    // Generate simple sequential IDs
    int idCounter = 1;
    final tableData = orders.expand((order) {
      return order.orderItems.map((orderItem) {
        return [
          (idCounter++).toString(),
          orderItem.itemName,
          orderItem.quantity.toString(),
          '\$${orderItem.price.toStringAsFixed(2)}',
          _getItemCategoryFromItemName(orderItem.itemName),
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