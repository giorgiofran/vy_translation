class MessageDefinition {
  final String id;
  final String text;
  final String description;
  final List<String> exampleValues;

  const MessageDefinition(this.id, this.text,
      {this.description, this.exampleValues});
}
