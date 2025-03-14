import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

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

  Future<String> _getVpa() async {
    final user = _auth.currentUser;
    if (user == null) return '';
    final doc = await _firestore.collection('users').doc(user.uid).get();
    print(user.uid);
    final data = doc.data() as Map<String, dynamic>;
    return data['vpa'] ?? '';
  }

  Future<void> _addExpense() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Get current user
        final user = _auth.currentUser;
        final vpa = await _getVpa();
        if (user == null) return;

        // Add expense to Firestore
        await _firestore.collection('expenses').add({
          'amount': double.parse(_amountController.text),
          'payerEmail': _payerEmailController.text.trim(),
          'creatorId': user.uid,
          'creatorEmail': user.email,
          'description': _descriptionController.text,
          'creatorVpa': vpa,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });

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

              // Format timestamp if available
              String dateStr = 'Just now';
              if (expense['createdAt'] != null) {
                final timestamp = expense['createdAt'] as Timestamp;
                final date = timestamp.toDate();
                dateStr = DateFormat('MMM d, y').format(date);
              }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 3,
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text('₹${amount.toInt()}'),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  title: Text('From: $payerEmail'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(description),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(dateStr, style: const TextStyle(fontSize: 12)),
                          const Spacer(),
                          Chip(
                            label: Text(status),
                            backgroundColor: status == 'pending'
                                ? Colors.orange.shade100
                                : Colors.green.shade100,
                            labelStyle: TextStyle(
                              color: status == 'pending'
                                  ? Colors.orange.shade800
                                  : Colors.green.shade800,
                              fontSize: 12,
                            ),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddExpenseDialog,
        child: const Icon(Icons.add),
        tooltip: 'Add new expense',
      ),
    );
  }
}
