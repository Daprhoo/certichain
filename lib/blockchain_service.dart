import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';

class BlockchainService {
  final String rpcUrl = "https://sepolia.infura.io/v3/aabc3e9ea79d47b49e17560ac7571c86";
  final String privateKey = "c6c1e1a155a6322c3ee1d22b2af9a0ac7210a08db1344f64b2d24e6160215168";

  late Web3Client _client;
  late EthPrivateKey _credentials;
  late DeployedContract _contract;

  BlockchainService() {
    _client = Web3Client(rpcUrl, Client());
    _credentials = EthPrivateKey.fromHex(privateKey);
  }

  /// Initializes the contract using the ABI and contract address
  Future<void> initContract() async {
    try {
      String abi = '''
        [
          {
            "inputs": [{"internalType": "string","name": "certHash","type": "string"}],
            "name": "issueCertificate",
            "outputs": [],
            "stateMutability": "nonpayable",
            "type": "function"
          },
          {
            "inputs": [{"internalType": "string","name": "certHash","type": "string"}],
            "name": "verifyCertificate",
            "outputs": [
              {"internalType": "bool","name": "","type": "bool"},
              {"internalType": "address","name": "","type": "address"},
              {"internalType": "uint256","name": "","type": "uint256"}
            ],
            "stateMutability": "view",
            "type": "function"
          }
        ]
      ''';

      String contractAddress = "0xeee005B3E73ff8a6130A31f94B3Ce9A13df1282F";
      _contract = DeployedContract(
        ContractAbi.fromJson(abi, "CertiChain"),
        EthereumAddress.fromHex(contractAddress),
      );

      debugPrint("Contract initialized successfully at address: $contractAddress");
    } catch (e) {
      debugPrint("Error initializing contract: $e");
      throw Exception("Error initializing contract: $e");
    }
  }

  /// Issues a certificate by sending a transaction to the contract
  Future<String> issueCertificate(String certHash) async {
    if (certHash.isEmpty) {
      throw Exception("Certificate hash cannot be empty.");
    }

    try {
      final function = _contract.function('issueCertificate');
      debugPrint("Issuing certificate with hash: $certHash");

      final result = await _client.sendTransaction(
        _credentials,
        Transaction.callContract(
          contract: _contract,
          function: function,
          parameters: [certHash],
        ),
        chainId: 11155111, // Sepolia chainId
      );

      debugPrint("Certificate issued. Transaction hash: $result");
      return result;
    } catch (e) {
      debugPrint("Error issuing certificate: $e");
      throw Exception("Error issuing certificate: $e");
    }
  }

  /// Verifies a certificate by calling the smart contract function
  Future<Map<String, dynamic>> verifyCertificate(String certHash) async {
    if (certHash.isEmpty) {
      throw Exception("Certificate hash cannot be empty.");
    }

    try {
      final function = _contract.function('verifyCertificate');
      debugPrint("Verifying certificate with hash: $certHash");

      final result = await _client.call(
        contract: _contract,
        function: function,
        params: [certHash],
      );

      debugPrint("Certificate verification result: $result");

      return {
        'exists': result[0] as bool,
        'issuer': result[1] as EthereumAddress,
        'issuedAt': result[2] as BigInt,
      };
    } catch (e) {
      debugPrint("Error verifying certificate: $e");
      throw Exception("Error verifying certificate: $e");
    }
  }

  /// Gets the latest block number on the blockchain
  Future<int> getLatestBlockNumber() async {
    try {
      final blockNumber = await _client.getBlockNumber();
      debugPrint("Latest block number: $blockNumber");
      return blockNumber;
    } catch (e) {
      debugPrint("Error fetching latest block number: $e");
      throw Exception("Error fetching latest block number: $e");
    }
  }
/// Gets detailed information of a block by its number
Future<String> getBlockByNumber(int blockNumber) async {
  try {
    // Fetch block details via RPC call
    final blockData = await _client.makeRPCCall(
      'eth_getBlockByNumber', 
      [
        '0x${blockNumber.toRadixString(16)}', // Convert to hex
        true // Include full transaction details
      ]
    );

    final formattedBlockInfo = '''
      Block Number: $blockNumber
      Hash: ${blockData['hash']}
      Timestamp: ${DateTime.fromMillisecondsSinceEpoch(int.parse(blockData['timestamp'].substring(2), radix: 16) * 1000)}
      Transactions: ${blockData['transactions'].length}
    ''';

    debugPrint("Block info: $formattedBlockInfo");
    return formattedBlockInfo;
  } catch (e) {
    debugPrint("Error fetching block by number: $e");
    throw Exception("Error fetching block by number: $e");
  }
}
}