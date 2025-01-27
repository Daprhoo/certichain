import 'package:certichain/blockchain_service.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

void main() {
  runApp(MyApp());
}

class Certificate {
  final String ownerName;
  final String certificateContent;
  final DateTime issueDate;

  Certificate({
    required this.ownerName,
    required this.certificateContent,
    required this.issueDate,
  });

  String toJson() {
    return '{"ownerName": "$ownerName", "certificateContent": "$certificateContent", "issueDate": "$issueDate"}';
  }
}

String generateCertificateHash(Certificate certificate) {
  final jsonString = certificate.toJson();
  final bytes = utf8.encode(jsonString);
  final hash = sha256.convert(bytes);
  return hash.toString();
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

class CertificateListPage extends StatefulWidget {
  @override
  _CertificateListPageState createState() => _CertificateListPageState();
}

class _CertificateListPageState extends State<CertificateListPage> {
  final BlockchainService _blockchainService = BlockchainService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  List<Map<String, dynamic>> issuedCertificates = [];
  Map<String, dynamic>? lastIssuedCertificate;

  @override
  void initState() {
    super.initState();
    _initializeBlockchain();
  }

  Future<void> _initializeBlockchain() async {
    try {
      await _blockchainService.initContract();
      debugPrint("Connected to Sepolia.");
    } catch (e) {
      debugPrint("Error initializing blockchain: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Blockchain başlatılırken hata oluştu: $e')),
      );
    }
  }

  Future<void> _issueCertificate() async {
    final ownerName = _nameController.text.trim();
    final content = _contentController.text.trim();

    if (ownerName.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lütfen tüm alanları doldurun.')),
      );
      return;
    }

    final certificate = Certificate(
      ownerName: ownerName,
      certificateContent: content,
      issueDate: DateTime.now(),
    );

    final certHash = generateCertificateHash(certificate);
    debugPrint("Generated Hash: $certHash");

    try {
      final txHash = await _blockchainService.issueCertificate(certHash);
      debugPrint("Certificate issued. Transaction hash: $txHash");

      final receipt = await _blockchainService.getTransactionReceipt(txHash);
      
      if (receipt != null && receipt['blockNumber'] != null) {
        final blockNumber = receipt['blockNumber'] as int;
        final blockInfo = await _blockchainService.getBlockByNumber(blockNumber);
        
        setState(() {
          issuedCertificates.add({
            'ownerName': ownerName,
            'certHash': certHash,
            'blockNumber': blockNumber,
            'blockInfo': blockInfo,
          });

          lastIssuedCertificate = {
            'ownerName': ownerName,
            'certHash': certHash,
            'blockNumber': blockNumber,
            'blockInfo': blockInfo,
          };
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sertifika yayınlandı! Blok: $blockNumber')),
        );
      } else {
        throw Exception("Invalid block number in transaction receipt");
      }
    } catch (e) {
      debugPrint("Error issuing certificate: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sertifika yayınlanırken hata oluştu: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sertifika Listesi'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Sertifika Sahibi Adı'),
            ),
            TextField(
              controller: _contentController,
              decoration: InputDecoration(labelText: 'Sertifika İçeriği'),
              maxLines: 3,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _issueCertificate,
              child: Text('Sertifika Yayınla'),
            ),
            SizedBox(height: 20),
            if (lastIssuedCertificate != null)
              Card(
                margin: EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Son Sertifika Sahibi: ${lastIssuedCertificate!['ownerName']}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('Sertifika Hash: ${lastIssuedCertificate!['certHash']}'),
                      Text('Blok Numarası: ${lastIssuedCertificate!['blockNumber']}'),
                      Text('Blok Detayları: ${lastIssuedCertificate!['blockInfo']}'),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: issuedCertificates.length,
                itemBuilder: (context, index) {
                  final cert = issuedCertificates[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sertifika Sahibi: ${cert['ownerName']}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('Sertifika Hash: ${cert['certHash']}'),
                          Text('Blok Numarası: ${cert['blockNumber']}'),
                          Text('Blok Detayları: ${cert['blockInfo']}'),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}