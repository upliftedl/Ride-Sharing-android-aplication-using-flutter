import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile.dart';

class EditProfileScreen extends StatefulWidget {
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  String? _gender;
  bool isNameEditable = false;
  bool isDobEditable = false;
  bool isGenderEditable = false;
  bool _isLoading = false;
  bool _hasLicense = false;
  bool _hasVehicle = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    User? user = _auth.currentUser;
    if (user != null) {
      var userDoc = await _firestore.collection("users").doc(user.uid).get();
      if (userDoc.exists) {
        var data = userDoc.data()!;
        setState(() {
          _nameController.text = data["name"] ?? "";
          _phoneController.text = data["phone"] ?? "";
          _addressController.text = data["address"] ?? "";
          _dobController.text = data["dob"] ?? "";
          _gender = data["gender"];
          _hasLicense = data["hasLicense"] ?? false;
          _hasVehicle = data["hasVehicle"] ?? false;
          isNameEditable = _nameController.text.isEmpty;
          isDobEditable = _dobController.text.isEmpty;
          isGenderEditable = _gender == null;
        });
      }
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    User? user = _auth.currentUser;

    if (user != null) {
      Map<String, dynamic> updatedData = {
        "phone": _phoneController.text.trim(),
        "address": _addressController.text.trim(),
        "hasLicense": _hasLicense,
        "hasVehicle": _hasVehicle,
      };

      if (isNameEditable) updatedData["name"] = _nameController.text.trim();
      if (isDobEditable) updatedData["dob"] = _dobController.text.trim();
      if (isGenderEditable) updatedData["gender"] = _gender;

      updatedData["profileCompleted"] = true;

      await _firestore.collection("users").doc(user.uid).update(updatedData);

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Profile updated successfully!")));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ProfileScreen()),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Edit Profile"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/bg.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(color: Colors.black.withOpacity(0.4)),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 120),
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(
                        _auth.currentUser?.photoURL ??
                            "https://via.placeholder.com/150",
                      ),
                    ),
                    const SizedBox(height: 20),
                    isNameEditable
                        ? _buildEditableField(
                          "Name",
                          _nameController,
                          TextInputType.text,
                        )
                        : _buildImmutableField("Name", _nameController.text),
                    _buildEditableField(
                      "Phone Number",
                      _phoneController,
                      TextInputType.phone,
                    ),
                    _buildEditableField(
                      "Address",
                      _addressController,
                      TextInputType.text,
                    ),
                    isDobEditable
                        ? _buildDatePickerField(
                          "Date of Birth *",
                          _dobController,
                        )
                        : _buildImmutableField(
                          "Date of Birth",
                          _dobController.text,
                        ),
                    isGenderEditable
                        ? _buildDropdownField(
                          "Gender *",
                          _gender,
                          ["Male", "Female", "Other"],
                          (value) {
                            setState(() => _gender = value);
                          },
                        )
                        : _buildImmutableField(
                          "Gender",
                          _gender ?? "Not Specified",
                        ),
                    // License Toggle
                    _buildToggleSwitch(
                      "I have a driving license",
                      _hasLicense,
                      (value) => setState(() => _hasLicense = value),
                    ),
                    // Vehicle Toggle
                    _buildToggleSwitch(
                      "I own a vehicle",
                      _hasVehicle,
                      (value) => setState(() => _hasVehicle = value),
                    ),
                    SizedBox(height: 20),
                    _isLoading
                        ? Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                          onPressed: _updateProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color.fromRGBO(165, 101, 101, 0.8),
                            padding: EdgeInsets.symmetric(
                              horizontal: 50,
                              vertical: 15,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: Text(
                            "Save Changes",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleSwitch(
    String label,
    bool value,
    Function(bool) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white, fontSize: 16)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Color.fromRGBO(165, 101, 101, 0.8),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableField(
    String title,
    TextEditingController controller,
    TextInputType inputType,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: TextFormField(
        controller: controller,
        keyboardType: inputType,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: "$title *",
          labelStyle: TextStyle(color: Colors.white70),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white70),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
          ),
        ),
        validator: (value) => value!.isEmpty ? "⚠ Enter $title" : null,
      ),
    );
  }

  Widget _buildDatePickerField(String title, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: TextFormField(
        controller: controller,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: title,
          labelStyle: TextStyle(color: Colors.white70),
          suffixIcon: Icon(Icons.calendar_today, color: Colors.white70),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white70),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
          ),
        ),
        readOnly: true,
        onTap: () async {
          DateTime? pickedDate = await showDatePicker(
            context: context,
            initialDate: DateTime(2000),
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
          );
          if (pickedDate != null) {
            controller.text = "${pickedDate.toLocal()}".split(' ')[0];
          }
        },
        validator: (value) => value!.isEmpty ? "⚠ Select $title" : null,
      ),
    );
  }

  Widget _buildDropdownField(
    String title,
    String? value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: title,
          labelStyle: TextStyle(color: Colors.white70),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white70),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isDense: true,
            isExpanded: true,
            dropdownColor: Colors.grey[900],
            style: TextStyle(color: Colors.white, fontSize: 16),
            items:
                items.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
            onChanged: onChanged,
            hint: Text(
              "Select $title",
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImmutableField(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(value, style: TextStyle(color: Colors.white, fontSize: 16)),
          Divider(color: Colors.white54, height: 1),
        ],
      ),
    );
  }
}
