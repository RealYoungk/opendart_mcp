import 'package:mcp_dart/mcp_dart.dart';
import 'package:opendart_mcp/opendart_mcp.dart';

/// Example: Run the OpenDART MCP server via stdio.
///
/// Before running, set the OPENDART_API_KEY environment variable:
/// ```bash
/// export OPENDART_API_KEY=your_api_key_here
/// dart run example/example.dart
/// ```
void main() async {
  // Create the MCP server (reads API key from OPENDART_API_KEY env var)
  final server = createServer();

  // Connect via stdio transport
  final transport = StdioServerTransport();
  await server.connect(transport);
}
