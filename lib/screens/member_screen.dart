import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../db/member_service.dart';
import '../db/db_helper.dart'; // Import DBHelper to fetch meal rate
import '../models/member.dart';

class MemberScreen extends StatefulWidget {
  @override
  _MemberScreenState createState() => _MemberScreenState();
}

class _MemberScreenState extends State<MemberScreen> {
  final MemberService _memberService = MemberService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _mealPreferenceController = TextEditingController();
  final TextEditingController _balanceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Search controller and filtered member list
  final TextEditingController _searchController = TextEditingController();
  List<Member> _filteredMembers = [];

  String? _profileImagePath;
  List<Member> _members = [];
  double _mealRate = 0.0; // Store meal rate per meal

  @override
  void initState() {
    super.initState();
    _loadMembers();
    _fetchMealRate(); // Fetch meal rate when the screen loads
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _mealPreferenceController.dispose();
    _balanceController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Fetch meal rate from the database
  void _fetchMealRate() async {
    final db = await DBHelper.instance.database;
    final marketResult = await db.rawQuery("SELECT SUM(amount) AS total FROM market");
    double totalMarketExpense = (marketResult.first['total'] as double?) ?? 0.0;

    final mealResult = await db.rawQuery("SELECT SUM(breakfast + lunch + dinner) AS total FROM meals");
    int totalMeals = (mealResult.first['total'] as int?) ?? 0;

    setState(() {
      _mealRate = totalMeals > 0 ? totalMarketExpense / totalMeals : 0.0;
    });
  }

  void _loadMembers() async {
    final members = await _memberService.getMembers();
    setState(() {
      _members = members;
      _filteredMembers = members;
    });
  }

  // Filter members based on search query
  void _filterMembers(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredMembers = _members;
      });
    } else {
      setState(() {
        _filteredMembers = _members
            .where((member) => member.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      });
    }
  }

  // Calculate remaining balance for a member
  double _calculateRemainingBalance(Member member) {
    return member.balance - (_mealRate * member.totalMeals);
  }

  void _addOrUpdateMember({Member? member}) async {
    try {
      final name = _nameController.text;
      final phone = _phoneController.text;
      final email = _emailController.text;
      final address = _addressController.text;
      final mealPreference = _mealPreferenceController.text;
      final balance = double.tryParse(_balanceController.text) ?? 0.0; // Fixed balance
      final description = _descriptionController.text;

      if (name.isEmpty || phone.isEmpty || email.isEmpty || address.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please fill all required fields")),
        );
        return;
      }

      if (member == null) {
        // Add a new member with the fixed balance
        await _memberService.addMember(Member(
          name: name,
          phone: phone,
          email: email,
          address: address,
          mealPreference: mealPreference,
          balance: balance, // Fixed balance
          description: description,
          profileImagePath: _profileImagePath,
          totalMeals: 0, // Initialize total meals to 0
        ));
        print("Added member with balance: $balance");
      } else {
        // Update an existing member, keeping the balance fixed
        await _memberService.updateMember(Member(
          id: member.id,
          name: name,
          phone: phone,
          email: email,
          address: address,
          mealPreference: mealPreference,
          balance: balance, // Fixed balance
          description: description,
          profileImagePath: _profileImagePath,
          totalMeals: member.totalMeals, // Keep the existing total meals
        ));
        print("Updated member with balance: $balance");
      }

      // Clear fields after saving
      _nameController.clear();
      _phoneController.clear();
      _emailController.clear();
      _addressController.clear();
      _mealPreferenceController.clear();
      _balanceController.clear();
      _descriptionController.clear();
      _profileImagePath = null;

      // Reload members and close the dialog
      _loadMembers();
      Navigator.pop(context);
    } catch (e) {
      print("Error saving member: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save member: $e")),
      );
    }
  }

  // Show dialog for adding or editing member
  void _showMemberDialog({Member? member}) {
    if (member != null) {
      _nameController.text = member.name;
      _phoneController.text = member.phone;
      _emailController.text = member.email;
      _addressController.text = member.address;
      _mealPreferenceController.text = member.mealPreference;
      _balanceController.text = member.balance.toString();
      _descriptionController.text = member.description;
      _profileImagePath = member.profileImagePath;
    } else {
      _nameController.clear();
      _phoneController.clear();
      _emailController.clear();
      _addressController.clear();
      _mealPreferenceController.clear();
      _balanceController.clear();
      _descriptionController.clear();
      _profileImagePath = null;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(member == null ? "Add Member" : "Edit Member", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _profileImagePath != null
                      ? FileImage(File(_profileImagePath!))
                      : null,
                  child: _profileImagePath == null ? Icon(Icons.camera_alt, size: 40) : null,
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: "Name",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: "Phone",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: "Address",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _mealPreferenceController,
                decoration: InputDecoration(
                  labelText: "Meal Preference",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.fastfood),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _balanceController,
                decoration: InputDecoration(
                  labelText: "Total Balance",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 10),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: "Description",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () => _addOrUpdateMember(member: member),
            child: Text("Save", style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
          ),
        ],
      ),
    );
  }

  // Show a read-only profile view with full details
  void _showProfile(Member member) {
    final remainingBalance = _calculateRemainingBalance(member);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Profile of ${member.name}", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: member.profileImagePath != null
                      ? FileImage(File(member.profileImagePath!))
                      : null,
                  child: member.profileImagePath == null
                      ? Icon(Icons.person, size: 50)
                      : null,
                ),
              ),
              SizedBox(height: 20),
              Text("Phone: ${member.phone}", style: TextStyle(fontSize: 16)),
              SizedBox(height: 10),
              Text("Email: ${member.email}", style: TextStyle(fontSize: 16)),
              SizedBox(height: 10),
              Text("Address: ${member.address}", style: TextStyle(fontSize: 16)),
              SizedBox(height: 10),
              Text("Meal Preference: ${member.mealPreference}", style: TextStyle(fontSize: 16)),
              SizedBox(height: 10),
              Text("Total Balance: ৳${member.balance.toStringAsFixed(2)}", style: TextStyle(fontSize: 16)),
              SizedBox(height: 10),
              Text("Total Meals: ${member.totalMeals}", style: TextStyle(fontSize: 16)),
              SizedBox(height: 10),
              Text("Remaining Balance: ৳${remainingBalance.toStringAsFixed(2)}", style: TextStyle(fontSize: 16)),
              SizedBox(height: 10),
              Text("Description: ${member.description}", style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close", style: TextStyle(color: Colors.indigo)),
          )
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final savedImage = await File(pickedFile.path).copy('${appDir.path}/$fileName');

      setState(() {
        _profileImagePath = savedImage.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Members", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo,
        elevation: 10,
      ),
      backgroundColor: Colors.grey[200],
      body: Column(
        children: [
          // Search field at the top
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: "Search",
                prefixIcon: Icon(Icons.search, color: Colors.indigo),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                _filterMembers(value);
              },
            ),
          ),
          // List of members with increased box size and adjusted layout
          Expanded(
            child: ListView.builder(
              itemCount: _filteredMembers.length,
              itemBuilder: (context, index) {
                final member = _filteredMembers[index];
                final remainingBalance = _calculateRemainingBalance(member);
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Container(
                    padding: EdgeInsets.all(16),
                    constraints: BoxConstraints(minHeight: 120),
                    child: ListTile(
                      onTap: () => _showProfile(member),
                      leading: member.profileImagePath != null
                          ? CircleAvatar(
                        radius: 30,
                        backgroundImage: FileImage(File(member.profileImagePath!)),
                      )
                          : CircleAvatar(
                        radius: 30,
                        child: Icon(Icons.person, size: 30),
                      ),
                      title: Text(member.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 5),
                          Text("Total Balance: ৳${member.balance.toStringAsFixed(2)}", style: TextStyle(fontSize: 14)),
                          Text("Remaining Balance: ৳${remainingBalance.toStringAsFixed(2)}", style: TextStyle(fontSize: 14)),
                        ],
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.edit, color: Colors.indigo),
                        onPressed: () => _showMemberDialog(member: member),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showMemberDialog(),
        backgroundColor: Colors.indigo,
        child: Icon(Icons.add, color: Colors.white),
        elevation: 10,
      ),
    );
  }
}