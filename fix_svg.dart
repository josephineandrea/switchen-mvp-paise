import 'dart:io';

void main() {
  var file = File('assets/images/hero_illustration.svg');
  if (!file.existsSync()) {
    print("File not found!");
    return;
  }
  var content = file.readAsStringSync();
  
  Map<String, String> styles = {
    'cls-1': 'fill="#fcf4f2"',
    'cls-2': 'fill="none" stroke="#783838" stroke-linecap="round" stroke-linejoin="round" stroke-width="0.82px"',
    'cls-3': 'fill="#443636"',
    'cls-4': 'fill="#e52828"',
    'cls-5': 'fill="#edaa9f"',
    'cls-6': 'fill="#ffe0d2"',
    'cls-7': 'fill="#f65d33"',
    'cls-8': 'fill="#441e1e"',
    'cls-9': 'fill="none" stroke-linecap="round" stroke-linejoin="round" stroke="#441e1e" stroke-width="1.63px"',
    'cls-10': 'fill="none" stroke-linecap="round" stroke-linejoin="round" stroke-width="0.82px" stroke="#441e1e"',
    'cls-11': 'clip-path="url(#clip-path)"',
    'cls-12': 'fill="none" stroke="#9bbe50" stroke-miterlimit="10" stroke-width="0.49px"',
    'cls-13': 'fill="#783838"',
    'cls-14': 'fill="#faa149"',
    'cls-15': 'fill="#f9ba55"',
    'cls-16': 'fill="#e5421c"',
    'cls-17': 'fill="#fcc34f"',
    'cls-18': 'fill="#e4b752"',
    'cls-19': 'fill="#55997c"',
    'cls-20': 'fill="#8dd3b7"',
    'cls-21': 'fill="#cc9671"',
    'cls-22': 'fill="none" stroke-linecap="round" stroke-linejoin="round" stroke-width="0.82px" stroke="#89532e"',
    'cls-23': 'fill="#9bbe50"',
    'cls-24': 'fill="none" stroke-linecap="round" stroke-linejoin="round" stroke-width="0.82px" stroke="#3a3030"',
  };

  for (var entry in styles.entries) {
    content = content.replaceAll('class="${entry.key}"', entry.value);
  }
  
  // Remove the <style>...</style> block
  content = content.replaceAll(RegExp(r'<style>.*?</style>', dotAll: true), '');
  
  file.writeAsStringSync(content);
  print("SVG fixed successfully!");
}
