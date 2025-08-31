import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('Extract all SQL functions from the database', () async {
    // Initialize Supabase
    await Supabase.initialize(
      url: 'https://aqtwasxdpkrkavqworwm.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFxdHdhc3hkcGtya2F2cXdvcndtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTYxNjk4NzUsImV4cCI6MjA3MTc0NTg3NX0.aIL3uIycOHqhlh_2xXncOFSHmDK-_yor7eWv8SxOu_w',
    );

    final supabase = Supabase.instance.client;

    // SQL query to get function definitions
    const String sqlQuery = """
      SELECT
          n.nspname as schema_name,
          p.proname as function_name,
          pg_get_functiondef(p.oid) as function_definition
      FROM
          pg_catalog.pg_proc p
      LEFT JOIN
          pg_catalog.pg_namespace n ON n.oid = p.pronamespace
      WHERE
          n.nspname NOT IN ('pg_catalog', 'information_schema', 'pg_toast') AND p.prokind = 'f';
    """;

    try {
      final List<dynamic> result = await supabase.rpc('execute_sql', params: {'sql': sqlQuery});

      if (result.isEmpty) {
        print('No user-defined functions found.');
        return;
      }

      for (var row in result) {
        print('-- Schema: ${row['schema_name']}');
        print('-- Function: ${row['function_name']}');
        print(row['function_definition']);
        print('\n-- --------------------------------------------------\n');
      }
    } catch (e) {
      print('Error fetching functions: $e');
      fail('Failed to extract functions from the database.');
    }
  });
}
