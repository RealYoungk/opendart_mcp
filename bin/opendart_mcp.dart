import 'package:mcp_dart/mcp_dart.dart';
import 'package:opendart_mcp/opendart_mcp.dart';

void main(List<String> args) async {
  final server = createServer();
  final transport = StdioServerTransport();
  await server.connect(transport);
}
