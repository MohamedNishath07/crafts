import re
p=r'c:\proj\crafts\lib\features\reports\reports_screen.dart'
s=open(p).read()
old="            onPressed: () {\n              // TODO: Show filter bottom sheet\n            },"
new="            onPressed: () {\n              showModalBottomSheet(\n                context: context,\n                isScrollControlled: true,\n                builder: (c) => const SizedBox(height: 200, child: Center(child: Text('Filter'))),\n              );\n            },"
assert old in s, 'pattern not found'
s=s.replace(old,new)
open(p,'w').write(s)
print('done')
