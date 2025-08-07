// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:my_app/presentation/screens/sensor_detail_screen.dart';
// import '../../models/sensor_model.dart';
// import '../widgets/sensor_card.dart';

// class SensorDashboard extends StatelessWidget {
//   const SensorDashboard({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final sensor = SensorModel(
//       id: 1,
//       name: "Lab Room",
//       temp: 25.6,
//       humidity: 59.0,
//       status: true,
//       signal: -70,
//     );

//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         title: Text(
//           "Danh sách cảm biến",
//           style: GoogleFonts.roboto(
//             color: Colors.black,
//             fontSize: 22,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         centerTitle: true,
//       ),
//       body: Column(
//         children: [
//           /// Header
//           Container(
//             color: Colors.grey[300],
//             padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
//             child: Row(
//               children: const [
//                 Expanded(
//                   flex: 4,
//                   child: Text(
//                     "Location",
//                     textAlign: TextAlign.center,
//                     style: TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                 ),
//                 Expanded(
//                   flex: 6,
//                   child: Text(
//                     "Sensor Display",
//                     textAlign: TextAlign.center,
//                     style: TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           const SizedBox(height: 10),

//           /// Card hiển thị sensor
//           Padding(
//             padding: const EdgeInsets.all(12),
//             child: GestureDetector(
//               onTap: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => SensorDetailScreen(sensor: sensor),
//                   ),
//                 );
//               },
//               child: SensorCard(sensor: sensor),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
