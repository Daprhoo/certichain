import 'package:certichain/blockchain_service.dart'; 
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

void main() {
  runApp(MyApp());
}

final String rpcUrl = "https://sepolia.infura.io/v3/aabc3e9ea79d47b49e17560ac7571c86";

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

// Sertifika Listesi Sayfası
class CertificateListPage extends StatefulWidget {
  @override
  _CertificateListPageState createState() => _CertificateListPageState();
}

class _CertificateListPageState extends State<CertificateListPage> {
  final BlockchainService _blockchainService = BlockchainService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  String? _latestBlockInfo;

  @override
  void initState() {
    super.initState();
    _initializeBlockchain();
  }

  Future<void> _initializeBlockchain() async {
    try {
      await _blockchainService.initContract();
      final blockNumber = await _blockchainService.getLatestBlockNumber();
      debugPrint("Connected to Sepolia. Latest block: $blockNumber");

      final blockInfo = await _blockchainService.getBlockByNumber(blockNumber);
      setState(() {
        _latestBlockInfo = blockInfo;
      });
    } catch (e) {
      debugPrint("Error initializing blockchain: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error initializing blockchain: $e')),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sertifika yayınlandı! TX Hash: $txHash')),
      );
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
            if (_latestBlockInfo != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Latest Block Info: $_latestBlockInfo',
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}