import 'package:flutter/material.dart';
import '../db/db_helper.dart';
import '../models/member.dart';

class SummaryScreen extends StatefulWidget {
  @override
  _SummaryScreenState createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  double _totalMarketExpense = 0;
  double _remainingBalance = 0;
  double _mealRate = 0;
  int _totalMeals = 0;
  double _totalWithdrawal = 0; // New variable for total withdrawal
  List<Member> _membersWithNegativeBalance = [];
  final TextEditingController _managerNotesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _calculateSummary();
  }

  void _calculateSummary() async {
    final db = await DBHelper.instance.database;

    // Calculate total market expense
    final marketResult = await db.rawQuery("SELECT SUM(amount) AS total FROM market");
    _totalMarketExpense = (marketResult.first['total'] as double?) ?? 0.0;

    // Calculate total balance of all members (Total Withdrawal)
    final balanceResult = await db.rawQuery("SELECT SUM(balance) AS total FROM members");
    _totalWithdrawal = (balanceResult.first['total'] as double?) ?? 0.0;

    // Calculate total meals
    final mealResult = await db.rawQuery("SELECT SUM(breakfast + lunch + dinner) AS total FROM meals");
    _totalMeals = (mealResult.first['total'] as int?) ?? 0;

    // Calculate meal rate
    if (_totalMeals > 0) {
      _mealRate = _totalMarketExpense / _totalMeals;
    }

    // Calculate remaining balance
    _remainingBalance = _totalWithdrawal - _totalMarketExpense;

    // Fetch members with negative remaining balance
    final membersResult = await db.query('members');
    List<Member> members = membersResult.map((map) => Member.fromMap(map)).toList();
    _membersWithNegativeBalance = members.where((member) {
      double remainingBalance = member.balance - (_mealRate * member.totalMeals);
      return remainingBalance < 0;
    }).toList();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Summary"),
        backgroundColor: Colors.indigo,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            // First Box: Summary Data
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Summary",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                  SizedBox(height: 10),
                  _buildSummaryItem("Total Withdrawal", "৳${_totalWithdrawal.toStringAsFixed(2)}", Icons.attach_money, Colors.teal), // New item
                  _buildSummaryItem("Total Market Expense", "৳${_totalMarketExpense.toStringAsFixed(2)}", Icons.shopping_cart, Colors.blue),
                  _buildSummaryItem("Remaining Balance", "৳${_remainingBalance.toStringAsFixed(2)}", Icons.account_balance_wallet, Colors.green),
                  _buildSummaryItem("Total Meals", "$_totalMeals", Icons.restaurant, Colors.orange),
                  _buildSummaryItem("Meal Rate Per Meal", "৳${_mealRate.toStringAsFixed(2)}", Icons.monetization_on, Colors.purple),
                ],
              ),
            ),
            SizedBox(height: 20),
            // Second Box: Manager Notes
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Manager Notes",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: _managerNotesController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: "Enter manager notes here...",
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            // Third Box: Members with Negative Balance
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Members with Negative Balance",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                  SizedBox(height: 10),
                  ..._membersWithNegativeBalance.map((member) {
                    double remainingBalance = member.balance - (_mealRate * member.totalMeals);
                    return ListTile(
                      leading: Icon(Icons.person, color: Colors.red),
                      title: Text(member.name),
                      subtitle: Text(
                        "Remaining Balance: ৳${remainingBalance.toStringAsFixed(2)}",
                        style: TextStyle(color: Colors.red),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _calculateSummary,
        backgroundColor: Colors.indigo,
        child: Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, IconData icon, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 30),
          SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}