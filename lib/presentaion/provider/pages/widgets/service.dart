import 'package:flutter/material.dart';

class Service extends StatefulWidget {
  final List<String> item;
  const Service({super.key, required this.item});

  @override
  State<Service> createState() => _ServiceState();
}

class _ServiceState extends State<Service> {
  List<String> foundServices = [];


  @override
  void initState() {
    super.initState();
    foundServices = widget.item;
  }

  void searchlitems(String enteredKeyword) {
    List<String> results = [];
    if (enteredKeyword.isEmpty) {
      // if the search field is empty or only contains white-space, we'll display all users

      results = widget.item;
    } else {
      results = widget.item
          .where((location) => location
              .toLowerCase()
              .contains(enteredKeyword.toLowerCase()))
          .cast<String>()
          .toList();
      // we use the toLowerCase() method to make it case-insensitive
    }

    setState(() {
      foundServices = results;

      print(foundServices);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: TextField(
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 15),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: Theme.of(context).highlightColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            border: InputBorder.none,
            fillColor: Theme.of(context).colorScheme.surface,
            filled: true,
            hintText: 'Find Service',
            hintStyle: TextStyle(
              fontSize: 12,
              color: Theme.of(context).hintColor,
            ),
          ),
          onChanged: (value) => searchlitems(value),
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              itemCount: foundServices.length,
              itemBuilder: (context, index) {
                final service = foundServices[index];
                return ListTile(
                  onTap: () async {
                    Navigator.of(context).pop(service);
                  },
                  title: Text(
                    service,
                    style: TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 12),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    color: Theme.of(context).highlightColor,
                    size: 20,
                  ),
                );
              },
              separatorBuilder: (BuildContext context, int index) {
                return Divider(
                  height: 0,
                  color: Theme.of(context).highlightColor,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
