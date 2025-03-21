import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:expense_split/services/database.dart';
import 'package:expense_split/ui/card/expense_card.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class Lena extends StatefulWidget {
  const Lena({super.key});

  @override
  State<Lena> createState() => _LenaState();
}

class _LenaState extends State<Lena> {
  final _formKey = GlobalKey<ShadFormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final Set<String> _selectedUsers = {};

  bool split = false;

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

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
                padding: const EdgeInsets.all(16.0),
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

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _selectedUsers.clear();
    super.dispose();
  }

  Future<void> _addExpense() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Get current user
        double amount = double.parse(_amountController.text);
        amount = double.parse(amount.toStringAsFixed(2));
        if (split) {
          amount =
              double.parse((amount / _selectedUsers.length).toStringAsFixed(2));
        }
        String description = _descriptionController.text.trim();
        for (String email in _selectedUsers) {
          Database.addExpense(amount, email, description);
        }
        _amountController.clear();
        _descriptionController.clear();
        _selectedUsers.clear();
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

  void _showAddExpenseDialog() async {
    var favoriteUsers = await Database.getFavorites();
    var options = <Widget>[];
    favoriteUsers.forEach((k, v) => options.add(
          StatefulBuilder(
            builder: (context, setState) {
              return ShadBadge.outline(
                foregroundColor:
                    _selectedUsers.contains(k) ? Colors.black : Colors.white,
                backgroundColor:
                    _selectedUsers.contains(k) ? Colors.white : Colors.black,
                child: Text(v),
                onPressed: () {
                  setState(() {
                    if (_selectedUsers.contains(k)) {
                      _selectedUsers.remove(k);
                    } else {
                      _selectedUsers.add(k);
                    }
                  });
                },
              );
            },
          ),
        ));
    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Add New Expense'),
          content: ShadForm(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShadInputFormField(
                    controller: _descriptionController,
                    placeholder: Text('Enter Title'),
                    leading: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(LucideIcons.text),
                    ),
                    validator: (value) {
                      if (value.isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  ShadInputFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    placeholder: Text('Enter amount'),
                    leading: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(LucideIcons.indianRupee),
                    ),
                    validator: (value) {
                      if (value.isEmpty) {
                        return 'Please enter an amount';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      if (int.parse(value) < 0 || int.parse(value) > 95000) {
                        return 'Please enter value between 0 to 95,000';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  ShadFormBuilderField(
                    validator: (obj) {
                      if (_selectedUsers.isEmpty) {
                        return 'Select atleast one person';
                      }
                      return null;
                    },
                    builder: (context) => Wrap(
                      spacing: 4.0,
                      children: options,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Row(
                      children: [
                        Expanded(child: Text("Split Evenly?")),
                        const SizedBox(width: 10),
                        ShadSwitchFormField(
                          initialValue: false,
                          onChanged: (v) {
                            split = v;
                          },
                        ),
                      ],
                    ),
                  )
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
  }
}
