import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class ExpenseCard extends StatelessWidget {
  const ExpenseCard({
    super.key,
    required this.description,
    required this.dateStr,
    required this.amount,
    required this.payerEmail,
    required this.status,
    required this.paid,
  });

  final dynamic description;
  final String dateStr;
  final dynamic amount;
  final dynamic payerEmail;
  final dynamic status;
  final bool paid;

  @override
  Widget build(BuildContext context) {
    return ShadCard(
      title: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(description.trim()),
              Text(dateStr, style: const TextStyle(fontSize: 12)),
            ],
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Text('you get ₹${amount.toInt()}',
                  style: TextStyle(color: Colors.green, fontSize: 16)),
            ),
          )
        ],
      ),
      footer: Row(
        children: [
          Text('Payer: $payerEmail'),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(status,
                  style: TextStyle(
                      color: paid ? Colors.green : Colors.red, fontSize: 14)),
            ),
          )
        ],
      ),
      child: SizedBox(
        height: 10,
      ),
    );
  }
}
