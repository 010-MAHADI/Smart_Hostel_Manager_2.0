import 'package:flutter/material.dart';
import '../db/db_helper.dart';
import '../models/member.dart';
import '../models/meal.dart';
import 'package:sqflite/sqflite.dart';

class MealScreen extends StatefulWidget {
  @override
  _MealScreenState createState() => _MealScreenState();
}

class _MealScreenState extends State<MealScreen> {
  List<Member> _members = [];
  List<Meal> _previousMeals = [];
  Map<int, Map<String, bool>> _mealData = {};
  String _selectedDate = DateTime.now().toIso8601String().split("T")[0];
  String _selectedMealType = 'Breakfast';
  bool _guestMeal = false;
  List<int> _suggestedMembers = [];
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadMembers();
    _loadPreviousMeals();
  }

  void _loadMembers() async {
    final db = await DBHelper.instance.database;
    final result = await db.query('members');
    final List<Member> members = result.map((e) => Member.fromMap(e)).toList();

    setState(() {
      _members = members;
      for (var member in members) {
        _mealData[member.id!] = {
          'breakfast': false,
          'lunch': false,
          'dinner': false
        };
      }
      _suggestedMembers = members.map((member) => member.id!).toList();
    });
  }

  void _loadPreviousMeals() async {
    final db = await DBHelper.instance.database;
    final result = await db.query('meals', orderBy: 'date DESC', limit: 3);
    final List<Meal> meals = result.map((e) => Meal.fromMap(e)).toList();

    setState(() {
      _previousMeals = meals;
    });
  }

  void _toggleMeal(int memberId, String mealType) {
    setState(() {
      _mealData[memberId]![mealType] = !_mealData[memberId]![mealType]!;
    });
  }

  void _updateMealStatusBasedOnPreviousMeal(String newMealType) {
    setState(() {
      for (var member in _members) {
        if (newMealType == 'lunch') {
          _mealData[member.id!]!['lunch'] = _mealData[member.id!]!['breakfast']!;
        } else if (newMealType == 'dinner') {
          _mealData[member.id!]!['dinner'] = _mealData[member.id!]!['lunch']!;
        } else if (newMealType == 'breakfast') {
          _mealData[member.id!]!['breakfast'] = _mealData[member.id!]!['dinner']!;
        }
      }
    });
  }

  void _saveMeals() async {
    final db = await DBHelper.instance.database;

    for (var member in _members) {
      int breakfast = _mealData[member.id]!['breakfast']! ? 1 : 0;
      int lunch = _mealData[member.id]!['lunch']! ? 1 : 0;
      int dinner = _mealData[member.id]!['dinner']! ? 1 : 0;
      int totalMeals = breakfast + lunch + dinner;

      await db.insert(
        'meals',
        {
          'member_id': member.id,
          'date': _selectedDate,
          'breakfast': breakfast,
          'lunch': lunch,
          'dinner': dinner,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      member.totalMeals += totalMeals;
      double mealRate = await _getMealRate();
      member.balance -= mealRate * totalMeals;
      await db.update('members', member.toMap(),
          where: 'id = ?', whereArgs: [member.id]);
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Meals saved!")));
    _loadPreviousMeals();
    _updateSuggestedMembers();
    _switchMealType();
  }

  void _updateSuggestedMembers() {
    setState(() {
      _suggestedMembers = _members
          .where((member) => _mealData[member.id]![_selectedMealType.toLowerCase()]!)
          .map((member) => member.id!)
          .toList();
    });
  }

  void _switchMealType() {
    setState(() {
      if (_selectedMealType == 'Breakfast') {
        _selectedMealType = 'Lunch';
      } else if (_selectedMealType == 'Lunch') {
        _selectedMealType = 'Dinner';
      } else if (_selectedMealType == 'Dinner') {
        _selectedMealType = 'Breakfast';
      }
    });
  }

  Future<double> _getMealRate() async {
    final db = await DBHelper.instance.database;
    final marketResult =
    await db.rawQuery("SELECT SUM(amount) AS total FROM market");
    double totalMarketExpense = (marketResult.first['total'] as double?) ?? 0.0;
    final mealResult = await db
        .rawQuery("SELECT SUM(breakfast + lunch + dinner) AS total FROM meals");
    int totalMeals = (mealResult.first['total'] as int?) ?? 0;
    return totalMeals > 0 ? totalMarketExpense / totalMeals : 0.0;
  }

  int _getMealCount(String mealType) {
    int count = 0;
    for (var meal in _previousMeals) {
      if (mealType == 'breakfast') {
        count += meal.breakfast;
      } else if (mealType == 'lunch') {
        count += meal.lunch;
      } else if (mealType == 'dinner') {
        count += meal.dinner;
      }
    }
    return count;
  }

  Widget _buildMealChart() {
    return Card(
      margin: EdgeInsets.all(16.0),
      elevation: 10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            DataColumn(label: Text('Member')),
            DataColumn(label: Text('Sun\nB')),
            DataColumn(label: Text('Sun\nL')),
            DataColumn(label: Text('Sun\nD')),
            DataColumn(label: Text('Mon\nB')),
            DataColumn(label: Text('Mon\nL')),
            DataColumn(label: Text('Mon\nD')),
          ],
          rows: _members.map((member) {
            return DataRow(
              cells: [
                DataCell(Text(member.name)),
                DataCell(_buildMealCell(member.id!, 'breakfast')),
                DataCell(_buildMealCell(member.id!, 'lunch')),
                DataCell(_buildMealCell(member.id!, 'dinner')),
                DataCell(_buildMealCell(member.id!, 'breakfast')),
                DataCell(_buildMealCell(member.id!, 'lunch')),
                DataCell(_buildMealCell(member.id!, 'dinner')),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMealCell(int memberId, String mealType) {
    return Icon(
      _mealData[memberId]![mealType]! ? Icons.check : Icons.close,
      color: _mealData[memberId]![mealType]! ? Colors.green : Colors.red,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Meal Tracker", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueAccent,
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blueAccent.shade100, Colors.blueAccent.shade400],
          ),
        ),
        child: Column(
          children: [
            _buildMealCountSummary(),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildNewMealEntry(),
                  ),
                  Expanded(
                    flex: 2,
                    child: _buildMealChart(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveMeals,
        child: Icon(Icons.save, color: Colors.white),
        backgroundColor: Colors.blueAccent,
        elevation: 10,
      ),
    );
  }

  Widget _buildMealCountSummary() {
    return Card(
      margin: EdgeInsets.all(16.0),
      elevation: 10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildMealCountItem('Breakfast', _getMealCount('breakfast')),
            _buildMealCountItem('Lunch', _getMealCount('lunch')),
            _buildMealCountItem('Dinner', _getMealCount('dinner')),
          ],
        ),
      ),
    );
  }

  Widget _buildMealCountItem(String mealType, int count) {
    return Column(
      children: [
        Text(mealType, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
        SizedBox(height: 8),
        Text('$count', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
      ],
    );
  }

  Widget _buildNewMealEntry() {
    return Card(
      margin: EdgeInsets.all(16.0),
      elevation: 10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButton<String>(
                      value: _selectedMealType,
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedMealType = newValue!;
                          _updateMealStatusBasedOnPreviousMeal(newValue.toLowerCase());
                        });
                      },
                      items: <String>['Breakfast', 'Lunch', 'Dinner']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value, style: TextStyle(color: Colors.blueAccent)),
                        );
                      }).toList(),
                      icon: Icon(Icons.arrow_drop_down, color: Colors.blueAccent),
                      dropdownColor: Colors.white,
                      style: TextStyle(fontSize: 16, color: Colors.blueAccent),
                      underline: Container(
                        height: 2,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: TextEditingController(text: _selectedDate),
                      decoration: InputDecoration(
                        labelText: 'Date',
                        labelStyle: TextStyle(color: Colors.blueAccent),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blueAccent),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blueAccent),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      style: TextStyle(color: Colors.blueAccent),
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedDate = picked.toIso8601String().split("T")[0];
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _members.length,
                  itemBuilder: (context, index) {
                    final member = _members[index];
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 4.0),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: CheckboxListTile(
                        title: Text(member.name, style: TextStyle(color: Colors.blueAccent)),
                        value: _mealData[member.id]![_selectedMealType.toLowerCase()],
                        onChanged: (bool? value) {
                          _toggleMeal(member.id!, _selectedMealType.toLowerCase());
                        },
                        activeColor: Colors.blueAccent,
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: _guestMeal,
                    onChanged: (bool? value) {
                      setState(() {
                        _guestMeal = value!;
                      });
                    },
                    activeColor: Colors.blueAccent,
                  ),
                  Text("Guest Meal", style: TextStyle(color: Colors.blueAccent)),
                  if (_guestMeal)
                    Expanded(
                      child: DropdownButton<int>(
                        value: null,
                        hint: Text("Select Member", style: TextStyle(color: Colors.blueAccent)),
                        onChanged: (int? memberId) {
                          // Handle guest meal member selection
                        },
                        items: _members.map<DropdownMenuItem<int>>((Member member) {
                          return DropdownMenuItem<int>(
                            value: member.id,
                            child: Text(member.name, style: TextStyle(color: Colors.blueAccent)),
                          );
                        }).toList(),
                        icon: Icon(Icons.arrow_drop_down, color: Colors.blueAccent),
                        dropdownColor: Colors.white,
                        style: TextStyle(fontSize: 16, color: Colors.blueAccent),
                        underline: Container(
                          height: 2,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}