import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../models/trip_model.dart';
import '../models/trip_ledger_item.dart';
import '../services/trip_transfer_service.dart';
import '../services/trip_expense_service.dart';
import '../models/trip_transfer_model.dart';
import '../models/trip_expense_model.dart';
import '../../../theme/app_theme.dart';
import '../../../pages/common/app_background_wrapper.dart';
import '../pages/expense_detail_page.dart';

class TransactionListPage extends StatelessWidget {
  final Trip trip;

  final TripTransferService transferService = TripTransferService();
  final TripExpenseService expenseService = TripExpenseService();

  TransactionListPage({super.key, required this.trip});

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Hotel':
        return Colors.blue;
      case 'Meal':
        return Colors.green;
      case 'Transportation':
        return Colors.orange;
      case 'Other':
        return Colors.purple;
      default:
        return AppTheme.primaryColor;
    }
  }

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
                    Colors.purple.withOpacity(0.2),
                    Colors.purple.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.purple.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.receipt_long,
                color: Colors.purple,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'All Transactions',
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
      ),
      body: AppBackgroundWrapper(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder(
          stream: transferService.streamTransfers(trip.id),
          builder: (context, transferSnapshot) {
            if (!transferSnapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
                ),
              );
            }

            final transfers = transferSnapshot.data!;

            return StreamBuilder(
              stream: expenseService.streamExpenses(trip.id),
              builder: (context, expenseSnapshot) {
                if (!expenseSnapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
                    ),
                  );
                }

                final expenses = expenseSnapshot.data!;

                final ledger = buildLedger(transfers, expenses);

                if (ledger.isEmpty) {
                  return Center(
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.receipt_long,
                              size: 48,
                              color: Colors.purple.shade300,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Transactions',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No transactions found for this trip',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    // Header Info
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.2),
                            Colors.white.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.receipt,
                                  size: 14,
                                  color: Colors.purple.shade700,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${ledger.length} ${ledger.length == 1 ? 'transaction' : 'transactions'}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.purple.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Sorted by latest',
                              style: TextStyle(fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Transaction List
                    Expanded(
                      child: ListView.builder(
                        itemCount: ledger.length,
                        itemBuilder: (context, index) {
                          final item = ledger[index];
                          return _buildTransactionCard(context, item);
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildTransactionCard(BuildContext context, TripLedgerItem item) {
    final isDebit = item.isDebit;
    final color = isDebit ? Colors.green : Colors.red;
    final categoryColor = _getCategoryColor(item.title);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
  if (item.type == 'expense' && item.expense != null) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExpenseDetailPage(
          tripId: trip.id,
          expense: item.expense!,
        ),
      ),
    );
  }
},
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.15),
                  Colors.white.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                // Icon with gradient background
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withOpacity(0.2),
                        color.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: color.withOpacity(0.3),
                    ),
                  ),
                  child: Icon(
                    isDebit ? Icons.arrow_downward : Icons.arrow_upward,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),

                // Content
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
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!isDebit && item.receiptUrl != null && item.receiptUrl!.isNotEmpty)
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
                          Text(
                            item.currency,
                            style: TextStyle(
                              fontSize: 11,
                              color: categoryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      if (item.description != null && item.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.description!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                // Amount
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withOpacity(0.15),
                        color.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: color.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    '${isDebit ? '+' : '-'} ${item.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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