import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
void main() async{
  WidgetsFlutterBinding.ensureInitialized(); // Đảm bảo Flutter đã khởi tạo
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
      home: MyHomePage(),
    );
  }
}
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late DatabaseReference _databaseRef;

  @override
  void initState() {
    super.initState();
    // Khởi tạo DatabaseReference
    _databaseRef = FirebaseDatabase.instance.ref("number"); // Thay "your_data_path" bằng đường dẫn cụ thể
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: StreamBuilder(
          stream: _databaseRef.onValue,
          builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator(); // Hiển thị vòng xoay khi chờ dữ liệu
            }
            if (snapshot.hasError) {
              return Text("Lỗi: ${snapshot.error}"); // Nếu có lỗi, hiển thị lỗi
            }
            if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
              return const Text("Không có dữ liệu"); // Nếu dữ liệu rỗng, hiển thị thông báo
            }

            // Dữ liệu hợp lệ -> hiển thị
            return Text(snapshot.data!.snapshot.value.toString());
          },
        )
      ),
    );
  }
}

