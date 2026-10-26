cd C:\proj\crafts\flutter\bin
flutter run -d windows > run_output.txt 2>&1
timeout /t 30 /nobreak > nul
echo.
echo=== FLUTTER RUN OUTPUT ===
type run_output.txt