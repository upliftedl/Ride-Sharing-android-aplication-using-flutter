import 'package:flutter/material.dart';

class HelpAndSupportPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Help & Support")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Need Help?",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text("For any issues, please contact us at:"),
            SizedBox(height: 5),
            Text("📧 Email: support@rideshare.com",
                style: TextStyle(fontSize: 16)),
            SizedBox(height: 5),
            Text("📞 Phone: +91 98765 43210", style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
