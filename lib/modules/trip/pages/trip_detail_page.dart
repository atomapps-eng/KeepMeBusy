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
import '../../../core/widgets/draggable_window.dart';
import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;
import 'transfer_detail_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TripDetailPage extends StatefulWidget {
  final Trip trip;

  const TripDetailPage({
    super.key,
    required this.trip,
  });

  @override
  State<TripDetailPage> createState() => _TripDetailPageState();
}

class _TripDetailPageState extends State<TripDetailPage> {
  final TripTransferService transferService = TripTransferService();
  final TripExpenseService expenseService = TripExpenseService();
  final TripService tripService = TripService();

  bool _isFabOpen = false;
  @override
void dispose() {
  _isFabOpen = false;
  super.dispose();
}

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  final NumberFormat _currencyFormatter =
    NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
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
        onPressed: () async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Export PDF"),
        content: const Text(
          "Do you want to generate and export this trip report as a PDF?",
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Export"),
          ),
        ],
      );
    },
  );

  if (confirm == true) {
    _generateEnterprisePdf(context);
  }
},
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
                builder: (_) => CreateTripPage(trip: widget.trip),
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
              await tripService.deleteTrip(widget.trip.id);
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
      body: Stack(
  children: [

    AppBackgroundWrapper(
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
                          widget.trip.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.trip.partnerName} • ${widget.trip.country}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_formatDate(widget.trip.startDate)} - ${_formatDate(widget.trip.endDate)}',
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
                      widget.trip.status,
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
        stream: transferService.streamTransfers(widget.trip.id),
        builder: (context, transferSnapshot) {
          if (!transferSnapshot.hasData) {
            return const SizedBox(
              height: 40,
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final transfers = transferSnapshot.data!;

          return StreamBuilder<List<TripExpense>>(
            stream: expenseService.streamExpenses(widget.trip.id),
            builder: (context, expenseSnapshot) {
              if (!expenseSnapshot.hasData) {
                return const SizedBox(
                  height: 40,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final expenses = expenseSnapshot.data!;
              final balances = calculateBalance(transfers, expenses);
              final ledger = buildLedger(transfers, expenses);

              


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
                                stream: transferService.streamTransfers(widget.trip.id),
                                builder: (context, transferSnapshot) {
                                  if (!transferSnapshot.hasData) return const Text('0');
                                  final transfers = transferSnapshot.data!;
                                  return StreamBuilder<List<TripExpense>>(
                                    stream: expenseService.streamExpenses(widget.trip.id),
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
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    if (isDesktop) {
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.transparent,
        builder: (context) {
          return DraggableResizableWindow(
            title: "All Transactions",
            headerColor: Colors.purple,
            child: TransactionListPage(trip: widget.trip),
          );
        },
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TransactionListPage(trip: widget.trip),
        ),
      );
    }
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
                        stream: transferService.streamTransfers(widget.trip.id),
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
                            stream: expenseService.streamExpenses(widget.trip.id),
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
          /// 🔥 OVERLAY BLUR + BLOCK TAP
    if (_isFabOpen)
      Positioned.fill(
        child: Stack(
  children: [

    /// BLOCK BACKGROUND (TIDAK TEMBUS)
    ModalBarrier(
      dismissible: false,
      color: Colors.black.withOpacity(0.2),
    ),

    /// BLUR
    BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
      child: Container(color: Colors.transparent),
    ),

    /// TAP CLOSE (INI SEKARANG AKAN WORK)
    GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() {
          _isFabOpen = false;
        });
      },
      child: Container(color: Colors.transparent),
    ),
  ],
)
      ),
  ],
    ),


      
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

floatingActionButton: Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.end,
  children: [

    /// 🔥 ADD TRANSFER
    _buildAnimatedFabItem(
      index: 0,
      child: FloatingActionButton.extended(
        heroTag: "transfer",
        backgroundColor: Colors.green,
        icon: const Icon(Icons.arrow_downward, size: 18),
        label: const Text("Add Transfer"),
        onPressed: () async {
          setState(() => _isFabOpen = false);
          await Future.delayed(const Duration(milliseconds: 200));

          final isDesktop = MediaQuery.of(context).size.width >= 900;

          if (isDesktop) {
            showDialog(
              context: context,
              barrierDismissible: false,
              barrierColor: Colors.transparent,
              builder: (context) {
                return DraggableResizableWindow(
                  title: "Add Transfer",
                  headerColor: Colors.green,
                  child: AddTransferPage(
                    tripId: widget.trip.id,
                  ),
                );
              },
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddTransferPage(
                  tripId: widget.trip.id,
                ),
              ),
            );
          }
        },
      ),
    ),

    const SizedBox(height: 10),

    /// 🔥 ADD EXPENSE
    _buildAnimatedFabItem(
      index: 1,
      child: FloatingActionButton.extended(
        heroTag: "expense",
        backgroundColor: Colors.red,
        icon: const Icon(Icons.arrow_upward, size: 18),
        label: const Text("Add Expense"),
        onPressed: () async {
          setState(() => _isFabOpen = false);
          await Future.delayed(const Duration(milliseconds: 200));

          final isDesktop = MediaQuery.of(context).size.width >= 900;

          if (isDesktop) {
            showDialog(
              context: context,
              barrierDismissible: false,
              barrierColor: Colors.transparent,
              builder: (context) {
                return DraggableResizableWindow(
                  title: "Add Expense",
                  headerColor: Colors.red,
                  child: AddExpensePage(
                    tripId: widget.trip.id,
                  ),
                );
              },
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddExpensePage(
                  tripId: widget.trip.id,
                ),
              ),
            );
          }
        },
      ),
    ),

    const SizedBox(height: 10),

    /// 🔥 MAIN FAB (TOGGLE)
    FloatingActionButton(
      heroTag: "main_fab",
      backgroundColor: Colors.blue,
      child: Icon(_isFabOpen ? Icons.close : Icons.add),
      onPressed: () {
        setState(() {
          _isFabOpen = !_isFabOpen;
        });
      },
    ),
  ],
),
    );
  }

  final Duration _fabAnimDuration = const Duration(milliseconds: 220);
