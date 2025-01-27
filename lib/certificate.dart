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