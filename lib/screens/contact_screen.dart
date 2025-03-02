import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactScreen extends StatelessWidget {
  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      print('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Contact Information"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.account_circle,
                size: 80,
                color: Colors.deepPurple,
              ),
              SizedBox(height: 20),
              Text(
                "MD MAHADI HASAN",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              SizedBox(height: 10),
              Text(
                "Love Programing | CST Student | App Tester",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.email, color: Colors.deepPurple),
                title: Text("mahadi796630@gmail.com"),
                onTap: () => _launchURL("mailto:mahadi796630@gmail.com"),
              ),
              ListTile(
                leading: Icon(Icons.phone, color: Colors.deepPurple),
                title: Text("01922796630"),
                onTap: () => _launchURL("tel:01922796630"),
              ),
              ListTile(
                leading: Icon(Icons.link, color: Colors.deepPurple),
                title: Text("GitHub: 010-Mahadi"),
                onTap: () => _launchURL("https://github.com/010-Mahadi"),
              ),
              ListTile(
                leading: Icon(Icons.facebook, color: Colors.blue),
                title: Text("Facebook"),
                onTap: () => _launchURL("https://www.facebook.com/Mahadi379377"),
              ),
              ListTile(
                leading: Icon(Icons.link, color: Colors.blue),
                title: Text("Twitter"),
                onTap: () => _launchURL("https://x.com/Mahadi379377"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}