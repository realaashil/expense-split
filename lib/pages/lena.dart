import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:expense_split/services/database.dart';
import 'package:expense_split/ui/card/expense_card.dart';

class Lena extends StatefulWidget {
  const Lena({super.key});

  @override
  State<Lena> createState() => _LenaState();
}

class _LenaState extends State<Lena> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _payerEmailController = TextEditingController();
  final _descriptionController = TextEditingController();

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    _amountController.dispose();
    _payerEmailController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _addExpense() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Get current user
        double amount = double.parse(_amountController.text);
        amount = double.parse(amount.toStringAsFixed(2));
        String email = _payerEmailController.text.trim();
        String description = _descriptionController.text.trim();
        Database.addExpense(amount, email, description);

        // Clear controllers
        _amountController.clear();
        _payerEmailController.clear();
        _descriptionController.clear();

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Expense added successfully')),
          );
          Navigator.pop(context); // Close the dialog
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding expense: $e')),
          );
        }
      }
    }
  }

  void _showAddExpenseDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Expense'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixIcon: Icon(Icons.currency_rupee),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an amount';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _payerEmailController,
                  decoration: const InputDecoration(
                    labelText: 'Payer Email',
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter payer email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _addExpense,
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('expenses')
            .where('creatorId', isEqualTo: _auth.currentUser?.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Something went wrong!'));
          }

          final expenses = snapshot.data?.docs ?? [];

          if (expenses.isEmpty) {
            return const Center(
              child: Text('No expenses yet. Add some using the + button.'),
            );
          }

          return ListView.builder(
            itemCount: expenses.length,
            itemBuilder: (ctx, index) {
              final expense = expenses[index].data() as Map<String, dynamic>;
              final amount = expense['amount'] ?? 0.0;
              final payerEmail = expense['payerEmail'] ?? 'Unknown';
              final description = expense['description'] ?? 'No description';
              final status = expense['status'] ?? 'pending';
              bool paid = status == 'paid';

              // Format timestamp if available
              String dateStr = 'Just now';
              if (expense['createdAt'] != null) {
                final timestamp = expense['createdAt'] as Timestamp;
                final date = timestamp.toDate();
                dateStr = DateFormat('MMM d, y').format(date);
              }

              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: ExpenseCard(
                    description: description,
                    dateStr: dateStr,
                    amount: amount,
                    payerEmail: payerEmail,
                    status: status,
                    paid: paid),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddExpenseDialog,
        tooltip: 'Add new expense',
        child: const Icon(Icons.add),
      ),
    );
  }
}
