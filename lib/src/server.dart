import 'dart:io';
import 'package:mcp_dart/mcp_dart.dart';
import 'client/opendart_client.dart';
import 'tools/disclosure.dart';
import 'tools/financial.dart';
import 'tools/major_event.dart';
import 'tools/ownership.dart';
import 'tools/periodic_report.dart';
import 'tools/securities_reg.dart';

/// Creates and configures the OpenDART MCP server.
///
/// The [apiKey] is used for all OpenDART API requests.
/// If not provided, reads from the `OPENDART_API_KEY` environment variable.
McpServer createServer({String? apiKey}) {
  final key = apiKey ?? Platform.environment['OPENDART_API_KEY'];
  if (key == null || key.isEmpty) {
    throw ArgumentError(
      'OpenDART API key is required. '
      'Set OPENDART_API_KEY environment variable or pass it directly.',
    );
  }

  final client = OpenDartClient(apiKey: key);

  final server = McpServer(
    Implementation(name: 'opendart-mcp', version: '0.1.0'),
    options: ServerOptions(
      capabilities: ServerCapabilities(
        tools: ServerCapabilitiesTools(),
      ),
    ),
  );

  // Register all tool groups
  registerDisclosureTools(server, client); // DS001: 공시정보
  registerPeriodicReportTools(server, client); // DS002: 정기보고서 주요정보
  registerFinancialTools(server, client); // DS003: 재무정보
  registerOwnershipTools(server, client); // DS004: 지분공시
  registerMajorEventTools(server, client); // DS005: 주요사항보고서
  registerSecuritiesRegTools(server, client); // DS006: 증권신고서

  return server;
}
