import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:split_frontend/features/groups/domain/group_model.dart';
import 'package:split_frontend/features/groups/domain/expense_model.dart';
import 'package:split_frontend/features/expenses/domain/expense_models.dart';

class PdfExportService {
  static Future<void> generateAndOpenPdf({
    required GroupModel group,
    required List<ExpenseModel> expenses,
    required List<SettlementModel> settlements,
  }) async {
    final pdf = pw.Document();

    final memberCount = group.members.length;
    var pageFormat = PdfPageFormat.a4.landscape;

    if (memberCount > 6) {
      pageFormat = PdfPageFormat(
        memberCount * 100.0 + 350.0,
        PdfPageFormat.a4.width,
        marginAll: 2 * PdfPageFormat.cm,
      );
    }

    const headerColor = PdfColor.fromInt(0xFFFFF3E0); // Light orange/yellow
    const positiveColor = PdfColor.fromInt(0xFF388E3C);
    const negativeColor = PdfColor.fromInt(0xFFD32F2F);

    final memberIds = group.members.map((m) => m.id).toList();
    final memberNames = group.members.map((m) => m.name).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        build: (context) => [
          _buildHeader(group),
          pw.SizedBox(height: 30),
          _buildExpenseTable(
            expenses,
            memberIds,
            memberNames,
            headerColor,
            positiveColor,
            negativeColor,
          ),
          pw.SizedBox(height: 40),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: _buildSuggestedPayments(settlements, headerColor),
              ),
              pw.SizedBox(width: 40),
              pw.Expanded(
                child: _buildTotalExpenditure(group, expenses, headerColor),
              ),
            ],
          ),
        ],
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File(
      '${output.path}/${group.name.replaceAll(' ', '_')}_expenses.pdf',
    );
    await file.writeAsBytes(await pdf.save());

    await OpenFilex.open(file.path);
  }

  static pw.Widget _buildHeader(GroupModel group) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '${group.name} - ${DateFormat('dd MMMM yyyy').format(DateTime.now())}',
          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Created with Split-Money',
          style: const pw.TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  static pw.Widget _buildExpenseTable(
    List<ExpenseModel> expenses,
    List<String> memberIds,
    List<String> memberNames,
    PdfColor headerColor,
    PdfColor positiveColor,
    PdfColor negativeColor,
  ) {
    final headers = ['Title', 'Amount', 'By', 'Date', ...memberNames];

    final totals = List.generate(memberIds.length, (index) => 0.0);

    return pw.Table(
      border: pw.TableBorder(
        horizontalInside: const pw.BorderSide(
          width: 0.5,
          color: PdfColors.grey300,
        ),
        bottom: const pw.BorderSide(width: 1, color: PdfColors.black),
      ),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1.2),
        2: const pw.FlexColumnWidth(1.2),
        3: const pw.FlexColumnWidth(1.2),
        for (int i = 0; i < memberIds.length; i++)
          i + 4: const pw.FlexColumnWidth(1),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: pw.BoxDecoration(color: headerColor),
          children: headers.map((h) {
            return pw.Padding(
              padding: const pw.EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 4,
              ),
              child: pw.Text(
                h,
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                ),
                textAlign: h == 'Title' || h == 'By'
                    ? pw.TextAlign.left
                    : (h == 'Date' ? pw.TextAlign.center : pw.TextAlign.right),
              ),
            );
          }).toList(),
        ),
        // Data Rows
        ...expenses.map((exp) {
          final baseCells = [
            _buildTextCell(exp.title, pw.TextAlign.left),
            _buildTextCell(
              'Rs. ${exp.amount.toStringAsFixed(2)}',
              pw.TextAlign.right,
            ),
            _buildTextCell(exp.paidByName, pw.TextAlign.left),
            _buildTextCell(
              DateFormat('dd/MM/yy').format(exp.date),
              pw.TextAlign.center,
            ),
          ];

          final memberCells = memberIds.map((id) {
            double balance = 0;
            if (exp.paidById == id) {
              balance += exp.amount;
            }
            final split = exp.splits.where((s) => s.memberId == id).firstOrNull;
            if (split != null) {
              balance -= split.amount;
            }

            final idx = memberIds.indexOf(id);
            totals[idx] += balance;

            if (balance == 0) return _buildTextCell('', pw.TextAlign.right);

            final color = balance > 0 ? positiveColor : negativeColor;
            return _buildTextCell(
              balance.toStringAsFixed(2),
              pw.TextAlign.right,
              color: color,
            );
          }).toList();

          return pw.TableRow(children: [...baseCells, ...memberCells]);
        }),
        // Totals Row
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              top: pw.BorderSide(width: 1, color: PdfColors.black),
            ),
          ),
          children: [
            _buildTextCell('', pw.TextAlign.left),
            _buildTextCell('', pw.TextAlign.left),
            _buildTextCell('', pw.TextAlign.left),
            _buildTextCell('', pw.TextAlign.left),
            ...totals.map((t) {
              if (t == 0) {
                return _buildTextCell('0.00', pw.TextAlign.right, isBold: true);
              }
              final color = t > 0 ? positiveColor : negativeColor;
              final text = t > 0
                  ? 'Rs. ${t.toStringAsFixed(2)}'
                  : '-Rs. ${(-t).toStringAsFixed(2)}';
              return _buildTextCell(
                text,
                pw.TextAlign.right,
                color: color,
                isBold: true,
              );
            }),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildTextCell(
    String text,
    pw.TextAlign align, {
    PdfColor? color,
    bool isBold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 10,
          color: color ?? PdfColors.black,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.Widget _buildSuggestedPayments(
    List<SettlementModel> settlements,
    PdfColor headerColor,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Suggested payments',
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: const pw.TableBorder(
            bottom: pw.BorderSide(width: 1, color: PdfColors.black),
            horizontalInside: pw.BorderSide(
              width: 0.5,
              color: PdfColors.grey300,
            ),
          ),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(2),
            3: const pw.FlexColumnWidth(2),
          },
          children: [
            ...settlements.map((s) {
              return pw.TableRow(
                children: [
                  _buildTextCell(s.fromMemberName, pw.TextAlign.left),
                  _buildTextCell('owes', pw.TextAlign.center),
                  _buildTextCell(s.toMemberName, pw.TextAlign.left),
                  _buildTextCell(
                    'Rs. ${s.amount.toStringAsFixed(2)}',
                    pw.TextAlign.right,
                    isBold: true,
                  ),
                ],
              );
            }),
            if (settlements.isEmpty)
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'No payments suggested.',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ),
                  pw.SizedBox(),
                  pw.SizedBox(),
                  pw.SizedBox(),
                ],
              ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildTotalExpenditure(
    GroupModel group,
    List<ExpenseModel> expenses,
    PdfColor headerColor,
  ) {
    final expenditures = <String, double>{};
    for (final m in group.members) {
      expenditures[m.id] = 0.0;
    }

    double sum = 0.0;
    for (final exp in expenses) {
      for (final split in exp.splits) {
        if (expenditures.containsKey(split.memberId)) {
          expenditures[split.memberId] =
              expenditures[split.memberId]! + split.amount;
          sum += split.amount;
        }
      }
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Total expenditure',
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: const pw.TableBorder(
            bottom: pw.BorderSide(width: 1, color: PdfColors.black),
            horizontalInside: pw.BorderSide(
              width: 0.5,
              color: PdfColors.grey300,
            ),
          ),
          columnWidths: {
            0: const pw.FlexColumnWidth(1),
            1: const pw.FlexColumnWidth(1),
          },
          children: [
            ...group.members.map((m) {
              final amt = expenditures[m.id] ?? 0.0;
              return pw.TableRow(
                children: [
                  _buildTextCell(m.name, pw.TextAlign.left),
                  _buildTextCell(
                    'Rs. ${amt.toStringAsFixed(2)}',
                    pw.TextAlign.right,
                    isBold: true,
                  ),
                ],
              );
            }),
            pw.TableRow(
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  top: pw.BorderSide(width: 1, color: PdfColors.black),
                ),
              ),
              children: [
                _buildTextCell('Sum', pw.TextAlign.left, isBold: true),
                _buildTextCell(
                  'Rs. ${sum.toStringAsFixed(2)}',
                  pw.TextAlign.right,
                  isBold: true,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
