import 'package:certichain/blockchain_service.dart';  // Add this import
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

final String rpcUrl = "https://sepolia.infura.io/v3/aabc3e9ea79d47b49e17560ac7571c86";

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
  final TextEditingController _certHashController = TextEditingController();
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

      // Fetch and display latest block info
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
    final certHash = _certHashController.text.trim();
    if (certHash.isEmpty) {
      debugPrint("Certificate hash cannot be empty.");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Certificate hash cannot be empty.')),
      );
      return;
    }

    try {
      final txHash = await _blockchainService.issueCertificate(certHash);
      debugPrint("Certificate issued. Transaction hash: $txHash");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Certificate issued! TX Hash: $txHash')),
      );
    } catch (e) {
      debugPrint("Error issuing certificate: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error issuing certificate: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sertifika Listesi'),
      ),
      body: Column(
        children: [
          TextField(
            controller: _certHashController,
            decoration: InputDecoration(labelText: 'Cert Hash'),
          ),
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
    );
  }
}