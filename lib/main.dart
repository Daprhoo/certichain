import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CertiChain',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('CertiChain Dashboard'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CertificateListPage()),
            );
          },
          child: Text('Sertifikaları Görüntüle'),
        ),
      ),
    );
  }
}

class CertificateListPage extends StatelessWidget {
  final List<String> certificates = [
    'Blockchain Basics - 2024-10-20',
    'Flutter Development - 2024-08-15',
    'Advanced Solidity - 2024-07-01',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sertifika Listesi'),
      ),
      body: ListView.builder(
        itemCount: certificates.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: Icon(Icons.check_circle, color: Colors.green),
            title: Text(certificates[index]),
          );
        },
      ),
    );
  }
}