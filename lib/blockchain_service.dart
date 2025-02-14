import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';

class BlockchainService {
  final String rpcUrl = "replace here with sepholi url it changes before making repo public";
  final String privateKey = "replace here with your private key it changes before making repo public";

  late Web3Client _client;
  late EthPrivateKey _credentials;
  late DeployedContract _contract;

  BlockchainService() {
    _client = Web3Client(rpcUrl, Client());
    _credentials = EthPrivateKey.fromHex(privateKey);
  }

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

      String contractAddress = "replace here with your contract adress it changes before making repo public";
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

  Future<Map<String, dynamic>?> getTransactionReceipt(String transactionHash, {int maxAttempts = 80}) async {
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        final receipt = await _client.getTransactionReceipt(transactionHash);
        if (receipt != null) {
          debugPrint("Transaction receipt found on attempt ${attempt + 1}: $receipt");
          
          int? blockNumberInt;
          if (receipt.blockNumber != null) {
            blockNumberInt = receipt.blockNumber!.blockNum;
          }
          
          return {
            'status': receipt.status,
            'blockNumber': blockNumberInt,
            'transactionHash': receipt.transactionHash,
            'from': receipt.from,
            'to': receipt.to,
          };
        }
        
        debugPrint("Receipt not found, attempt ${attempt + 1}/$maxAttempts. Waiting...");
        await Future.delayed(Duration(seconds: 2));
      } catch (e) {
        debugPrint("Error in attempt ${attempt + 1}: $e");
      }
    }
    
    debugPrint("Failed to get transaction receipt after $maxAttempts attempts");
    return null;
  }

  Future<String> issueCertificate(String certHash) async {
    if (certHash.isEmpty) {
      throw Exception("Certificate hash cannot be empty.");
    }

    try {
      final function = _contract.function('issueCertificate');
      debugPrint("Issuing certificate with hash: $certHash");

      final txHash = await _client.sendTransaction(
        _credentials,
        Transaction.callContract(
          contract: _contract,
          function: function,
          parameters: [certHash],
        ),
        chainId: 11155111, // Sepolia chain ID
      );

      debugPrint("Certificate issued. Transaction hash: $txHash");
      
      // Wait for receipt with retry mechanism
      final receipt = await getTransactionReceipt(txHash);
      if (receipt == null) {
        throw Exception("Failed to get transaction receipt after multiple attempts");
      }
      
      return txHash;
    } catch (e) {
      debugPrint("Error issuing certificate: $e");
      throw Exception("Error issuing certificate: $e");
    }
  }

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

  Future<String> getBlockByNumber(int blockNumber) async {
    try {
      final blockData = await _client.makeRPCCall(
        'eth_getBlockByNumber', 
        [
          '0x${blockNumber.toRadixString(16)}', 
          true 
        ]
      );

      if (blockData == null) {
        throw Exception("Block data not found");
      }

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
