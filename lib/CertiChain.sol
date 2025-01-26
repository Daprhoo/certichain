import 'package:flutter/material.dart';
import 'package:http/http.dart'; // HTTP bağlantısı için
import 'package:web3dart/web3dart.dart';

class BlockchainService {
  final String rpcUrl = "https://mainnet.infura.io/v3/YOUR_INFURA_PROJECT_ID";
  final String privateKey = "YOUR_PRIVATE_KEY";

  late Web3Client _client;
  late EthPrivateKey _credentials;
  late DeployedContract _contract;

  BlockchainService() {
    _client = Web3Client(rpcUrl, Client());
    _credentials = EthPrivateKey.fromHex(privateKey);
  }

  Future<void> initContract() async {
    // CertiChain sözleşmesinin ABI'sini ekle
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

    String contractAddress = "YOUR_CONTRACT_ADDRESS";
    final contract = DeployedContract(
      ContractAbi.fromJson(abi, "CertiChain"),
      EthereumAddress.fromHex(contractAddress),
    );
    _contract = contract;
  }

  Future<String> issueCertificate(String certHash) async {
    final function = _contract.function('issueCertificate');
    final result = await _client.sendTransaction(
      _credentials,
      Transaction.callContract(
        contract: _contract,
        function: function,
        parameters: [certHash],
      ),
    );
    return result;
  }

  Future<Map<String, dynamic>> verifyCertificate(String certHash) async {
    final function = _contract.function('verifyCertificate');
    final result = await _client.call(
      contract: _contract,
      function: function,
      params: [certHash],
    );

    return {
      'exists': result[0] as bool,
      'issuer': result[1] as EthereumAddress,
      'issuedAt': result[2] as BigInt,
    };
  }
}