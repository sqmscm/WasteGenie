import 'package:flutter/material.dart';
import 'package:waste_genie/helpers/database_utils.dart';
import 'package:waste_genie/helpers/globals.dart' as globals;

class Waste {
  final String category;
  final String subCategory;
  final String itemName;
  final String searchDesc;

  Waste({
    this.category = '',
    this.subCategory = '',
    this.itemName = '',
    this.searchDesc = '',
  });
}

class SearchWastes extends StatefulWidget {
  SearchWastes({Key? key}) : super(key: key);

  @override
  State<SearchWastes> createState() => _SearchWastesState();
}

class _SearchWastesState extends State<SearchWastes> {
  TextEditingController editingController = TextEditingController();

  var wastes = <Waste>[];
  var listItems = <Waste>[];

  bool loading = true;

  void loadItems() async {
    final classifications = Map<String, dynamic>.from(
        await DatabaseUtils.getData('waste-classifications', ''));

    for (var category in classifications.keys) {
      if (classifications[category] != null) {
        var subCategories = classifications[category];
        for (var subCategory in subCategories!.keys) {
          if (subCategories[subCategory] != null) {
            var items = subCategories[subCategory];
            for (var item in items!.keys) {
              if (subCategory == 'all') {
                subCategory = '';
              }
              wastes.add(Waste(
                  category: category,
                  subCategory: subCategory,
                  itemName: item,
                  searchDesc: '$category $subCategory $item'.toLowerCase()));
            }
          }
        }
      }
    }

    listItems.addAll(wastes);

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    loadItems();
    globals.currPageName = 'Search';
  }

  void filterSearchResults(String query) {
    if (query.isNotEmpty) {
      if (query.length > 2) {
        DatabaseUtils.writeLog('Search', query);
      }

      List<Waste> dummyListData = <Waste>[];
      query = query.toLowerCase();

      for (var item in wastes) {
        if (item.searchDesc.contains(query)) {
          dummyListData.add(item);
        }
      }
      setState(() {
        listItems.clear();
        listItems.addAll(dummyListData);
      });
    } else {
      setState(() {
        listItems.clear();
        listItems.addAll(wastes);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            style: TextStyle(fontSize: 15),
            onChanged: (value) {
              filterSearchResults(value);
            },
            controller: editingController,
            decoration: InputDecoration(
                contentPadding: EdgeInsets.all(8),
                labelText: "Search",
                hintText: "Search",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(15.0)))),
          ),
        ),
        Expanded(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: listItems.length,
            itemBuilder: (context, index) {
              Waste curr = listItems[index];
              if (curr.subCategory == 'all') {
                return ListTile(
                  title: Text(curr.itemName),
                  leading: Text(curr.category),
                );
              }
              return ListTile(
                title: Text(curr.itemName),
                subtitle: Text(curr.subCategory),
                leading: Text(curr.category),
              );
            },
          ),
        ),
      ],
    );
  }
}
