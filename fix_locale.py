import re

# Fix appointment_service.dart - replace hardcoded Kannada with AppLocale.l()
f = r'd:\bharatheeyamapp sample\lib\services\appointment_service.dart'
with open(f, 'r', encoding='utf-8') as fh:
    c = fh.read()

pairs = [
    ("'🆔 ಗ್ರಾಹಕ ID: ${appt.clientId}\\n'", "'🆔 ${AppLocale.l(\"waClientId\")}: ${appt.clientId}\\n'"),
    ("'ನಮಸ್ಕಾರ ${appt.clientName},\\n\\n'", "'${AppLocale.l(\"bookingMsgNamaskara\")} ${appt.clientName},\\n\\n'"),
    ("'ನಿಮ್ಮ ಅಪಾಯಿಂಟ್\\u200cಮೆಂಟ್ ದೃಢಪಡಿಸಲಾಗಿದೆ ✅\\n\\n'", "'${AppLocale.l(\"waConfirmed\")}\\n\\n'"),
    ("'📅 ದಿನಾಂಕ: ${appt.dateStr}\\n'", "'📅 ${AppLocale.l(\"waDate\")}: ${appt.dateStr}\\n'"),
    ("'⏰ ಸಮಯ: ${appt.timeRange}\\n'", "'⏰ ${AppLocale.l(\"waTime\")}: ${appt.timeRange}\\n'"),
    ("'ದಯವಿಟ್ಟು ಸಮಯಕ್ಕೆ ಸರಿಯಾಗಿ ಬನ್ನಿ.\\n\\n'", "'${AppLocale.l(\"waComeOnTime\")}\\n\\n'"),
    ("'- ಭಾರತೀಯಮ್ ✨'", "'${AppLocale.l(\"bookingMsgSign\")}'"),
    ("'ನಿಮ್ಮ ಅಪಾಯಿಂಟ್\\u200cಮೆಂಟ್ ನಾಳೆಯ ಜ್ಞಾಪನೆ 🔔\\n\\n'", "'${AppLocale.l(\"waReminder\")}\\n\\n'"),
    ("return 'ಈ ದಿನಾಂಕದಲ್ಲಿ ಯಾವುದೇ ಸ್ಲಾಟ್ ಲಭ್ಯವಿಲ್ಲ.';", "return AppLocale.l('waNoSlots');"),
    ("'ನಮಸ್ಕಾರ,\\n\\n'", "'${AppLocale.l(\"bookingMsgNamaskara\")}\\n\\n'"),
    ("'📅 $dateStr ದಿನಾಂಕದಲ್ಲಿ ಲಭ್ಯವಿರುವ ಸ್ಲಾಟ್\u200cಗಳು:\\n\\n'", "'📅 $dateStr ${AppLocale.l(\"waSlotsOn\")}\\n\\n'"),
    ("'ಬುಕ್ ಮಾಡಲು ದಯವಿಟ್ಟು ಸಂಪರ್ಕಿಸಿ.\\n\\n'", "'${AppLocale.l(\"waBookContact\")}\\n\\n'"),
    ("'- ಭಾರತೀಯಮ್ ✨';", "'${AppLocale.l(\"bookingMsgSign\")}';"),
    # Weekly calendar
    ("const dayNames = ['ಸೋಮವಾರ', 'ಮಂಗಳವಾರ', 'ಬುಧವಾರ', 'ಗುರುವಾರ', 'ಶುಕ್ರವಾರ', 'ಶನಿವಾರ', 'ರವಿವಾರ'];",
     "final dayNames = [AppLocale.l('dayFullMon'), AppLocale.l('dayFullTue'), AppLocale.l('dayFullWed'), AppLocale.l('dayFullThu'), AppLocale.l('dayFullFri'), AppLocale.l('dayFullSat'), AppLocale.l('dayFullSun')];"),
    ("const months = ['ಜನವರಿ', 'ಫೆಬ್ರವರಿ', 'ಮಾರ್ಚ್', 'ಏಪ್ರಿಲ್', 'ಮೇ', 'ಜೂನ್', 'ಜುಲೈ', 'ಆಗಸ್ಟ್', 'ಸೆಪ್ಟೆಂಬರ್', 'ಅಕ್ಟೋಬರ್', 'ನವೆಂಬರ್', 'ಡಿಸೆಂಬರ್'];",
     "final months = [AppLocale.l('month0'), AppLocale.l('month1'), AppLocale.l('month2'), AppLocale.l('month3'), AppLocale.l('month4'), AppLocale.l('month5'), AppLocale.l('month6'), AppLocale.l('month7'), AppLocale.l('month8'), AppLocale.l('month9'), AppLocale.l('month10'), AppLocale.l('month11')];"),
    # Calendar titles/instructions
    ("buf.writeln('🙏 *ಭಾರತೀಯಮ್ - ಅಪಾಯಿಂಟ್\\u200cಮೆಂಟ್ ಕ್ಯಾಲೆಂಡರ್*');", "buf.writeln('🙏 *${AppLocale.l(\"waCalTitle\")}*');"),
    ("buf.writeln('ಕೆಳಗಿನ ದಿನಾಂಕಗಳಲ್ಲಿ ಲಭ್ಯವಿರುವ ಸಮಯಗಳನ್ನು ನೋಡಿ.');", "buf.writeln(AppLocale.l('waCalView'));"),
    ("buf.writeln('ನಿಮಗೆ ಬೇಕಾದ ದಿನಾಂಕ ಮತ್ತು ಸಮಯವನ್ನು ಆಯ್ಕೆ ಮಾಡಿ ಉತ್ತರಿಸಿ.');", "buf.writeln(AppLocale.l('waCalSelect'));"),
    ("buf.writeln('❌ ಮುಂದಿನ $days ದಿನಗಳಲ್ಲಿ ಯಾವುದೇ ಸ್ಲಾಟ್ ಲಭ್ಯವಿಲ್ಲ.');", "buf.writeln('❌ ${AppLocale.l(\"waCalNoSlots\").replaceAll(\"{d}\", days.toString())}');"),
    ("buf.writeln('ಬುಕ್ ಮಾಡಲು: ನಿಮ್ಮ ಹೆಸರು, ಫೋನ್ ಸಂಖ್ಯೆ, ಮತ್ತು ಬೇಕಾದ ದಿನಾಂಕ+ಸಮಯವನ್ನು ಕಳುಹಿಸಿ.');", "buf.writeln(AppLocale.l('waCalBook'));"),
    ("buf.writeln('- *ಭಾರತೀಯಮ್* ✨');", "buf.writeln('- *${AppLocale.l(\"bookingMsgSign\")}*');"),
    # Custom calendar
    ("buf.writeln('⏰ ಸಮಯ: ${_fmt(fromHour, fromMinute)} - ${_fmt(toHour, toMinute)}');", "buf.writeln('⏰ ${AppLocale.l(\"waTime\")}: ${_fmt(fromHour, fromMinute)} - ${_fmt(toHour, toMinute)}');"),
    ("buf.writeln('ನಿಮಗೆ ಬೇಕಾದ ಸ್ಲಾಟ್ ಆಯ್ಕೆ ಮಾಡಿ ಉತ್ತರಿಸಿ.');", "buf.writeln(AppLocale.l('waCalSlotSel'));"),
    ("buf.writeln('❌ ಈ ಅವಧಿಯಲ್ಲಿ ಯಾವುದೇ ಸ್ಲಾಟ್ ಲಭ್ಯವಿಲ್ಲ.');", "buf.writeln('❌ ${AppLocale.l(\"waCalNoSlotsP\")}');"),
    ("buf.writeln('*ಬುಕ್ ಮಾಡಲು:*');", "buf.writeln('*${AppLocale.l(\"waCalBookTo\")}*');"),
    ("buf.writeln('✅ ನಿಮಗೆ ಬೇಕಾದ ಸ್ಲಾಟ್ ಆಯ್ಕೆ ಮಾಡಿ');", "buf.writeln('✅ ${AppLocale.l(\"waCalSelSlot\")}');"),
    ("buf.writeln('✅ ನಿಮ್ಮ ಹೆಸರು ಮತ್ತು ಫೋನ್ ಸಂಖ್ಯೆ ಕಳುಹಿಸಿ');", "buf.writeln('✅ ${AppLocale.l(\"waCalSendInfo\")}');"),
]

for old, new in pairs:
    if old in c:
        c = c.replace(old, new)
        print(f"OK Replaced: {ascii(old[:30])}...")
    else:
        print(f"MISS: {ascii(old[:30])}...")

with open(f, 'w', encoding='utf-8') as fh:
    fh.write(c)

print("\nDone! appointment_service.dart updated.")
