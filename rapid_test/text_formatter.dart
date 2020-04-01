const String test = r' $file \n line2 \n line3';
const String test2 = ' \$file \r\n line2 \r\n line3';
const String test3 =
    '''Two message definition with the same id "%0" \n but different text have been detected. They come from the following sources:
- %1
- %2''';
const String test4 =
    '''Two message definition with the same id "%0" but different text have been detected. They come from the following sources:\n- %1\n- %2''';

void main() {
  var buffer = StringBuffer();

  buffer.writeln(test4);
  var content = buffer.toString();

  print('$content');
  var result = content.replaceAll('%1', 'replaced!');
  print(result);
}