final Curve _fabAnimCurve = Curves.easeOut;

Widget _buildAnimatedFabItem({
  required int index,
  required Widget child,
}) {
  final delay = index * 50;

  return IgnorePointer(
  ignoring: !_isFabOpen,
  child: AnimatedOpacity(
    duration: _fabAnimDuration,
    curve: _fabAnimCurve,
    opacity: _isFabOpen ? 1 : 0,
    child: AnimatedSlide(
      duration: _fabAnimDuration,
      curve: _fabAnimCurve,
      offset: _isFabOpen
          ? Offset.zero
          : Offset(0, 0.3 + (0.1 * index)),
      child: child,
    ),
  ),
);
}

Widget _buildTransactionItem(BuildContext context, TripLedgerItem item) {
  return InkWell(
    onTap: () {
      if (item.type == 'expense') {
  final expense = TripExpense(
    id: item.id,
    date: item.date,
    employeeId: FirebaseAuth.instance.currentUser?.uid ?? '',
    amount: item.amount,
    currency: item.currency,
    category: item.title,
    description: item.description ?? '',
    receiptUrl: item.receiptUrl ?? '',
    fingerprint: '',
  );

  final isDesktop = MediaQuery.of(context).size.width >= 900;

  if (isDesktop) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (context) {
        return DraggableResizableWindow(
          title: "Expense Detail",
          headerColor: Colors.red,
          child: ExpenseDetailPage(
            tripId: widget.trip.id,
            expense: expense,
          ),
        );
      },
    );
  } else {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExpenseDetailPage(
          tripId: widget.trip.id,
          expense: expense,
        ),
      ),
    );
  }
}

