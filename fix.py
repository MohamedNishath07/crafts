p='lib/features/dashboard/dashboard_report_screen.dart'
s=open(p).read()
s=s.replace("import 'package:flutter/material.dart';\n", "import 'package:supabase_flutter/supabase_flutter.dart';\nimport 'package:flutter/material.dart';\n",1)
s=s.replace('final allRows = ReportFilter.generateRows(', 'final allRows = TabularReportGenerator.generateRows(')
s=s.replace('    final dataTable = _buildDataTable(context);\n    final exportSection = _buildExportSection(context);', '    final dataTable = Container();\n    final exportSection = Container();')
s=s.replace('  Widget _selectDateRange(BuildContext context) async {', '  Future<void> _selectDateRange(BuildContext context) async {')
old = "lastDate: DateTime.now().add(duration: Duration(days: 1)),\n       currentRangeStart: _startDate,\n       currentRangeEnd: _endDate,"
new = "lastDate: DateTime.now().add(const Duration(days: 1)),\n      initialDateRange: _startDate != None and _endDate != None and __import__('datetime').datetime and None or None,"
s=s.replace(old,new)
open(p,'w').write(s)
print('done')
