import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class Dena extends StatefulWidget {
  const Dena({super.key});

  @override
  State<Dena> createState() => _DenaState();
}

class _DenaState extends State<Dena> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<void> _markAsPaid(String expenseId) async {
    try {
      await _firestore.collection('expenses').doc(expenseId).update({
        'status': 'paid',
        'paidAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Marked as paid!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _initiateUpiPayment(Map<String, dynamic> expense) async {
    String? vpa = expense['creatorVpa'];

    if (vpa == null || vpa.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment not available: Missing UPI ID'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final amount = expense['amount']?.toString() ?? '0';
    final description = expense['description'] ?? 'Expense Payment';
    final payeeName =
        expense['creatorName']?.toString().split('@')[0] ?? 'Recipient';

    // Create UPI URL
    final upiUrl = 'upi://pay?pa=$vpa&pn=$payeeName&am=$amount&tn=$description';

    try {
      final uri = Uri.parse(upiUrl);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch payment app: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('expenses')
            .where('payerEmail', isEqualTo: _auth.currentUser?.email)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final expenses = snapshot.data?.docs ?? [];

          if (expenses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 80,
                    color: theme.colorScheme.primary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'You don\'t owe money to anyone!',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'When someone adds an expense for you, it will appear here',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // Sort expenses - unpaid first, then by date
          final sortedExpenses = [...expenses];
          sortedExpenses.sort((a, b) {
            final aStatus =
                (a.data() as Map<String, dynamic>)['status'] ?? 'pending';
            final bStatus =
                (b.data() as Map<String, dynamic>)['status'] ?? 'pending';

            // First sort by status (pending before paid)
            if (aStatus != bStatus) {
              return aStatus == 'pending' ? -1 : 1;
            }

            // Then sort by date (newest first)
            final aDate =
                (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
            final bDate =
                (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;

            if (aDate == null) return -1;
            if (bDate == null) return 1;

            return bDate.compareTo(aDate);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedExpenses.length,
            itemBuilder: (ctx, index) {
              final expenseDoc = sortedExpenses[index];
              final expense = expenseDoc.data() as Map<String, dynamic>;
              final amount = expense['amount'] ?? 0.0;
              final creatorEmail = expense['creatorEmail'] ?? 'Unknown';
              final description = expense['description'] ?? 'No description';
              final status = expense['status'] ?? 'pending';
              final isPaid = status == 'paid';

              // Format timestamp if available
              String dateStr = 'Just now';
              if (expense['createdAt'] != null) {
                final timestamp = expense['createdAt'] as Timestamp;
                final date = timestamp.toDate();
                dateStr = DateFormat('MMM d, y').format(date);
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isPaid
                        ? theme.colorScheme.primary.withValues(alpha: 0.3)
                        : theme.colorScheme.error.withValues(alpha: 0.3),
                    width: 1.0,
                  ),
                ),
                child: Column(
                  children: [
                    // Colored header
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      color: isPaid
                          ? theme.colorScheme.primary.withValues(alpha: 0.1)
                          : theme.colorScheme.error.withValues(alpha: 0.1),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: isPaid
                                ? theme.colorScheme.primary
                                : theme.colorScheme.error,
                            foregroundColor: Colors.white,
                            child: Text(
                              '₹${amount.toInt()}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'To: $creatorEmail',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  description,
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Chip(
                            label: Text(isPaid ? 'PAID' : 'PENDING'),
                            backgroundColor: isPaid
                                ? theme.colorScheme.primary
                                    .withValues(alpha: 0.2)
                                : theme.colorScheme.error
                                    .withValues(alpha: 0.2),
                            labelStyle: TextStyle(
                              color: isPaid
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.error,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),

                    // Date row
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            dateStr,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Action buttons
                    if (!isPaid)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _markAsPaid(expenseDoc.id),
                                icon: const Icon(Icons.check_circle),
                                label: const Text('MARK AS PAID'),
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () => _initiateUpiPayment(expense),
                                icon: const Icon(Icons.payment),
                                label: const Text('PAY NOW'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
