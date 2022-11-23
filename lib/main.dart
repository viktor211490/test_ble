import 'dart:async';
import 'dart:typed_data';
import 'package:convert/convert.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:quick_blue/quick_blue.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

final log = Logger('BleLogger');
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter BLE Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter BLE Demo'),
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
  final QuickBlue blue = QuickBlue();
  List<BlueScanResult> bleNames = [];
  var set = <String>{};

  _stopScan() {
    QuickBlue.stopScan();
    setState(() {
      bleNames =
          bleNames.where((element) => set.add(element.deviceId)).toList();
    });
  }

  Timer scheduleTimeout([int milliseconds = 10000]) {
    return Timer(Duration(milliseconds: milliseconds), _stopScan);
  }

  Future<void> _connectBlePeripheral(BlueScanResult data) async {
    print(data.name);

    // await QuickBlue.readValue('D4:62:E6:96:8D:DA', '0000180f-0000-1000-8000-00805f9b34fb', '00002a19-0000-1000-8000-00805f9b34fb');

    Future<void> _handleConnectionChange(
        String deviceId, BlueConnectionState state) async {
      print('_handleConnectionChange $deviceId, ${state.value}');
    }

    QuickBlue.setConnectionHandler(_handleConnectionChange);
    QuickBlue.connect(data.deviceId);
  }

  void _disconnectBlePher(BlueScanResult data) {
    QuickBlue.disconnect(data.deviceId);
  }

  void _findBleDevices() {
    // QuickBlue.setServiceHandler(_handleServiceDiscovery);

    // void _handleServiceDiscovery(String deviceId) {
    //   print('_handleServiceDiscovery $deviceId');}

    QuickBlue.startScan();

    QuickBlue.scanResultStream.listen((result) {
      bleNames.add(result);
    });
    scheduleTimeout(10 * 1000);
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
    _findBleDevices();
    QuickBlue.setLogger(log);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
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
                        'manufacturerData/buffer: ${bleNames.first.manufacturerData.buffer.asByteData()}'),
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
                    ],
                  ),
                  onTap: () => {
                    _connectBlePeripheral(bleNames[index]),
                  },
                  onLongPress: () => {_disconnectBlePher(bleNames[index])},
                  trailing: IconButton(
                      onPressed: () =>
                          {_showMyDialog(context, bleNames[index])},
                      icon: const Icon(Icons.more_vert)),
                );
              },
            )
          : spinkit,
      floatingActionButton: FloatingActionButton(
        onPressed: () => {
          setState(() {
            bleNames.removeRange(0, bleNames.length);
            set = <String>{};
          }),
          _findBleDevices()
        },
        child: Icon(Icons.refresh),
      ),
    );
  }
}

Future<void> _showMyDialog(BuildContext context, BlueScanResult bleInfo) async {
  Future<void> GetServices(String deviceId) async {
    void _handleServiceDiscovery(
        String deviceId, String serviceId, List<String> characteristicIds) {
      //never triggered
      print(
          '_handleServiceDiscovery $deviceId, $serviceId, $characteristicIds');
      void _handleValueChange(
          String deviceId, String characteristicId, Uint8List value) {
        print('_handleValueChange $deviceId, $characteristicId, $value');
      }

      QuickBlue.setValueHandler(_handleValueChange);

      for (var characteristicId in characteristicIds) {
        {
          if (characteristicId == '00002a28-0000-1000-8000-00805f9b34fb') {
            QuickBlue.setNotifiable(deviceId, serviceId, characteristicId,
                BleInputProperty.indication);
            QuickBlue.readValue(deviceId, serviceId, characteristicId);
          }

          // QuickBlue.setNotifiable(deviceId, serviceId, characteristicId, BleInputProperty.disabled)
        }
      }
    }

    QuickBlue.setServiceHandler(_handleServiceDiscovery);

    QuickBlue.discoverServices(deviceId);
  }

  return showDialog<void>(
    context: context,
    barrierDismissible: false, // user must tap button!
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(bleInfo.name.isNotEmpty ? bleInfo.name : bleInfo.deviceId),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text('rssi: ${bleInfo.rssi}'),
              Text('manufacturerData/buffer: ${bleInfo.name}'),
              IconButton(
                  onPressed: () {
                    GetServices(bleInfo.deviceId);
                  },
                  icon: const Icon(Icons.accessible_forward_sharp))
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Approve'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}
