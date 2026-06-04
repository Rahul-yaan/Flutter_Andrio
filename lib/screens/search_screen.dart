import 'package:flutter/material.dart';
import ' hotel_list_screen.dart';

class SearchScreen extends StatefulWidget {
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final List<String> cities = [
    "Bangalore",
    "Baroda",
    "Bhopal",
    "Mumbai",
    "Delhi",
    "Chennai",
    "Hyderabad"
  ];

  String selectedCity = "";
  DateTime? fromDate;
  DateTime? toDate;

  Future<void> pickFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => fromDate = picked);
    }
  }

  Future<void> pickToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: fromDate ?? DateTime.now(),
      firstDate: fromDate ?? DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => toDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Search Hotel')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [

            /// 🔍 CITY AUTOCOMPLETE
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text == '') return const Iterable<String>.empty();
                return cities.where((city) =>
                    city.toLowerCase().startsWith(textEditingValue.text.toLowerCase()));
              },
              onSelected: (String selection) {
                selectedCity = selection;
              },
              fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(labelText: "City"),
                );
              },
            ),

            SizedBox(height: 20),

            /// 📅 FROM DATE
            ListTile(
              title: Text(fromDate == null
                  ? "Select From Date"
                  : fromDate.toString().split(" ")[0]),
              trailing: Icon(Icons.calendar_today),
              onTap: pickFromDate,
            ),

            /// 📅 TO DATE
            ListTile(
              title: Text(toDate == null
                  ? "Select To Date"
                  : toDate.toString().split(" ")[0]),
              trailing: Icon(Icons.calendar_today),
              onTap: pickToDate,
            ),

            SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                if (selectedCity.isEmpty || fromDate == null || toDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Fill all fields")));
                  return;
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HotelListScreen(
                      city: selectedCity,
                      fromDate: fromDate!,
                      toDate: toDate!,
                    ),
                  ),
                );
              },
              child: Text("Search"),
            )
          ],
        ),
      ),
    );
  }
}