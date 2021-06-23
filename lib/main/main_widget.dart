
import 'package:flutter/material.dart';
import 'package:test_flutter/dialogs/AddEventDialog.dart';
import 'package:test_flutter/eventList/events_widget.dart';


import 'package:test_flutter/map/map_widget.dart';
import 'package:test_flutter/profile/profile_widget.dart';

class MainPage extends StatefulWidget {


  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".



  @override
  MainPageState createState() => MainPageState();
}

class MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  List pages = [MapPage(),EventListWidget(),ProfileWidget()];
  bool isFabVisible = true;


  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(

        body: pages[_selectedIndex] ,
      bottomNavigationBar: buildBottomNavigationBar(),
      floatingActionButton: Visibility(child:  FloatingActionButton.extended(
          onPressed: (){showDialog(context: context, builder: (BuildContext context){return AddEventDialog();});},
      label: Text('Суета!'),
      icon: Icon(Icons.add),
    ),
    visible: isFabVisible,)



    );
  }
  BottomNavigationBar buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _selectedIndex,
      onTap: (value) {
        setState(() {
          if(value==2) isFabVisible = false;
          else isFabVisible = true;
          _selectedIndex = value;
        });
      },
      items: [
        BottomNavigationBarItem(icon: Icon(Icons.map), label: "Карта"),
        BottomNavigationBarItem(icon: Icon(Icons.event), label: "События"),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "Профиль"),

      ],
    );
  }


}
