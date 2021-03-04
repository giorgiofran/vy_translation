import 'package:vy_dart_meme/src/element/flavor_collection.dart';

class MessageDefinition {
  final String id;
  final String text;
  final String? description;
  final List<String>? exampleValues;
  final List<FlavorCollection>? flavorCollections;
  final Map<List<String>, String>? flavorTextPerKey;

  const MessageDefinition(this.id, this.text,
      {this.description,
      this.exampleValues,
      this.flavorCollections,
      this.flavorTextPerKey});

  @override
  bool operator ==(other) =>
      other is MessageDefinition &&
      _textRepresentation == other._textRepresentation;

  @override
  int get hashCode => _textRepresentation.hashCode;

  String get _textRepresentation => '$id#$text#'
      '${description ?? ''}#'
      '${exampleValues == null ? '' : exampleValues!.join('#')}';
}
