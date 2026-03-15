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
              Colors.blue.withOpacity(0.2),
              Colors.blue.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.blue.withOpacity(0.3),
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
          Colors.white.withOpacity(0.2),
          Colors.white.withOpacity(0.1),
        ],
      ),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white.withOpacity(0.3)),
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
            Colors.red.withOpacity(0.2),
            Colors.red.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red.withOpacity(0.3),
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
            Colors.blue.withOpacity(0.2),
            Colors.blue.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
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
            // Trip Info Card
            _glass(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.withOpacity(0.2),
                              Colors.blue.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.info_outline,
                          color: Colors.blue,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Trip Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Title',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              trip.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.green.withOpacity(0.15),
                              Colors.green.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.green.withOpacity(0.3)),
                        ),
                        child: Text(
                          trip.status,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Icon(Icons.business, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          trip.partnerName,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Icon(Icons.public, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Text(
                        trip.country,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Icon(Icons.date_range, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Text(
                        '${_formatDate(trip.startDate)} - ${_formatDate(trip.endDate)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Icon(Icons.person, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Text(
                        'Created by: ${trip.createdByName}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Balance Card
            _glass(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.green.withOpacity(0.2),
                              Colors.green.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet,
                          color: Colors.green,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Balance',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  StreamBuilder<List<TripTransfer>>(
                    stream: transferService.streamTransfers(trip.id),
                    builder: (context, transferSnapshot) {
                      if (!transferSnapshot.hasData) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
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
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          final expenses = expenseSnapshot.data!;
                          final balances = calculateBalance(transfers, expenses);

                          if (balances.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(
                                child: Text('No balance data'),
                              ),
                            );
                          }

                          return Column(
                            children: balances.entries.map((entry) {
                              final isPositive = entry.value >= 0;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      isPositive
                                          ? Colors.green.withOpacity(0.1)
                                          : Colors.red.withOpacity(0.1),
                                      isPositive
                                          ? Colors.green.withOpacity(0.05)
                                          : Colors.red.withOpacity(0.05),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isPositive
                                        ? Colors.green.withOpacity(0.3)
                                        : Colors.red.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: isPositive
                                                ? Colors.green.withOpacity(0.2)
                                                : Colors.red.withOpacity(0.2),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            isPositive
                                                ? Icons.arrow_upward
                                                : Icons.arrow_downward,
                                            color: isPositive ? Colors.green : Colors.red,
                                            size: 12,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          entry.key,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '${isPositive ? '' : '-'}${_currencyFormatter.format(entry.value.abs())}',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isPositive ? Colors.green : Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),

            // Transactions Section
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
                Colors.purple.withOpacity(0.2),
                Colors.purple.withOpacity(0.1),
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
      child: const Text("View All"),
    ),
  ],
),
                    const SizedBox(height: 16),

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
                                          color: Colors.purple.withOpacity(0.1),
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
                                itemCount: ledger.length,
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
          Colors.white.withOpacity(0.1),
          Colors.white.withOpacity(0.05),
        ],
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: item.isDebit
            ? Colors.green.withOpacity(0.3)
            : Colors.red.withOpacity(0.3),
      ),
    ),
    child: Row(
      children: [
        // Icon
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  item.isDebit
                      ? Colors.green.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2),
                  item.isDebit
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: item.isDebit
                    ? Colors.green.withOpacity(0.3)
                    : Colors.red.withOpacity(0.3),
              ),
            ),
            child: Icon(
              item.isDebit ? Icons.arrow_downward : Icons.arrow_upward,
              color: item.isDebit ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Content - EXPANDED
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                 if (!item.isDebit && item.receiptUrl != null && item.receiptUrl!.isNotEmpty)
  Row(
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
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
      const SizedBox(width: 4),
      const Icon(
        Icons.download,
        size: 12,
        color: Colors.blue,
      ),
    ],
  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 10,
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
                    const SizedBox(width: 8),
                    Container(
                      width: 3,
                      height: 3,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.description!,
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

        const SizedBox(width: 8),

        // Amount and Menu - FIXED WITH FLEX
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Amount Container
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    item.isDebit
                        ? Colors.green.withOpacity(0.15)
                        : Colors.red.withOpacity(0.15),
                    item.isDebit
                        ? Colors.green.withOpacity(0.05)
                        : Colors.red.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: item.isDebit
                      ? Colors.green.withOpacity(0.3)
                      : Colors.red.withOpacity(0.3),
                ),
              ),
              child: Text(
                '${item.isDebit ? '+' : '-'} ${_currencyFormatter.format(item.amount)}',
                style: TextStyle(
                  color: item.isDebit ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 4),
            
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
              icon: const Icon(Icons.more_vert, size: 18),
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

    for (var e in expenses) {
  print("DESC: ${e.description}");
}

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
        build: (context) => [
          /// HEADER
          pw.Row(
  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
  children: [

    pw.Row(
      children: [
        pw.Image(logo, height: 40),
        pw.SizedBox(width: 12),
        pw.Text(
          "TRIP EXPENSE REPORT",
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    ),

    pw.Text(
      DateFormat("dd MMM yyyy").format(DateTime.now()),
    ),

  ],
),

          pw.Divider(),

          /// TRIP INFO
          pw.SizedBox(height: 10),

          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Table(
              columnWidths: {0: const pw.FixedColumnWidth(120)},
              children: [
                _row("Title", trip.title),
                _row("Partner", trip.partnerName),
                _row("Country", trip.country),
                _row("Status", trip.status),
                _row("Created By", trip.createdByName),
                _row(
                  "Trip Date",
                  "${_formatDate(trip.startDate)} - ${_formatDate(trip.endDate)}",
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          /// BALANCE SUMMARY
          pw.Text(
            "Balance Summary",
            style:
                pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),

          pw.SizedBox(height: 8),

          pw.Table.fromTextArray(
            headers: ["Currency", "Balance"],
            headerStyle:
                pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration:
                const pw.BoxDecoration(color: PdfColors.grey200),
            data: balances.entries.map((e) {
              return [
                e.key,
                currencyFormat.format(e.value),
              ];
            }).toList(),
          ),

          pw.SizedBox(height: 25),

          /// TRANSACTION TABLE
          pw.Text(
            "Transactions",
            style:
                pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),

          pw.SizedBox(height: 10),

          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: {
              0: const pw.FixedColumnWidth(60),
              1: const pw.FixedColumnWidth(50),
              2: const pw.FixedColumnWidth(120),
              3: const pw.FixedColumnWidth(120),
              4: const pw.FixedColumnWidth(80),
              5: const pw.FixedColumnWidth(60),
              6: const pw.FixedColumnWidth(60),
            },
            children: [
              /// HEADER
              pw.TableRow(
                decoration:
                    const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _cell("Date", bold: true),
                  _cell("Type", bold: true),
                  _cell("Title", bold: true),
                  _cell("Description", bold: true),
                  _cell("Amount", bold: true),
                  _cell("Currency", bold: true),
                  _cell("Receipt", bold: true),
                ],
              ),

              /// DATA
              ...ledger.map((e) {
                final color =
                    e.isDebit ? PdfColors.green700 : PdfColors.red700;

                return pw.TableRow(
                  children: [
                    _cell(_formatDate(e.date)),
                    _cell(e.type),
                    _cell(e.title),
                    _cell(e.description ?? "-"),
                    _cell(
                      "${e.isDebit ? "+" : "-"}${currencyFormat.format(e.amount)}",
                      color: color,
                    ),
                    _cell(e.currency),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: receiptThumbs.containsKey(e.id)
                          ? pw.Image(receiptThumbs[e.id]!, height: 40)
                          : pw.Text(
                              e.receiptUrl != null &&
                                      e.receiptUrl!.endsWith(".pdf")
                                  ? "PDF"
                                  : "-",
                              style: const pw.TextStyle(fontSize: 8),
                            ),
                    ),
                  ],
                );
              })
            ],
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
              Colors.white.withOpacity(0.3),
              Colors.white.withOpacity(0.15),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.4)),
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

pw.Widget _cell(String text, {bool bold = false, PdfColor? color}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.all(4),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 9,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        color: color,
      ),
    ),
  );
}