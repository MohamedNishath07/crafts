import os
base = r"C:\proj\crafts\lib\features"
if os.path.exists(base):
    print("Exists:", base)
    print("Contents:", os.listdir(base))
else:
    print("Not found:", base)