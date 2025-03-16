import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:parking_manager/MoneyController.dart';
import 'package:parking_manager/TimeController.dart';
import 'package:parking_manager/vehicle.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseDatabase.instance.databaseURL = "https://parking-manager-11a88-default-rtdb.firebaseio.com/";
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Parking Manager',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late DatabaseReference _vehicleRef;
  late StreamSubscription<DatabaseEvent> _vehicleSubscription;
  List<Vehicle> vehicleList = [];
  TextStyle ts = TextStyle(fontWeight: FontWeight.bold, fontSize: 18);

  @override
  void initState() {
    super.initState();
    _vehicleRef = FirebaseDatabase.instance.ref("parking_history");

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listenToVehicleData();
    });
  }

  void _listenToVehicleData() {
  _vehicleSubscription = _vehicleRef.onValue.listen((DatabaseEvent event) async {
    final dataSnapshot = event.snapshot;
    if (dataSnapshot.exists) {
      vehicleList.clear();

      for (final child in dataSnapshot.children) {
        final childData = child.value as Map<dynamic, dynamic>?;
        final String id = child.key ?? '';
        final String currentTime = DateTime.now().toIso8601String();
        
        if (childData != null) {
          final String status = childData['status'] as String? ?? '';
          final String userRfId = childData['user_rf_id'] as String? ?? '';
          final String vehiclePlate = childData['vehicle_plate'] as String? ?? '';

          final docRef = FirebaseFirestore.instance.collection('parking_history').doc(id);
          final snapshot = await docRef.get();

          String timeIn = '';
          String timeOut = '';

          if (status.toUpperCase() == 'IN') {
            if (!snapshot.exists) {
              // Thêm mới nếu chưa tồn tại
              await docRef.set({
                'user_rf_id': userRfId,
                'vehicle_plate': vehiclePlate,
                'status': 'IN',
                'time_in': currentTime,
                'time_out': '',
              });
              timeIn = currentTime;
            } else {
              // Lấy time_in nếu đã tồn tại
              timeIn = snapshot.data()?['time_in'] ?? '';
            }

            // Thêm vào danh sách hiển thị
            vehicleList.add(Vehicle(
              userRfId: userRfId,
              vehiclePlate: vehiclePlate,
              status: 'IN',
              time: timeIn,
            ));
          } else if (status.toUpperCase() == 'OUT') {
            if (snapshot.exists) {
              final currentStatus = snapshot.data()?['status'] ?? '';

              // Chỉ cập nhật khi trạng thái trong Firestore vẫn là IN
              if (currentStatus == 'IN') {
                await docRef.update({
                  'status': 'OUT',
                  'time_out': currentTime,
                });
                timeOut = currentTime;
              } else {
                // Nếu đã OUT, giữ lại time_out hiện tại
                timeOut = snapshot.data()?['time_out'] ?? '';
              }

              timeIn = snapshot.data()?['time_in'] ?? '';

              // Thêm vào danh sách hiển thị
              vehicleList.add(Vehicle(
                userRfId: userRfId,
                vehiclePlate: vehiclePlate,
                status: 'OUT',
                time: timeIn,
              )..timeOut = timeOut);
            }
          }
        }
      }

      setState(() {});
    }
  });
}




  @override
  void dispose() {
    _vehicleSubscription.cancel();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Parking History',style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),)),
      body: vehicleList.isEmpty
          ? const Center(child: Text('No vehicles found.'))
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  DataColumn(label: Text('RFID', style: ts)),
                  DataColumn(label: Text('Biển số', style: ts)),
                  DataColumn(label: Text('Trạng thái', style: ts)),
                  DataColumn(label: Text('Giờ vào', style: ts)),
                  DataColumn(label: Text('Giờ ra', style: ts)),
                  DataColumn(label: Text('Giá', style: ts)),
                ],

                rows: vehicleList.map((vehicle) {
                  double? price;
                  if (vehicle.time.isNotEmpty && vehicle.timeOut.isNotEmpty) {
                    DateTime? timeIn = TimeController.convertToDateTime(vehicle.time);
                    DateTime? timeOut = TimeController.convertToDateTime(vehicle.timeOut);

                    if (timeIn != null && timeOut != null) {
                      price = 7000;
                      if (timeIn.day != timeOut.day || timeOut.difference(timeIn).inDays >= 1) {
                        price += 10000 * timeOut.difference(timeIn).inDays;
                      }
                    }
                  }

                  return DataRow(cells: [
                    DataCell(Text(vehicle.userRfId)),
                    DataCell(Text(vehicle.vehiclePlate)),
                    DataCell(Text(vehicle.status, style: TextStyle(color: vehicle.status.toUpperCase()=='IN'?Colors.green:Colors.orange),)),
                    DataCell(Text(TimeController.convertToFormattedString(vehicle.time) ?? '')),
                    DataCell(vehicle.status.toUpperCase() == 'OUT'
                        ? Text(TimeController.convertToFormattedString(vehicle.timeOut) ?? '')
                        : Text('')),
                    DataCell(price != null ? Text('${MoneyController.formatCurrency(price.toString())} VND') : Text('Chưa xác định')),
                  ]);
                }).toList(),
              ),
            ),
    );
  }
}
