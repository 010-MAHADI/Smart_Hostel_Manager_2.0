import 'package:flutter/material.dart';
import '../db/db_helper.dart';

class MarketScreen extends StatefulWidget {
  @override
  _MarketScreenState createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _marketList = [];
  Map<String, List<Map<String, dynamic>>> _groupedMarketList = {};
  DateTime? _selectedDate;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadMarketData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _filterMarketItems();
    });
  }

  void _filterMarketItems() {
    final searchText = _searchController.text.toLowerCase();
    _groupedMarketList = _groupMarketItems(_marketList.where((item) {
      final itemName = item['item'].toString().toLowerCase();
      return itemName.contains(searchText);
    }).toList());
  }

  void _loadMarketData() async {
    final db = await DBHelper.instance.database;
    final result = await db.query('market');
    setState(() {
      _marketList = result;
      _groupedMarketList = _groupMarketItems(result);
    });
  }

  Map<String, List<Map<String, dynamic>>> _groupMarketItems(List<Map<String, dynamic>> items) {
    Map<String, List<Map<String, dynamic>>> groupedItems = {};
    for (var item in items) {
      final date = item['date'];
      if (groupedItems[date] == null) {
        groupedItems[date] = [];
      }
      groupedItems[date]!.add(item);
    }
    return groupedItems;
  }

  void _addMarketItem(DateTime date) async {
    if (_itemController.text.isEmpty || _amountController.text.isEmpty) return;

    final db = await DBHelper.instance.database;
    await db.insert(
      'market',
      {
        'item': _itemController.text,
        'amount': double.parse(_amountController.text),
        'quantity': double.parse(_quantityController.text),
        'date': date.toIso8601String().split("T")[0],
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'manager_signature': 'Manager Signature', // Placeholder for now
        'marketer_signature': 'Marketer Signature', // Placeholder for now
      },
    );

    _itemController.clear();
    _amountController.clear();
    _quantityController.clear();
    _loadMarketData();
    Navigator.pop(context);
  }

  void _editMarketItem(int id) async {
    final db = await DBHelper.instance.database;
    final item = await db.query('market', where: "id = ?", whereArgs: [id]);

    _itemController.text = item[0]['item'].toString();
    _amountController.text = item[0]['amount'].toString();
    _quantityController.text = item[0]['quantity'].toString();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit Market Item", style: TextStyle(color: Colors.blueAccent)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: _itemController,
                decoration: InputDecoration(labelText: "Item Name", labelStyle: TextStyle(color: Colors.blueAccent)),
                style: TextStyle(color: Colors.black87)),
            TextField(
                controller: _amountController,
                decoration: InputDecoration(labelText: "Amount", labelStyle: TextStyle(color: Colors.blueAccent)),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(color: Colors.black87)),
            TextField(
                controller: _quantityController,
                decoration: InputDecoration(labelText: "Quantity", labelStyle: TextStyle(color: Colors.blueAccent)),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(color: Colors.black87)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text("Cancel", style: TextStyle(color: Colors.redAccent))),
          TextButton(
              onPressed: () async {
                await db.update(
                  'market',
                  {
                    'item': _itemController.text,
                    'amount': double.parse(_amountController.text),
                    'quantity': double.parse(_quantityController.text),
                    'date': DateTime.now().toIso8601String().split("T")[0],
                    'timestamp': DateTime.now().millisecondsSinceEpoch,
                  },
                  where: "id = ?",
                  whereArgs: [id],
                );

                _itemController.clear();
                _amountController.clear();
                _quantityController.clear();
                _loadMarketData();
                Navigator.pop(context);
              },
              child: Text("Save", style: TextStyle(color: Colors.blueAccent))),
        ],
      ),
    );
  }

  void _showMarketDialog() {
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Add Market Item", style: TextStyle(color: Colors.blueAccent)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () async {
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (pickedDate != null) {
                  setState(() {
                    selectedDate = pickedDate;
                  });
                }
              },
              child: Text(
                "Date: ${selectedDate.toLocal().toString().split(' ')[0]}",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent),
              ),
            ),
            SizedBox(height: 8),
            TextField(
                controller: _itemController,
                decoration: InputDecoration(labelText: "Item Name", labelStyle: TextStyle(color: Colors.blueAccent)),
                style: TextStyle(color: Colors.black87)),
            TextField(
                controller: _amountController,
                decoration: InputDecoration(labelText: "Amount", labelStyle: TextStyle(color: Colors.blueAccent)),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(color: Colors.black87)),
            TextField(
                controller: _quantityController,
                decoration: InputDecoration(labelText: "Quantity", labelStyle: TextStyle(color: Colors.blueAccent)),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(color: Colors.black87)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text("Cancel", style: TextStyle(color: Colors.redAccent))),
          TextButton(
              onPressed: () => _addMarketItem(selectedDate),
              child: Text("Save", style: TextStyle(color: Colors.blueAccent))),
        ],
      ),
    );
  }

  bool _canEditItem(int timestamp) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return now - timestamp < 24 * 60 * 60 * 1000; // 24 hours in milliseconds
  }

  double _calculateTotalForDate(List<Map<String, dynamic>> items) {
    double total = 0;
    for (var item in items) {
      total += item['amount']; // Exclude quantity from calculation
    }
    return total;
  }

  void _showFullListForDate(String date, List<Map<String, dynamic>> items) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Full List for $date", style: TextStyle(color: Colors.blueAccent)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: items.map((item) => ListTile(
              title: Text(item['item'], style: TextStyle(color: Colors.black87)),
              subtitle: Text(
                  "৳${item['amount']} - ${item['quantity']} units", style: TextStyle(color: Colors.black54)),
              trailing: _canEditItem(item['timestamp'])
                  ? IconButton(
                icon: Icon(Icons.edit, color: Colors.blueAccent),
                onPressed: () => _editMarketItem(item['id']),
              )
                  : null,
            )).toList(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text("Close", style: TextStyle(color: Colors.blueAccent))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: "Search items...",
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white70),
          ),
          style: TextStyle(color: Colors.white),
          autofocus: true,
        )
            : Text("Market List", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.white),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _groupedMarketList = _groupMarketItems(_marketList);
                }
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.filter_alt, color: Colors.white),
            onPressed: () async {
              final pickedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (pickedDate != null) {
                setState(() {
                  _selectedDate = pickedDate;
                  _groupedMarketList = _groupMarketItems(_marketList.where((item) {
                    return item['date'] == pickedDate.toIso8601String().split("T")[0];
                  }).toList());
                });
              }
            },
          ),
        ],
      ),
      body: ListView(
        children: _groupedMarketList.entries.map((entry) {
          final date = entry.key;
          final items = entry.value;
          final total = _calculateTotalForDate(items);

          return Card(
            margin: EdgeInsets.all(8.0),
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: InkWell(
              onTap: () => _showFullListForDate(date, items),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Date: $date",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                    ),
                    SizedBox(height: 8),
                    ...items.take(3).map((item) => ListTile(
                      title: Text(item['item'], style: TextStyle(color: Colors.black87)),
                      subtitle: Text(
                          "৳${item['amount']} - ${item['quantity']} units", style: TextStyle(color: Colors.black54)),
                      trailing: _canEditItem(item['timestamp'])
                          ? IconButton(
                        icon: Icon(Icons.edit, color: Colors.blueAccent),
                        onPressed: () => _editMarketItem(item['id']),
                      )
                          : null,
                    )),
                    if (items.length > 3)
                      Text(
                        "... and ${items.length - 3} more items",
                        style: TextStyle(color: Colors.grey),
                      ),
                    Divider(),
                    Text(
                      "Total: ৳${total.toStringAsFixed(2)}",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Manager Signature: ${items.first['manager_signature']}",
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                    Text(
                      "Marketer Signature: ${items.first['marketer_signature']}",
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showMarketDialog,
        child: Icon(Icons.add, color: Colors.white),
        backgroundColor: Colors.blueAccent,
        elevation: 4,
      ),
    );
  }
}