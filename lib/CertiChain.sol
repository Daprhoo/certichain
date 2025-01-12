// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CertiChain {
    struct Certificate {
        string certHash;
        address issuer;
        uint256 issuedAt;
    }

    mapping(string => Certificate) private certificates;

    event CertificateIssued(string certHash, address indexed issuer, uint256 issuedAt);

    function issueCertificate(string memory certHash) public {
        require(bytes(certHash).length > 0, "Certificate hash is required");
        require(certificates[certHash].issuedAt == 0, "Certificate already exists");

        certificates[certHash] = Certificate(certHash, msg.sender, block.timestamp);

        emit CertificateIssued(certHash, msg.sender, block.timestamp);
    }

    function verifyCertificate(string memory certHash) public view returns (bool, address, uint256) {
        Certificate memory cert = certificates[certHash];
        if (cert.issuedAt == 0) {
            return (false, address(0), 0);
        }
        return (true, cert.issuer, cert.issuedAt);
    }
}