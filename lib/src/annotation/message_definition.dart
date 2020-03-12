class MessageDefinition {
  final String id;
  final String text;
  final String description;
  final List<String> exampleValues;

  const MessageDefinition(this.id, this.text,
      {this.description, this.exampleValues});

  @override
  bool operator ==(other) =>
      other is MessageDefinition &&
      _textRepresentation == other._textRepresentation;

  @override
  int get hashCode => _textRepresentation.hashCode;

  String get _textRepresentation => '${id ?? ''}#${text ?? ''}#'
      '${description ?? ''}#'
      '${exampleValues == null ? '' : exampleValues.join('#')}';
}
