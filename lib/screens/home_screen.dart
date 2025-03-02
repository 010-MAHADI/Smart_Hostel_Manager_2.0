import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'member_screen.dart';
import 'meal_screen.dart';
import 'market_screen.dart';
import 'summary_screen.dart';
import 'contact_screen.dart'; // Ensure this import is added
import 'terms_and_conditions.dart'; // Ensure this import is added

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = "Add Name";
  String userImage = "assets/default_user.png"; // Default user image

  void _updateUserImage(String newImage) {
    setState(() {
      userImage = newImage;
    });
  }

  void _updateUserName(String newName) {
    setState(() {
      userName = newName;
    });
  }

  void _showProfileShutter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: GestureDetector(
                  onTap: () async {
                    final ImagePicker _picker = ImagePicker();
                    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

                    if (image != null) {
                      _updateUserImage(image.path); // Update the user image
                    }
                    Navigator.pop(context);
                  },
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: userImage.startsWith('assets/')
                        ? AssetImage(userImage) // Load from assets
                        : FileImage(File(userImage)) as ImageProvider, // Load from file
                    child: Icon(Icons.camera_alt, color: Colors.white),
                  ),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  _updateUserName(value);
                },
              ),
              SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.contact_mail),
                title: Text('Contact Us'),
                onTap: () {
                  Navigator.pop(context); // Close the bottom sheet
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ContactScreen()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.description),
                title: Text('Terms and Conditions'),
                onTap: () {
                  Navigator.pop(context); // Close the bottom sheet
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => TermsAndConditionsScreen()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.logout),
                title: Text('Logout'),
                onTap: () {
                  // Implement logout functionality
                  _logout(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _logout(BuildContext context) {
    // Perform logout actions here
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.teal.shade600,
              Colors.teal.shade100,
            ],
          ),
        ),
        child: Column(
          children: [
            // User image and name at the top corner
            Padding(
              padding: EdgeInsets.only(top: 40, left: 20, right: 20),
              child: GestureDetector(
                onTap: () {
                  _showProfileShutter(context); // Open profile options when tapped
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Welcome Back",
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          userName,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 28, // Increased font size
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    CircleAvatar(
                      backgroundImage: userImage.startsWith('assets/')
                          ? AssetImage(userImage) // Load from assets
                          : FileImage(File(userImage)) as ImageProvider, // Load from file
                      radius: 30,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 30),
            // Buttons moved upwards
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildAnimatedButton(
                      label: 'Manage Members',
                      icon: Icons.account_box,
                      color: Colors.amber,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => MemberScreen()),
                      ),
                    ),
                    SizedBox(height: 30),
                    _buildAnimatedButton(
                      label: 'Track Meals',
                      icon: Icons.food_bank,
                      color: Colors.teal,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => MealScreen()),
                      ),
                    ),
                    SizedBox(height: 30),
                    _buildAnimatedButton(
                      label: 'Market List',
                      icon: Icons.shopping_cart_outlined,
                      color: Colors.blueAccent,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => MarketScreen()),
                      ),
                    ),
                    SizedBox(height: 30),
                    _buildAnimatedButton(
                      label: 'View Summary',
                      icon: Icons.add_chart,
                      color: Colors.deepPurple,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SummaryScreen()),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.black12,
        child: Container(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround, // Reduced distance
            children: [
              IconButton(
                icon: Icon(Icons.home, color: Colors.black45, size: 50), // Increased icon size
                onPressed: () {
                  // Navigate to home or perform any action
                },
              ),
              IconButton(
                icon: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person, color: Colors.black45, size: 50), // Increased icon size
                    Container(
                      height: 8,
                      width: 40,
                      color: Colors.black45,
                    ),
                  ],
                ),
                onPressed: () {
                  _showProfileShutter(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: 130, // Enlarged height
      width: 350, // Enlarged width
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onPressed,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 50, // Enlarged icon size
                ),
                SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24, // Enlarged font size
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}