if (item.type == 'transfer') {
  final isDesktop = MediaQuery.of(context).size.width >= 900;

  /// 🔥 ANCHOR: ambil object transfer dari service
  transferService.getTransfer(widget.trip.id, item.id).then((doc) {
    if (doc == null) return;

    if (isDesktop) {
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.transparent,
        builder: (context) {
          return DraggableResizableWindow(
            title: "Transfer Detail",
            headerColor: Colors.green,
            child: TransferDetailPage(
              tripId: widget.trip.id,
              transfer: doc,
            ),
          );
        },
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TransferDetailPage(
            tripId: widget.trip.id,
            transfer: doc,
          ),
        ),
      );
    }
  });
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
                    await expenseService.deleteExpense(widget.trip.id, item.id);
                  }
                  if (item.type == 'transfer') {
                    await transferService.deleteTransfer(widget.trip.id, item.id);
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
                          tripId: widget.trip.id,
                          expenseId: item.id,
                        ),
                      ),
                    );
                  }
                  if (item.type == 'transfer') {
  final isDesktop = MediaQuery.of(context).size.width >= 900;

  if (isDesktop) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (context) {
        return DraggableResizableWindow(
          title: "Edit Transfer",
          headerColor: Colors.green,
          child: AddTransferPage(
            tripId: widget.trip.id,
            transferId: item.id,
          ),
        );
      },
    );
  } else {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransferPage(
          tripId: widget.trip.id,
          transferId: item.id,
        ),
      ),
    );
  }
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
        final currency = item['currency'] ?? 'UNKNOWN';
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
  double progress = 0;
  Function(void Function())? updateDialog;
  try {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
  return StatefulBuilder(
    builder: (context, setStateDialog) {

      updateDialog = setStateDialog;

      return Center(
  child: ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// TITLE (kecil & clean)
            const Text(
              "Exporting PDF",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 12),

            /// PROGRESS BAR
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
              ),
            ),

            const SizedBox(height: 8),

            /// PERCENT TEXT (kanan bawah)
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                "${(progress * 100).toStringAsFixed(0)}%",
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);
    },
  );
},
    );

    final transfers = await transferService.getTransfers(widget.trip.id);
    final expenses = await expenseService.getExpenses(widget.trip.id);

    final ledger = buildLedger(transfers, expenses);
    final balances = calculateBalance(transfers, expenses);

    final dio = Dio();
  dio.options.connectTimeout = const Duration(seconds: 10);
dio.options.receiveTimeout = const Duration(seconds: 10);
    // =====================
// ATTACHMENT_LIST START
// =====================
final List<Map<String, dynamic>> attachments = [];

for (var e in ledger) {
  if (e.receiptUrl != null && e.receiptUrl!.isNotEmpty) {
    attachments.add({
      "id": e.id,
      "url": e.receiptUrl!,
      "date": e.date,
      "amount": e.amount,
      "currency": e.currency,
      "isPdf": e.receiptUrl!.toLowerCase().endsWith(".pdf"),
    });
  }
}


// =====================
// ATTACHMENT_LIST END
// =====================

// ==========================
// ATTACHMENT_DOWNLOAD START
// ==========================
final Map<String, Uint8List> attachmentBytes = {};

int i = 0;

int total = attachments.length;

if (total == 0) {
  progress = 1;
  if (updateDialog != null) updateDialog!(() {});
} else {
  int i = 0;

  for (var att in attachments) {
    try {
      final res = await dio.get(
        att["url"],
        options: Options(responseType: ResponseType.bytes),
      );

      attachmentBytes[att["id"]] = Uint8List.fromList(res.data);

    } catch (e) {
    }

    i++;
    progress = i / total;

    if (updateDialog != null) {
      updateDialog!(() {});
    }
  }
}

// ==========================
// ATTACHMENT_DOWNLOAD END
// ==========================

    final pdf = pw.Document();
    final currencyFormat =
        NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0);

    // Cache thumbnail receipts
   final Map<String, pw.MemoryImage> receiptThumbs = {};

bool isValidImage(Uint8List bytes) {
  if (bytes.length < 4) return false;

  // JPG: FF D8
  if (bytes[0] == 0xFF && bytes[1] == 0xD8) return true;

  // PNG: 89 50 4E 47
  if (bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47) return true;

  return false;
}

