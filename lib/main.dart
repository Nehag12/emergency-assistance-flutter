import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_sms/flutter_sms.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(EmergencyApp());
}

class EmergencyApp extends StatelessWidget {
  const EmergencyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: HomeScreen());
  }
}

// ================= HOME SCREEN =================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  List<String> emergencyContacts = [];

  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    loadContacts();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 140, end: 180).animate(_controller);
  }

  Future<void> loadContacts() async {
    final prefs = await SharedPreferences.getInstance();
    emergencyContacts = prefs.getStringList('contacts') ?? [];
    setState(() {});
  }

  Future<void> handleSOS() async {
    Position position = await Geolocator.getCurrentPosition();

    String url =
        "https://www.google.com/maps?q=${position.latitude},${position.longitude}";

    String message = "🚨 Emergency! My location: $url";

    if (emergencyContacts.isNotEmpty) {
      await sendSMS(message: message, recipients: emergencyContacts);
    }

    final Uri callUri = Uri(scheme: 'tel', path: '112');
    await launchUrl(callUri);

    final Uri mapUri = Uri.parse(url);
    await launchUrl(mapUri);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("SOS Sent!")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Emergency SOS"),
        actions: [
          IconButton(
            icon: Icon(Icons.contacts),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ContactsScreen()),
              );
              loadContacts(); // refresh after coming back
            },
          ),
        ],
      ),
      body: Center(
        child: AnimatedBuilder(
          animation: _animation,
          builder: (_, _) {
            return GestureDetector(
              onTap: handleSOS,
              child: Container(
                height: _animation.value,
                width: _animation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red,
                ),
                child: Center(
                  child: Text(
                    "SOS",
                    style: TextStyle(fontSize: 30, color: Colors.white),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ================= CONTACT SCREEN =================

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  _ContactsScreenState createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  List<String> contacts = [];

  @override
  void initState() {
    super.initState();
    loadContacts();
  }

  Future<void> loadContacts() async {
    final prefs = await SharedPreferences.getInstance();
    contacts = prefs.getStringList('contacts') ?? [];
    setState(() {});
  }

  Future<void> saveContacts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('contacts', contacts);
  }

  void addContact() {
    TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Add Contact"),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  contacts.add(controller.text);
                });
                saveContacts();
              }
              Navigator.pop(context);
            },
            child: Text("Save"),
          ),
        ],
      ),
    );
  }

  void deleteContact(int index) {
    setState(() {
      contacts.removeAt(index);
    });
    saveContacts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Emergency Contacts")),
      floatingActionButton: FloatingActionButton(
        onPressed: addContact,
        child: Icon(Icons.add),
      ),
      body: ListView.builder(
        itemCount: contacts.length,
        itemBuilder: (_, i) {
          return ListTile(
            title: Text(contacts[i]),
            trailing: IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => deleteContact(i),
            ),
          );
        },
      ),
    );
  }
}
