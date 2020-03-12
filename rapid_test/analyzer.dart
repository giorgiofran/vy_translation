import 'dart:io' show Directory, File, Platform, exit;

import 'package:analyzer/dart/analysis/analysis_context_collection.dart'
    show AnalysisContextCollection;
import 'package:analyzer/dart/analysis/analysis_context.dart'
    show AnalysisContext;
import 'package:analyzer/dart/analysis/session.dart' show AnalysisSession;
import 'package:analyzer/dart/analysis/results.dart'
    show ParsedUnitResult, ResolvedUnitResult;
import 'package:analyzer/dart/ast/ast.dart' show Annotation, CompilationUnit;
import 'package:analyzer/dart/ast/visitor.dart' show GeneralizingAstVisitor;
import 'package:analyzer/file_system/physical_file_system.dart'
    show PhysicalResourceProvider;

import 'package:logging/logging.dart' show Level, Logger;
import 'package:vy_analyzer_utils/vy_analyzer_utils.dart'
    show DartSourceAnalysis;
import 'package:yaml/yaml.dart';

String formatTimeRef(DateTime time) {
  String timeString = time.toIso8601String().replaceAll('T', ' ');
  int dotIndex = timeString.indexOf('.');
  return timeString.substring(0, dotIndex);
}

Future<void> main(List<String> args) async {
  Logger.root.level = Level.ALL; // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    print(
        '${record.level.name}: ${formatTimeRef(record.time)}: ${record.message}');
  });
  AnalysisContextCollection collection =
      getAnalysisContextCollection(Directory.current);
/*  analyzeSomeFiles(collection, [
    '/home/giorgio/dart-projects/git/vy_translation/lib/src/abstract/translation_abstract.dart'
  ]);*/

  //analyzeAllFiles(collection);


  //await executeDsa(Directory.current);
  try {
    Directory current = Directory.current;
    File yamlFile = File('${current.path}/vy_translation.yaml');
    bool existsYaml = yamlFile.existsSync();
    if (!existsYaml) {
      throw StateError(
          'Missing file "vy_translation.yaml" in project directory (${current.path})');
    }
    List<String> data = yamlFile.readAsLinesSync();
    YamlMap doc = loadYaml(data.join('\n'));
    // if .yaml file is empty, loadYaml() returns null;
    /*Parameters parms =*/ //extractYamlValues(doc ?? {}, current);
    await executeDsa(Directory.current);
  } catch (e, stack) {
    print('$e\n$stack');
    exit(1);
  }
  exit(0);
}

Future<void> executeDsa(Directory dir) async {
  DartSourceAnalysis dsa = DartSourceAnalysis(AnnotationRetriever(),
      resolvedAnalysis: true, dir: dir);
  await dsa.run();
}

analyzeSomeFiles(
    AnalysisContextCollection collection, List<String> includedPaths) async {
  for (String path in includedPaths) {
    AnalysisContext context = collection.contextFor(path);
    await analyzeSingleFile(context, path);
  }
}

Future<void> analyzeAllFiles(AnalysisContextCollection collection) async {
  for (AnalysisContext context in collection.contexts) {
    for (String path in context.contextRoot.analyzedFiles()) {
      await analyzeSingleFile(context, path);
    }
  }
}

analyzeSingleFile(AnalysisContext context, String path) async {
  AnalysisSession session = context.currentSession;
  //processUnresolvedFile(session, path);
  await processResolvedFile(session, path);
}

/// Unresolved AST
processUnresolvedFile(AnalysisSession session, String path) {
  ParsedUnitResult result = session.getParsedUnit(path);
  CompilationUnit unit = result.unit;
}

/// Resolved AST
processResolvedFile(AnalysisSession session, String path) async {
  ResolvedUnitResult result = await session.getResolvedUnit(path);
  CompilationUnit unit = result.unit;
  unit.accept<void>(AnnotationRetriever());
}

class AnnotationRetriever extends GeneralizingAstVisitor<void> {
  @override
  void visitAnnotation(Annotation visitAnnotation) {
    var parent = visitAnnotation.parent;
    String string;
    while (parent != null) {
      if (parent is CompilationUnit) {
        string = parent.declaredElement.source.fullName;
        break;
      }
      parent = parent.parent;
    }
    print('$string - $visitAnnotation');
    super.visitAnnotation(visitAnnotation);
  }
}

AnalysisContextCollection getAnalysisContextCollection(Directory directory) {
  var path = PhysicalResourceProvider.INSTANCE.pathContext.normalize(
      directory.absolute.uri.toFilePath(windows: Platform.isWindows));
  return AnalysisContextCollection(includedPaths: [path]);
}
