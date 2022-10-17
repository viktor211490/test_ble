import 'dart:async';

import 'package:flutter/material.dart';
import 'package:quick_blue/quick_blue.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  List<BlueScanResult> bleNames = [];
  _stopScan() {
    QuickBlue.stopScan();
    setState(() {
      bleNames = bleNames.toSet().toList();
    });
  }

  Timer scheduleTimeout([int milliseconds = 10000]) {
    return Timer(Duration(milliseconds: milliseconds), _stopScan);
  }

  void _incrementCounter() {
    QuickBlue.startScan();
    QuickBlue.scanResultStream.listen((result) {
      bleNames.add(result);
      print('onScanResult ' + result.name);
    });
    scheduleTimeout(5 * 1000);
    setState(() {
      _counter++;
    });
  }

  final spinkit = SpinKitFadingCircle(
    itemBuilder: (BuildContext context, int index) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: index.isEven ? Colors.red : Colors.green,
        ),
      );
    },
  );
  @override
  void initState() {
    super.initState();
    _incrementCounter(); //call it over here
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('hello'),
        ),
        body: bleNames.isNotEmpty
            ? ListView.builder(
                itemCount: bleNames.length,
                prototypeItem: ListTile(
                  title: Text(bleNames.first.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('id: ${bleNames.first.deviceId}'),
                      Text('rssi: ${bleNames.first.rssi}'),
                      Text(
                          'manufacturerData/bufer: ${bleNames.first.manufacturerData.buffer.asByteData()}'),
                    ],
                  ),
                ),
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(bleNames[index].name.isNotEmpty
                        ? bleNames[index].name
                        : "Name is EMPTY"),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('id: ${bleNames[index].deviceId}'),
                        Text('rssi: ${bleNames[index].rssi}'),
                        Text(
                            'manufacturerData/bufer: ${bleNames[index].manufacturerData.buffer.asByteData()}'),
                      ],
                    ),
                  );
                },
              )
            : spinkit);
  }
}
