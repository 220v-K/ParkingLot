import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:parkinglot/models/parkinglot_item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:parkinglot/pages/favorites.dart';
import 'package:parkinglot/widget/navigation_bar.dart';

// import 'package:parkinglot/models/parking_lot.dart' as globals;

import '../util/colors.dart';
import 'datetime_selection.dart';

import 'package:parkinglot/util/helper.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  _SearchPageState();
  List<ParkingLotItem> parkingLotItemList = [];

  final key = GlobalKey<ScaffoldState>();
  final TextEditingController _searchQuery = TextEditingController();
  List<ParkingLotItem> _filterList = [];

  bool _IsSearching = false;
  String _searchText = "";
  _SearchListState() {
    _searchQuery.addListener(() {
      if (_searchQuery.text.isEmpty) {
        setState(() {
          _IsSearching = false;
          _searchText = "";
        });
      } else {
        setState(() {
          _IsSearching = true;
          _searchText = _searchQuery.text;
        });
      }
    });
  }

  final Stream<QuerySnapshot> parkinglots = FirebaseFirestore.instance
      .collection('ParkingLot')
      .orderBy('code')
      .snapshots(includeMetadataChanges: true);

  @override
  Widget build(BuildContext context) {
    //bool isAdmin = true;
    //comment for comit test
    bool isAdmin = true;
    String testUserName = 'leejaewon'; //테스트용 이름

    return StreamBuilder<QuerySnapshot>(
      stream: parkinglots,
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        int tempMin = 50;
        if (snapshot.hasError) {
          return Text("Sth Wrong");
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Text("Loading");
        }
        for (var doc in snapshot.data!.docs) {
          parkingLotItemList.add(ParkingLotItem(
              doc["name"],
              doc["address"],
              doc["telephone"],
              doc["parkingtime_permin"],
              doc["pay_fee"],
              doc["capacity"],
              doc["code"],
              true,
              doc["weekday_begin_time"],
              doc["weekday_end_time"],
              doc["weekend_begin_time"],
              doc["weekend_end_time"]));
        }
        print(parkingLotItemList.first.name);
        // TODO: implement build

        return SafeArea(
          child: Scaffold(
            appBar: AppBar(
                backgroundColor: Colors.white,
                centerTitle: true,
                title: TextField(
                  controller: _searchQuery,
                  style: TextStyle(
                    color: Colors.black,
                  ),
                  decoration: InputDecoration(
                      suffixIcon: Icon(Icons.search, color: Colors.black),
                      hintText: "  주차장 검색 ",
                      hintStyle: TextStyle(color: Colors.black)),
                )),
            // body: ListView(
            //   padding: EdgeInsets.symmetric(vertical: 8.0),
            //   children: <Widget>[
            //     _IsSearching ? _createListView() : _createFilteredListView()
            //   ],
            // ),
            body: Container(
                margin: EdgeInsets.only(left: 10.0, right: 10.0, top: 10.0),
                child: _IsSearching
                    ? _createFilteredListView()
                    : _createListView()),
            bottomNavigationBar:
                NaviBarButtons(MediaQuery.of(context).size, context),
          ),
        );
      },
    );
  }

  Widget _createListView() {
    return Flexible(
      child: ListView.builder(
        itemCount: parkingLotItemList.length,
        //itemCount: products.length,
        itemBuilder: (context, index) {
          final size = MediaQuery.of(context).size;
          Size doubleButtonSize = Size(size.width * 0.4, 20);
          //getParkinglots();
          return Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 1.0, horizontal: 3.0),
              child: Card(
                child: ListTile(
                  onTap: () {},
                  subtitle: Column(children: [
                    Row(
                      children: [
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(parkingLotItemList[index].name,
                                  style: TextStyle(
                                      fontSize: 23,
                                      color: blue,
                                      fontWeight: FontWeight.bold)),
                              SizedBox(height: 5),
                              Text(parkingLotItemList[index].address),
                              Text(parkingLotItemList[index].telephone.isEmpty
                                  ? "전화번호 없음"
                                  : parkingLotItemList[index].telephone),
                              Text(
                                  '30분 ${parkingLotItemList[index].fee} 원   |   총 ${parkingLotItemList[index].total_space} 면'),
                            ]),
                      ],
                    ),
                    SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () {
                            FirebaseFirestore.instance
                                .collection("Favorites")
                                .doc(parkingLotItemList[index].name +
                                    '_' +
                                    'leejaewon')
                                .set({
                              "user_name": 'leejaewon',
                              "name": parkingLotItemList[index].name,
                              "address": parkingLotItemList[index].address,
                              "telephone": parkingLotItemList[index].telephone,
                              "minute": parkingLotItemList[index].minute,
                              "fee": parkingLotItemList[index].fee,
                              "total_space":
                                  parkingLotItemList[index].total_space,
                            });
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => FavoritesPage()));
                          },
                          style: buildDoubleButtonStyle(
                              lightGrey, doubleButtonSize),
                          child: const Text('즐겨찾기 추가',
                              style: TextStyle(color: Colors.black)),
                        ),
                        SizedBox(width: 10),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => DateTimeSelection()));
                          },
                          style: buildDoubleButtonStyle(blue, doubleButtonSize),
                          child: const Text('예약하기',
                              style: TextStyle(color: Colors.white)),
                        ),
                        SizedBox(height: 5),
                      ],
                    )
                  ]),
                  // --- 이미지 넣기 ---
                ),
              ));
        },
      ),
    );
  }

  Widget _createFilteredListView() {
    print('_createFilteredListView');

    _filterList = [];
    for (int i = 0; i < parkingLotItemList.length; i++) {
      var item = parkingLotItemList[i];

      if (item.name.contains(_searchText)) {
        _filterList.add(item);
      }
    }
    return Flexible(
      child: ListView.builder(
          itemCount: _filterList.length,
          itemBuilder: (BuildContext context, int index) {
            return Card(
              color: Colors.white,
              elevation: 5.0,
              child: Container(
                margin: EdgeInsets.all(15.0),
                child: Text("${_filterList[index]}"),
              ),
            );
          }),
    );
  }
}