attachmentBytes.forEach((id, bytes) {
  if (isValidImage(bytes)) {
    receiptThumbs[id] = pw.MemoryImage(bytes);
  }
});
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
                            "Trip ID: ${widget.trip.id.substring(0, 8)}...",
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
                          _infoRow("Title", widget.trip.title),
                          _infoRow("Partner", widget.trip.partnerName),
                          _infoRow("Country", widget.trip.country),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 20),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _infoRow("Status", widget.trip.status),
                          _infoRow("Created By", widget.trip.createdByName),
                          _infoRow(
                            "Trip Date",
                            "${_formatDate(widget.trip.startDate)} - ${_formatDate(widget.trip.endDate)}",
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
          pw.Table.fromTextArray(
  border: pw.TableBorder.all(color: PdfColors.grey300),

  headerStyle: pw.TextStyle(
    fontSize: 10,
    fontWeight: pw.FontWeight.bold,
    color: PdfColors.blue900,
  ),

  headerDecoration: const pw.BoxDecoration(
    color: PdfColors.grey200,
  ),

  cellStyle: const pw.TextStyle(
    fontSize: 9,
  ),

  cellAlignments: {
    0: pw.Alignment.centerLeft,
    1: pw.Alignment.centerLeft,
    2: pw.Alignment.centerLeft,
    3: pw.Alignment.centerLeft,
    4: pw.Alignment.centerRight,
    5: pw.Alignment.center,
  },

  columnWidths: {
    0: const pw.FractionColumnWidth(0.12),
    1: const pw.FractionColumnWidth(0.10),
    2: const pw.FractionColumnWidth(0.18),
    3: const pw.FractionColumnWidth(0.30),
    4: const pw.FractionColumnWidth(0.15),
    5: const pw.FractionColumnWidth(0.10),
  },

  headers: [
    "Date",
    "Type",
    "Title",
    "Description",
    "Amount",
    "Curr",
  ],

  data: ledger.map((e) {
    final amountText =
        "${e.isDebit ? "+" : "-"}${currencyFormat.format(e.amount)}";

    return [
      _formatDate(e.date),
      e.type,
      e.title,
      e.description ?? "-",
      amountText,
      e.currency,
    ];
  }).toList(),
),

          // ==========================
// ATTACHMENT INLINE START
// ==========================

pw.SizedBox(height: 20),

pw.Text(
  "Attachments",
  style: pw.TextStyle(
    fontSize: 14,
    fontWeight: pw.FontWeight.bold,
  ),
),

pw.SizedBox(height: 10),

pw.Wrap(
  spacing: 10,
  runSpacing: 10,
  children: [
    ...attachments.map((att) {
      final bytes = attachmentBytes[att["id"]];

      return pw.Container(
        width: 120,
        padding: const pw.EdgeInsets.all(6),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
  crossAxisAlignment: pw.CrossAxisAlignment.start,
  children: [
    pw.Container(
      height: 80,
      width: double.infinity,
      alignment: pw.Alignment.center,
      color: PdfColors.grey100,
      child: att["isPdf"]
          ? pw.UrlLink(
              destination: att["url"],
              child: pw.Text(
                "Open PDF",
                style: pw.TextStyle(
                  color: PdfColors.red,
                  decoration: pw.TextDecoration.underline,
                ),
              ),
            )
          : (bytes != null
              ? pw.Image(
                  pw.MemoryImage(bytes),
                  fit: pw.BoxFit.contain,
                )
              : pw.Text("-")),
    ),

    pw.SizedBox(height: 4),

    pw.Text(
      _formatDate(att["date"]),
      style: pw.TextStyle(fontSize: 8),
    ),

    pw.Text(
      currencyFormat.format(att["amount"]),
      style: pw.TextStyle(
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
      ),
    ),

    pw.SizedBox(height: 4),

    pw.UrlLink(
      destination: att["url"],
      child: pw.Text(
        "Download",
        style: pw.TextStyle(
          fontSize: 8,
          color: PdfColors.blue,
          decoration: pw.TextDecoration.underline,
        ),
      ),
    ),
  ],
)
      );
    }).toList(),
  ],
),

// ==========================
// ATTACHMENT INLINE END
// ==========================

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


final pdfBytes = await pdf.save();

final tripDate =
    "${widget.trip.startDate.day}-${widget.trip.startDate.month}-${widget.trip.startDate.year}";
final fileName = "${widget.trip.country},$tripDate.pdf";

if (kIsWeb) {
  final blob = html.Blob([pdfBytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);

  final anchor = html.AnchorElement(href: url)
    ..setAttribute("download", fileName)
    ..click();

  html.Url.revokeObjectUrl(url);

  Navigator.pop(context);
} else {
  Directory dir;

  if (defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS) {
    dir = Directory.systemTemp;
  } else {
    dir = await getTemporaryDirectory();
  }

  final file = File("${dir.path}/$fileName");

  await file.writeAsBytes(pdfBytes);

  Navigator.pop(context);

  await OpenFilex.open(file.path);
}
    
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
