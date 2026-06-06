import 'dart:io';

void main() {
  final dir = Directory('lib');
  int replaced = 0;
  for (var file in dir.listSync(recursive: true)) {
    if (file is File && file.path.endsWith('.dart')) {
      final lines = file.readAsLinesSync();
      bool changed = false;
      for (int i = 0; i < lines.length; i++) {
        var line = lines[i];
        if (line.contains('AppColors.')) {
          // If the line contains const, let's remove const.
          // Wait, 'const AppColors.' is easy.
          if (line.contains('const AppColors.')) {
            line = line.replaceAll('const AppColors.', 'AppColors.');
            changed = true;
          }
          // If it contains const before a widget that uses AppColors...
          // For example: const Text('...', style: TextStyle(color: AppColors.primary))
          // or const BoxDecoration(color: AppColors.surface)
          // or const Icon(..., color: AppColors.navy)
          // This is a naive approach: if a line has 'const ' and 'AppColors.', replace 'const ' with ''.
          if (line.contains('const ') && line.contains('AppColors.')) {
            line = line.replaceAll('const ', '');
            changed = true;
          }
        }
        lines[i] = line;
      }
      if (changed) {
        file.writeAsStringSync(lines.join('\n'));
        replaced++;
      }
    }
  }
  print('Replaced in $replaced files');
}
