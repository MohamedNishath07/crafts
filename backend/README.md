# Backend Setup (XAMPP)

1. Install XAMPP, start Apache and MySQL.
2. Copy the `backend` folder into `C:\xampp\htdocs\crafts\backend` (or symlink).
3. Import `backend/schema.sql` into MySQL (phpMyAdmin or mysql CLI).
4. Default MySQL user root with empty password. Adjust `backend/config/db.php` if needed.
5. Endpoints:
   - POST http://localhost/crafts/backend/api/register.php
   - POST http://localhost/crafts/backend/api/login.php
6. For Android emulator use base URL http://10.0.2.2/crafts/backend/api
   For physical device use http://<your-pc-ip>/crafts/backend/api
7. Test with curl/Postman before Flutter integration.
