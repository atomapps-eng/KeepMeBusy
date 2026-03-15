import 'package:flutter/material.dart';
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

class TripDetailPage extends StatelessWidget {

  final TripTransferService transferService = TripTransferService();
  final TripExpenseService expenseService = TripExpenseService();
  final TripService tripService = TripService();

  final Trip trip;

  TripDetailPage({
    super.key,
    required this.trip,
  });

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
  title: const Text('Trip Detail'),
  actions: [

    PopupMenuButton<String>(
      onSelected: (value) async {

        if (value == 'edit') {

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreateTripPage(
                trip: trip,
              ),
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
                actions: [

                  TextButton(
                    onPressed: () {
                      Navigator.pop(context, false);
                    },
                    child: const Text('Cancel'),
                  ),

                  TextButton(
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

            Navigator.pop(context);

          }

        }

      },

      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Text('Edit Trip'),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Text('Delete Trip'),
        ),
      ],
    ),

  ],
),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(
              trip.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text('${trip.partnerName} • ${trip.country}'),

            const SizedBox(height: 8),

            Text(
              '${trip.startDate} - ${trip.endDate}',
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 30),

            const Text(
              'Transactions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
  child: StreamBuilder<List<TripTransfer>>(
    stream: transferService.streamTransfers(trip.id),
    builder: (context, transferSnapshot) {

      if (!transferSnapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }

      final transfers = transferSnapshot.data!;

      return StreamBuilder<List<TripExpense>>(
        stream: expenseService.streamExpenses(trip.id),
        builder: (context, expenseSnapshot) {

          if (!expenseSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final expenses = expenseSnapshot.data!;

          final ledger = buildLedger(transfers, expenses);
          final balances = calculateBalance(transfers, expenses);

          if (ledger.isEmpty) {
            return const Center(child: Text('No transactions yet'));
          }

          return Column(
            children: [

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const Text(
                      'Balance',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    ...balances.entries.map((entry) {
                      return Text(
                        '${entry.key} ${entry.value}',
                        style: const TextStyle(fontSize: 16),
                      );
                    }),

                  ],
                ),
              ),

              Expanded(
                child: ListView.builder(
                  itemCount: ledger.length,
                  itemBuilder: (context, index) {

                    final item = ledger[index];

 return ListTile(

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

  leading: Icon(
    item.isDebit
        ? Icons.arrow_downward
        : Icons.arrow_upward,
    color: item.isDebit
        ? Colors.green
        : Colors.red,
  ),

  title: Text(item.title),

  subtitle: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [

    Text(
      "${item.date.year}-${item.date.month.toString().padLeft(2,'0')}-${item.date.day.toString().padLeft(2,'0')}",
      style: const TextStyle(
        fontSize: 12,
        color: Colors.grey,
      ),
    ),

    if (item.description != null && item.description!.isNotEmpty)
      Text(item.description!),

  ],
),

  trailing: Row(
    mainAxisSize: MainAxisSize.min,
    children: [

      Text(
        '${item.isDebit ? '+' : '-'} ${item.amount} ${item.currency}',
        style: TextStyle(
          color: item.isDebit ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),

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

  itemBuilder: (context) => const [

    PopupMenuItem(
      value: 'edit',
      child: Text('Edit'),
    ),

    PopupMenuItem(
      value: 'delete',
      child: Text('Delete'),
    ),

  ],
)

    ],
  ),
);

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

          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
  onPressed: () {

    showModalBottomSheet(
      context: context,
      builder: (context) {

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              ListTile(
                leading: const Icon(Icons.arrow_downward),
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
                leading: const Icon(Icons.arrow_upward),
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
  child: const Icon(Icons.add),
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
    ),
  );

}

  ledger.sort((a,b) => b.date.compareTo(a.date));

  return ledger;
}

}