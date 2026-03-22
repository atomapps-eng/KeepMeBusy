import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../models/trip_model.dart';
import 'add_transfer_page.dart';
import '../services/trip_transfer_service.dart';
import '../models/trip_transfer_model.dart';
import 'add_expense_page.dart';
import '../services/trip_expense_service.dart';
import '../models/trip_expense_model.dart';
import '../models/trip_ledger_item.dart';
import 'receipt_viewer_page.dart';
import '../services/trip_service.dart';
import 'create_trip_page.dart';
import '../../../pages/common/app_background_wrapper.dart';
import 'package:intl/intl.dart';
import 'expense_detail_page.dart';
import 'transaction_list_page.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:dio/dio.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:flutter/services.dart';


class TripDetailPage extends StatelessWidget {
  final TripTransferService transferService = TripTransferService();
  final TripExpenseService expenseService = TripExpenseService();
  final TripService tripService = TripService();

  final Trip trip;

  TripDetailPage({
    super.key,
    required this.trip,
  });

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  final NumberFormat _currencyFormatter =
    NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
  title: Row(
    children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue.withValues(alpha:0.2),
              Colors.blue.withValues(alpha:0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.blue.withValues(alpha:0.3),
            width: 1,
          ),
        ),
        child: const Icon(
          Icons.flight_takeoff,
          color: Colors.blue,
          size: 24,
        ),
      ),
      const SizedBox(width: 12),
      const Text(
        'Trip Detail',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  ),
  backgroundColor: Colors.transparent,
  elevation: 0,

  leading: Container(
    margin: const EdgeInsets.only(left: 8),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Colors.white.withValues(alpha:0.2),
          Colors.white.withValues(alpha:0.1),
        ],
      ),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white.withValues(alpha:0.3)),
    ),
    child: IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => Navigator.pop(context),
    ),
  ),

  actions: [

    /// BUTTON EXPORT PDF
    Container(
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.withValues(alpha:0.2),
            Colors.red.withValues(alpha:0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red.withValues(alpha:0.3),
        ),
      ),
      child: IconButton(
        icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
        onPressed: () => _generateEnterprisePdf(context),
      ),
    ),

    /// MENU 3 DOT
    Container(
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withValues(alpha:0.2),
            Colors.blue.withValues(alpha:0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withValues(alpha:0.3),
        ),
      ),
      child: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, color: Colors.blue),
        onSelected: (value) async {

          if (value == 'edit') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CreateTripPage(trip: trip),
              ),
            );
          }

          if (value == 'delete') {
            final confirm = await showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text('Delete Trip'),
                  content: const Text(
                    'Are you sure you want to delete this trip?',
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context, false);
                      },
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.pop(context, true);
                      },
                      child: const Text('Delete'),
                    ),
                  ],
                );
              },
            );

            if (confirm == true) {
              await tripService.deleteTrip(trip.id);
              if (context.mounted) Navigator.pop(context);
            }
          }

        },
        itemBuilder: (context) => const [
          PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit, size: 18, color: Colors.blue),
                SizedBox(width: 8),
                Text('Edit Trip'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete, size: 18, color: Colors.red),
                SizedBox(width: 8),
                Text('Delete Trip'),
              ],
            ),
          ),
        ],
      ),
    ),

  ],
),
      body: AppBackgroundWrapper(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trip Info Card - Compact version
            _glass(
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${trip.partnerName} • ${trip.country}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_formatDate(trip.startDate)} - ${_formatDate(trip.endDate)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.green.withValues(alpha:0.15),
                          Colors.green.withValues(alpha:0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.withValues(alpha:0.3)),
                    ),
                    child: Text(
                      trip.status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Balance Card - Compact horizontal layout
            // Balance Card - Compact horizontal layout with label
_glass(
  Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green.withValues(alpha:0.2),
                  Colors.green.withValues(alpha:0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.account_balance_wallet,
              color: Colors.deepOrange,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Current Balance',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      StreamBuilder<List<TripTransfer>>(
        stream: transferService.streamTransfers(trip.id),
        builder: (context, transferSnapshot) {
          if (!transferSnapshot.hasData) {
            return const SizedBox(
              height: 40,
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final transfers = transferSnapshot.data!;

          return StreamBuilder<List<TripExpense>>(
            stream: expenseService.streamExpenses(trip.id),
            builder: (context, expenseSnapshot) {
              if (!expenseSnapshot.hasData) {
                return const SizedBox(
                  height: 40,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final expenses = expenseSnapshot.data!;
              final balances = calculateBalance(transfers, expenses);

              if (balances.isEmpty) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No balance data',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                );
              }

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: balances.entries.map((entry) {
                    final isPositive = entry.value >= 0;
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            isPositive
                                ? Colors.green.withValues(alpha:0.1)
                                : Colors.red.withValues(alpha:0.1),
                            isPositive
                                ? Colors.green.withValues(alpha:0.05)
                                : Colors.red.withValues(alpha:0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isPositive
                              ? Colors.green.withValues(alpha:0.3)
                              : Colors.red.withValues(alpha:0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isPositive
                                  ? Colors.green.withValues(alpha:0.2)
                                  : Colors.red.withValues(alpha:0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isPositive
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              color: isPositive ? Colors.green : Colors.red,
                              size: 10,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            entry.key,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isPositive
                                  ? Colors.green.withValues(alpha:0.1)
                                  : Colors.red.withValues(alpha:0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${isPositive ? '' : '-'}${_currencyFormatter.format(entry.value.abs())}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isPositive ? Colors.green : Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          );
        },
      ),
    ],
  ),
),

            // Transactions Section - Takes most of the space
            Expanded(
              child: _glass(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.purple.withValues(alpha:0.2),
                                    Colors.purple.withValues(alpha:0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.receipt,
                                color: Colors.purple,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Transactions',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.purple.withValues(alpha:0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: StreamBuilder<List<TripTransfer>>(
                                stream: transferService.streamTransfers(trip.id),
                                builder: (context, transferSnapshot) {
                                  if (!transferSnapshot.hasData) return const Text('0');
                                  final transfers = transferSnapshot.data!;
                                  return StreamBuilder<List<TripExpense>>(
                                    stream: expenseService.streamExpenses(trip.id),
                                    builder: (context, expenseSnapshot) {
                                      if (!expenseSnapshot.hasData) return Text('${transfers.length}');
                                      final expenses = expenseSnapshot.data!;
                                      final total = transfers.length + expenses.length;
                                      return Text(
                                        '$total',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.purple,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),

                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TransactionListPage(trip: trip),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          child: Row(
                            children: const [
                              Text("View All"),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward, size: 16),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Expanded(
                      child: StreamBuilder<List<TripTransfer>>(
                        stream: transferService.streamTransfers(trip.id),
                        builder: (context, transferSnapshot) {
                          if (!transferSnapshot.hasData) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          final transfers = transferSnapshot.data!;

                          return StreamBuilder<List<TripExpense>>(
                            stream: expenseService.streamExpenses(trip.id),
                            builder: (context, expenseSnapshot) {
                              if (!expenseSnapshot.hasData) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(32),
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }

                              final expenses = expenseSnapshot.data!;
                              final ledger = buildLedger(transfers, expenses);

                              if (ledger.isEmpty) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: Colors.purple.withValues(alpha:0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.receipt,
                                          size: 48,
                                          color: Colors.purple,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'No transactions yet',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Tap + to add a transfer or expense',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              return ListView.builder(
                                itemCount: ledger.length > 5 ? 5 : ledger.length,
                                itemBuilder: (context, index) {
                                  final item = ledger[index];
                                  return _buildTransactionItem(context, item);
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) {
              return Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.arrow_downward, color: Colors.green),
                      title: const Text('Add Transfer'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddTransferPage(
                              tripId: trip.id,
                            ),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.arrow_upward, color: Colors.red),
                      title: const Text('Add Expense'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddExpensePage(
                              tripId: trip.id,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

Widget _buildTransactionItem(BuildContext context, TripLedgerItem item) {
  return InkWell(
    onTap: () {
      if (item.type == 'expense') {
        final expense = TripExpense(
          id: item.id,
          date: item.date,
          employeeId: '',
          amount: item.amount,
          currency: item.currency,
          category: item.title,
          description: item.description ?? '',
          receiptUrl: item.receiptUrl ?? '',
          fingerprint: '',
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ExpenseDetailPage(
              tripId: trip.id,
              expense: expense,
            ),
          ),
        );
      }

      if (item.type == 'transfer') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddTransferPage(
              tripId: trip.id,
              transferId: item.id,
            ),
          ),
        );
      }
    },
    child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha:0.1),
            Colors.white.withValues(alpha:0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isDebit
              ? Colors.green.withValues(alpha:0.3)
              : Colors.red.withValues(alpha:0.3),
        ),
      ),
      child: Row(
        children: [
          // Icon with receipt tap
          GestureDetector(
            onTap: () {
              if (!item.isDebit &&
                  item.receiptUrl != null &&
                  item.receiptUrl!.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReceiptViewerPage(
                      imageUrl: item.receiptUrl!,
                    ),
                  ),
                );
              }
            },
            child: Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    item.isDebit
                        ? Colors.green.withValues(alpha:0.2)
                        : Colors.red.withValues(alpha:0.2),
                    item.isDebit
                        ? Colors.green.withValues(alpha:0.1)
                        : Colors.red.withValues(alpha:0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: item.isDebit
                      ? Colors.green.withValues(alpha:0.3)
                      : Colors.red.withValues(alpha:0.3),
                ),
              ),
              child: Icon(
                item.isDebit ? Icons.arrow_downward : Icons.arrow_upward,
                color: item.isDebit ? Colors.green : Colors.red,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Content - Takes remaining space
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!item.isDebit && item.receiptUrl != null && item.receiptUrl!.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(left: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha:0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.receipt, size: 10, color: Colors.blue),
                            SizedBox(width: 2),
                            Text(
                              'Receipt',
                              style: TextStyle(
                                fontSize: 8,
                                color: Colors.blue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 11,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(item.date),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (item.description != null && item.description!.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '• ${item.description!}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Amount
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  item.isDebit
                      ? Colors.green.withValues(alpha:0.15)
                      : Colors.red.withValues(alpha:0.15),
                  item.isDebit
                      ? Colors.green.withValues(alpha:0.05)
                      : Colors.red.withValues(alpha:0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: item.isDebit
                    ? Colors.green.withValues(alpha:0.3)
                    : Colors.red.withValues(alpha:0.3),
              ),
            ),
            child: Text(
              '${item.isDebit ? '+' : '-'} ${_currencyFormatter.format(item.amount)}',
              style: TextStyle(
                color: item.isDebit ? Colors.green : Colors.red,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),

          // Menu Button
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'delete') {
                final confirm = await showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Delete Transaction'),
                    content: const Text(
                      'Are you sure you want to delete this transaction?',
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  if (item.type == 'expense') {
                    await expenseService.deleteExpense(trip.id, item.id);
                  }
                  if (item.type == 'transfer') {
                    await transferService.deleteTransfer(trip.id, item.id);
                  }
                }
              }

              if (value == 'edit') {
                final confirm = await showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Edit Transaction'),
                    content: const Text(
                      'Do you want to edit this transaction?',
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Edit'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  if (item.type == 'expense') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddExpensePage(
                          tripId: trip.id,
                          expenseId: item.id,
                        ),
                      ),
                    );
                  }
                  if (item.type == 'transfer') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddTransferPage(
                          tripId: trip.id,
                          transferId: item.id,
                        ),
                      ),
                    );
                  }
                }
              }
            },
            icon: const Icon(Icons.more_vert, size: 20),
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 16, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 16, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

  Map<String, double> calculateBalance(
    List<TripTransfer> transfers,
    List<TripExpense> expenses,
  ) {
    final Map<String, double> balance = {};

    /// TRANSFERS (DEBIT)
    for (var transfer in transfers) {
      for (var item in transfer.transfers) {
        final currency = item['currency'];
        final amount = (item['amount'] as num).toDouble();
        balance[currency] = (balance[currency] ?? 0) + amount;
      }
    }

    /// EXPENSES (CREDIT)
    for (var expense in expenses) {
      final currency = expense.currency;
      final amount = expense.amount;
      balance[currency] = (balance[currency] ?? 0) - amount;
    }

    return balance;
  }

  List<TripLedgerItem> buildLedger(
    List<TripTransfer> transfers,
    List<TripExpense> expenses,
  ) {
    final List<TripLedgerItem> ledger = [];

    for (var t in transfers) {
      for (var item in t.transfers) {
        ledger.add(
          TripLedgerItem(
            id: t.id,
            type: 'transfer',
            date: t.date,
            title: 'Admin Transfer',
             description: t.note ?? '',
            amount: (item['amount'] as num).toDouble(),
            currency: item['currency'],
            isDebit: true,
          ),
        );
      }
    }

    for (var e in expenses) {
      ledger.add(
        TripLedgerItem(
          id: e.id,
          type: 'expense',
          date: e.date,
          title: e.category,
          description: e.description,
          amount: e.amount,
          currency: e.currency,
          isDebit: false,
          receiptUrl: e.receiptUrl,
          expense: e,
        ),
      );
    }

    ledger.sort((a, b) => b.date.compareTo(a.date));
    return ledger;
  }

 Future<void> _generateEnterprisePdf(BuildContext context) async {
  try {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final transfers = await transferService.getTransfers(trip.id);
    final expenses = await expenseService.getExpenses(trip.id);

    final ledger = buildLedger(transfers, expenses);
    final balances = calculateBalance(transfers, expenses);

    final pdf = pw.Document();
    final dio = Dio();
    final currencyFormat =
        NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 2);

    // Cache thumbnail receipts
    final Map<String, pw.MemoryImage> receiptThumbs = {};
    for (var item in ledger) {
      if (item.receiptUrl != null &&
          item.receiptUrl!.isNotEmpty &&
          !item.receiptUrl!.toLowerCase().endsWith(".pdf")) {
        try {
          final res = await dio.get(
            item.receiptUrl!,
            options: Options(responseType: ResponseType.bytes),
          );
          receiptThumbs[item.id] =
              pw.MemoryImage(Uint8List.fromList(res.data));
        } catch (_) {}
      }
    }

    final logoBytes = await rootBundle.load('assets/images/ATOM_INDO.png');
    final logo = pw.MemoryImage(logoBytes.buffer.asUint8List());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 20),
          child: pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Row(
                    children: [
                      pw.Image(logo, height: 40),
                      pw.SizedBox(width: 12),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            "TRIP EXPENSE REPORT",
                            style: pw.TextStyle(
                              fontSize: 24,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue700,
                            ),
                          ),
                          pw.Text(
                            "Trip ID: ${trip.id.substring(0, 8)}...",
                            style: pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.blue50,
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Text(
                      DateFormat("dd MMM yyyy").format(DateTime.now()),
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue700,
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Divider(color: PdfColors.blue200, thickness: 2),
            ],
          ),
        ),
        footer: (context) => pw.Container(
          margin: const pw.EdgeInsets.only(top: 20),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                "Generated by ATOM System",
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
              ),
              pw.Text(
                "Page ${context.pageNumber} of ${context.pagesCount}",
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
              ),
            ],
          ),
        ),
        build: (context) => [
          /// TRIP INFO CARD
          pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 20),
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.blue200),
              borderRadius: pw.BorderRadius.circular(12),
              color: PdfColors.blue50,
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.all(6),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.blue700,
                        shape: pw.BoxShape.circle,
                      ),
                      child: pw.Text(
                        "✈",
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Text(
                      "Trip Information",
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue700,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 16),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _infoRow("Title", trip.title),
                          _infoRow("Partner", trip.partnerName),
                          _infoRow("Country", trip.country),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 20),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _infoRow("Status", trip.status),
                          _infoRow("Created By", trip.createdByName),
                          _infoRow(
                            "Trip Date",
                            "${_formatDate(trip.startDate)} - ${_formatDate(trip.endDate)}",
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          /// BALANCE SUMMARY CARD
          pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 25),
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.green200),
              borderRadius: pw.BorderRadius.circular(12),
              color: PdfColors.green50,
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.all(6),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.green700,
                        shape: pw.BoxShape.circle,
                      ),
                      child: pw.Text(
                        "💰",
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Text(
                      "Balance Summary",
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green700,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 16),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                  children: balances.entries.map((e) {
                    final isPositive = e.value >= 0;
                    return pw.Expanded(
                      child: pw.Container(
                        margin: const pw.EdgeInsets.symmetric(horizontal: 4),
                        padding: const pw.EdgeInsets.all(12),
                        decoration: pw.BoxDecoration(
                          color: isPositive
                              ? PdfColors.green50
                              : PdfColors.red50,
                          borderRadius: pw.BorderRadius.circular(8),
                          border: pw.Border.all(
                            color: isPositive
                                ? PdfColors.green200
                                : PdfColors.red200,
                          ),
                        ),
                        child: pw.Column(
                          children: [
                            pw.Text(
                              e.key,
                              style: pw.TextStyle(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold,
                                color: isPositive
                                    ? PdfColors.green700
                                    : PdfColors.red700,
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              currencyFormat.format(e.value),
                              style: pw.TextStyle(
                                fontSize: 16,
                                fontWeight: pw.FontWeight.bold,
                                color: isPositive
                                    ? PdfColors.green700
                                    : PdfColors.red700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          /// TRANSACTIONS SECTION
          pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 10),
            child: pw.Row(
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(6),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.purple700,
                    shape: pw.BoxShape.circle,
                  ),
                  child: pw.Text(
                    "📄",
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Text(
                  "Transactions",
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.purple700,
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 10),

          /// TRANSACTION TABLE
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {
               0: const pw.FractionColumnWidth(0.1),   // Date - 10%
      1: const pw.FractionColumnWidth(0.08),  // Type - 8%
      2: const pw.FractionColumnWidth(0.15),  // Title - 15%
      3: const pw.FractionColumnWidth(0.25),  // Description - 25%
      4: const pw.FractionColumnWidth(0.12),  // Amount - 12%
      5: const pw.FractionColumnWidth(0.08),  // Currency - 8%
      6: const pw.FractionColumnWidth(0.12),
              },
              children: [
                /// HEADER
                pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey200,
                  ),
                  children: [
                    _headerCell("Date"),
                    _headerCell("Type"),
                    _headerCell("Title"),
                    _headerCell("Description"),
                    _headerCell("Amount"),
                    _headerCell("Curr"),
                    _headerCell("Receipt"),
                  ],
                ),

                /// DATA
                ...ledger.asMap().entries.map((entry) {
                  final index = entry.key;
                  final e = entry.value;
                  final color =
                      e.isDebit ? PdfColors.green700 : PdfColors.red700;

                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: index.isEven ? PdfColors.white : PdfColors.grey50,
                    ),
                    children: [
                      _cell(_formatDate(e.date)),
                      _cell(e.type, color: color),
                      _cell(e.title),
                      _cell(e.description ?? "-"),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(6),
                        alignment: pw.Alignment.centerRight,
                        child: pw.Text(
                          "${e.isDebit ? "+" : "-"}${currencyFormat.format(e.amount)}",
                          style: pw.TextStyle(
                            color: color,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      _cell(e.currency),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(4),
                        alignment: pw.Alignment.center,
                        child: receiptThumbs.containsKey(e.id)
                            ? pw.Container(
                                width: 40,
                                height: 30,
                                child: pw.Image(
                                  receiptThumbs[e.id]!,
                                  fit: pw.BoxFit.cover,
                                ),
                              )
                            : pw.Container(
                                padding: const pw.EdgeInsets.all(4),
                                decoration: pw.BoxDecoration(
                                  color: e.receiptUrl != null &&
                                          e.receiptUrl!.endsWith(".pdf")
                                      ? PdfColors.red50
                                      : PdfColors.grey100,
                                  borderRadius: pw.BorderRadius.circular(4),
                                ),
                                child: pw.Text(
                                  e.receiptUrl != null &&
                                          e.receiptUrl!.endsWith(".pdf")
                                      ? "PDF"
                                      : "-",
                                  style: pw.TextStyle(
                                    fontSize: 8,
                                    color: e.receiptUrl != null &&
                                            e.receiptUrl!.endsWith(".pdf")
                                        ? PdfColors.red700
                                        : PdfColors.grey600,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                              ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),

          /// SUMMARY FOOTER
          pw.SizedBox(height: 20),
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  "Total Transactions: ${ledger.length}",
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  "Report generated by ATOM System",
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File("${dir.path}/trip_report_${trip.id}.pdf");

    await file.writeAsBytes(await pdf.save());

    Navigator.pop(context);

    await OpenFilex.open(file.path);
  } catch (e) {
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("PDF error: $e")),
    );
  }
}

// Helper methods for PDF styling
pw.Widget _infoRow(String label, String value, {PdfColor? color}) {
  return pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 6),
    child: pw.Row(
      children: [
        pw.Container(
          width: 70,
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 9,
              color: PdfColors.grey600,
            ),
          ),
        ),
        pw.Text(
          ":",
          style: pw.TextStyle(
            fontSize: 9,
            color: PdfColors.grey600,
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    ),
  );
}

pw.Widget _cell(String text, {PdfColor? color, bool bold = false}) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(6),
    alignment: pw.Alignment.centerLeft,
    child: pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 9,
        color: color,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      ),
    ),
  );
}

pw.Widget _headerCell(String text) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(8),
    alignment: pw.Alignment.center,
    child: pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 10,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.blue900,
      ),
    ),
  );
}

}

// =======================================================
// UI HELPERS
// =======================================================
Widget _glass(Widget child) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha:0.3),
              Colors.white.withValues(alpha:0.15),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha:0.4)),
        ),
        child: child,
      ),
    ),
  );
}

pw.TableRow _row(String title, String value) {
  return pw.TableRow(children: [
    pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Text(title,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
    ),
    pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Text(value),
    ),
  ]);
}
