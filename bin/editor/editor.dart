import 'dart:io';
import 'dart:math' show min;

import 'console_extension.dart';
import 'package:dart_console/dart_console.dart';

const translateVersion = '0.3.1';
const translateTabStopLength = 4;

//
// GLOBAL VARIABLES
//

final console = Console();

String messageId = '';
bool isSentenceDirty = false;

// We keep two copies of the file contents, as follows:
//
// fileRows represents the actual contents of the document
//
// renderRows represents what we'll render on screen. This may be different to
// the actual contents of the file. For example, tabs are rendered as a series
// of spaces even though they are only one character; control characters may
// be shown in some form in the future.
var sentenceRows = <String>[];
var renderRows = <String>[];

// Cursor location relative to file (not the screen)
int cursorCol = 0, cursorRow = 0;
// First editable row
int editorFirstRow = 2;

// Also store cursor column position relative to the rendered row
int cursorRenderCol = 0;

// The row in the file that is currently at the top of the screen
int screenFileRowOffset = 0;
// The column in the row that is currently on the left of the screen
int screenRowColOffset = 0;

// Allow lines for the status bar and message bar
final editorWindowHeight = console.windowHeight - 2;
final editorWindowWidth = console.windowWidth;

// Index of the row last find match was on, or -1 if no match
int findLastMatchRow = -1;

// Current search direction
enum FindDirection { forwards, backwards }
var findDirection = FindDirection.forwards;

String messageText = '';
DateTime? messageTimestamp;

void initEditor() {
  isSentenceDirty = false;
  sentenceRows.clear();
  renderRows.clear();
  cursorCol = 0;
  cursorRow = 0;
  editorFirstRow = 2;
  cursorRenderCol = 0;
  screenFileRowOffset = 0;
  screenRowColOffset = 0;
  messageText = '';
  findLastMatchRow = -1;
}

void crash(String message) {
  console.clearScreen();
  console.resetCursorPosition();
  console.rawMode = false;
  console.write(message);
  exit(1);
}

String truncateString(String text, int length) =>
    length < text.length ? text.substring(0, length) : text;

//
// EDITOR OPERATIONS
//
void editorInsertChar(String char) {
  if (cursorRow == sentenceRows.length) {
    sentenceRows.add(char);
    renderRows.add(char);
  } else {
    sentenceRows[cursorRow] = sentenceRows[cursorRow].substring(0, cursorCol) +
        char +
        sentenceRows[cursorRow].substring(cursorCol);
  }
  editorUpdateRenderRow(cursorRow);
  cursorCol++;
  isSentenceDirty = true;
}

void editorBackspaceChar() {
  // If we're past the end of the file, then there's nothing to delete
  if (cursorRow == sentenceRows.length) return;

  // Nothing to do if we're at the first character of the file
  if (cursorCol == 0 && cursorRow >= editorFirstRow /* == 0 */) return;

  if (cursorCol > 0) {
    sentenceRows[cursorRow] =
        sentenceRows[cursorRow].substring(0, cursorCol - 1) +
            sentenceRows[cursorRow].substring(cursorCol);
    editorUpdateRenderRow(cursorRow);
    cursorCol--;
  } else {
    // delete the carriage return by appending the current line to the previous
    // one and then removing the current line altogether.
    cursorCol = sentenceRows[cursorRow - 1].length;
    sentenceRows[cursorRow - 1] += sentenceRows[cursorRow];
    editorUpdateRenderRow(cursorRow - 1);
    sentenceRows.removeAt(cursorRow);
    renderRows.removeAt(cursorRow);
    cursorRow--;
  }
  isSentenceDirty = true;
}

void editorInsertNewline() {
  if (cursorCol == 0) {
    sentenceRows.insert(cursorRow, '');
    renderRows.insert(cursorRow, '');
  } else {
    sentenceRows.insert(
        cursorRow + 1, sentenceRows[cursorRow].substring(cursorCol));
    sentenceRows[cursorRow] = sentenceRows[cursorRow].substring(0, cursorCol);

    renderRows.insert(cursorRow + 1, '');
    editorUpdateRenderRow(cursorRow);
    editorUpdateRenderRow(cursorRow + 1);
  }
  cursorRow++;
  cursorCol = 0;
}

void editorFindCallback(String query, Key key) {
  if (key.controlChar == ControlCharacter.enter ||
      key.controlChar == ControlCharacter.escape) {
    findLastMatchRow = -1;
    findDirection = FindDirection.forwards;
    return;
  } else if (key.controlChar == ControlCharacter.arrowRight ||
      key.controlChar == ControlCharacter.arrowDown) {
    findDirection = FindDirection.forwards;
  } else if (key.controlChar == ControlCharacter.arrowLeft ||
      key.controlChar == ControlCharacter.arrowUp) {
    findDirection = FindDirection.backwards;
  } else {
    findLastMatchRow = -1;
    findDirection = FindDirection.forwards;
  }

  if (findLastMatchRow == -1) findDirection = FindDirection.forwards;

  var currentRow = findLastMatchRow;
  if (query.isNotEmpty) {
    // we loop through all the rows, rotating back to the beginning/end as
    // necessary
    for (var i = 0; i < renderRows.length; i++) {
      if (findDirection == FindDirection.forwards) {
        currentRow++;
      } else {
        currentRow--;
      }

      if (currentRow == -1) {
        currentRow = sentenceRows.length - 1;
      } else if (currentRow == sentenceRows.length) {
        currentRow = 0;
      }

      if (renderRows[currentRow].contains(query)) {
        findLastMatchRow = currentRow;
        cursorRow = currentRow;
        cursorCol =
            getFileCol(currentRow, renderRows[currentRow].indexOf(query));
        screenFileRowOffset = sentenceRows.length;
        editorSetStatusMessage(
            'Search (ESC to cancel, use arrows for prev/next): $query');
        editorRefreshScreen();
        break;
      }
    }
  }
}

void editorFind() {
  var savedCursorCol = cursorCol;
  var savedCursorRow = cursorRow;
  var savedScreenFileRowOffset = screenFileRowOffset;
  var savedScreenRowColOffset = screenRowColOffset;

  final query = editorPrompt(
      'Search (ESC to cancel, use arrows for prev/next): ', editorFindCallback);

  if (query.isEmpty) {
    // Escape pressed
    cursorCol = savedCursorCol;
    cursorRow = savedCursorRow;
    screenFileRowOffset = savedScreenFileRowOffset;
    screenRowColOffset = savedScreenRowColOffset;
  }
}

//
// set initial value
//
void editorSet(String initialValue) {
  sentenceRows = initialValue.split(RegExp(r'\r?\n'));

  //final file = File(filename);
  //try {
  //fileRows = file.readAsLinesSync();
  //} on FileSystemException catch (e) {
  //editorSetStatusMessage('Error opening file: $e');
  //return;
  // }

  editorFirstRow = 2;
  for (var rowIndex = 0; rowIndex < sentenceRows.length; rowIndex++) {
    renderRows.add('');
    if (sentenceRows[rowIndex].endsWith('**********')) {
      editorFirstRow = rowIndex + 1;
    }
    editorUpdateRenderRow(rowIndex, doNotCheckRows: true);
  }
  cursorRow = editorFirstRow;

  assert(sentenceRows.length == renderRows.length);

  isSentenceDirty = false;
}

//
// FILE I/O
//
/* void editorOpen(String filename) {
  final file = File(filename);
  try {
    sentenceRows = file.readAsLinesSync();
  } on FileSystemException catch (e) {
    editorSetStatusMessage('Error opening file: $e');
    return;
  }

  for (var rowIndex = 0; rowIndex < sentenceRows.length; rowIndex++) {
    renderRows.add('');
    editorUpdateRenderRow(rowIndex);
  }

  assert(sentenceRows.length == renderRows.length);

  isSentenceDirty = false;
} */

/* void editorSave() async {
  if (editedFilename.isEmpty) {
    editedFilename = editorPrompt('Save as: ');
    if (editedFilename == null) {
      editorSetStatusMessage('Save aborted.');
      return;
    }
  }

  // TODO: This is hopelessly naive, as with kilo.c. We should write to a
  //    temporary file and rename to ensure that we have written successfully.
  final file = File(editedFilename);
  final fileContents = '${sentenceRows.join('\n')}\n';
  file.writeAsStringSync(fileContents);

  isSentenceDirty = false;

  editorSetStatusMessage('${fileContents.length} bytes written to disk.');
} */

void editorQuit() {
  if (isSentenceDirty) {
    editorSetStatusMessage('File is unsaved. Quit anyway (y or n)?');
    editorRefreshScreen();
    final response = console.readKey();
    if (response.char != 'y' && response.char != 'Y') {
      isSentenceDirty = false;
      editorSetStatusMessage('');
      return;
    }
  }
  console.clearScreen();
  console.resetCursorPosition();
  console.rawMode = false;
}

//
// RENDERING OPERATIONS
//

// Takes a column in a given row of the file and converts it to the rendered
// column. For example, if the file contains \t\tFoo and tab stops are
// configured to display as eight spaces, the 'F' should display as rendered
// column 16 even though it is only the third character in the file.
int getRenderedCol(int fileRow, int fileCol) {
  var col = 0;

  if (fileRow >= sentenceRows.length) return 0;

  var rowText = sentenceRows[fileRow];
  for (var i = 0; i < fileCol; i++) {
    if (rowText[i] == '\t') {
      col += (translateTabStopLength - 1) - (col % translateTabStopLength);
    }
    col++;
  }
  return col;
}

// Inversion of the getRenderedCol method. Converts a rendered column index
// into its corresponding position in the file.
int getFileCol(int row, int renderCol) {
  var currentRenderCol = 0;
  int fileCol;
  var rowText = sentenceRows[row];
  for (fileCol = 0; fileCol < rowText.length; fileCol++) {
    if (rowText[fileCol] == '\t') {
      currentRenderCol += (translateTabStopLength - 1) -
          (currentRenderCol % translateTabStopLength);
    }
    currentRenderCol++;

    if (currentRenderCol > renderCol) return fileCol;
  }
  return fileCol;
}

void editorUpdateRenderRow(int rowIndex, {bool? doNotCheckRows}) {
  var _doNotCheckRows = doNotCheckRows ?? false;

  assert(_doNotCheckRows || renderRows.length == sentenceRows.length);

  var renderBuffer = '';
  final fileRow = sentenceRows[rowIndex];

  for (var fileCol = 0; fileCol < fileRow.length; fileCol++) {
    if (fileRow[fileCol] == '\t') {
      // Add at least one space for the tab stop, plus as many more as needed to
      // get to the next tab stop
      renderBuffer += ' ';
      while (renderBuffer.length % translateTabStopLength != 0) {
        renderBuffer += ' ';
      }
    } else {
      renderBuffer += fileRow[fileCol];
    }
    renderRows[rowIndex] = renderBuffer;
  }
}

void editorScroll() {
  cursorRenderCol = 0;

  if (cursorRow < sentenceRows.length) {
    cursorRenderCol = getRenderedCol(cursorRow, cursorCol);
  }

  if (cursorRow < screenFileRowOffset) {
    screenFileRowOffset = cursorRow;
  }

  if (cursorRow >= screenFileRowOffset + editorWindowHeight) {
    screenFileRowOffset = cursorRow - editorWindowHeight + 1;
  }

  if (cursorRenderCol < screenRowColOffset) {
    screenRowColOffset = cursorRenderCol;
  }

  if (cursorRenderCol >= screenRowColOffset + editorWindowWidth) {
    screenRowColOffset = cursorRenderCol - editorWindowWidth + 1;
  }
}

void editorDrawRows() {
  final screenBuffer = StringBuffer();

  for (var screenRow = 0; screenRow < editorWindowHeight; screenRow++) {
    // fileRow is the row of the file we want to print to screenRow
    final fileRow = screenRow + screenFileRowOffset;

    // If we're beyond the text buffer, print tilde in column 0
    if (fileRow >= sentenceRows.length) {
      // Show a welcome message
      if (sentenceRows.isEmpty &&
          (screenRow == (editorWindowHeight / 3).round())) {
        // Print the welcome message centered a third of the way down the screen
        final welcomeMessage = truncateString(
            'Translate -- version $translateVersion', editorWindowWidth);
        var padding = ((editorWindowWidth - welcomeMessage.length) / 2).round();
        if (padding > 0) {
          screenBuffer.write('~');
          padding--;
        }
        while (padding-- > 0) {
          screenBuffer.write(' ');
        }
        screenBuffer.write(welcomeMessage);
      } else {
        screenBuffer.write('~');
      }
    }

    // Otherwise print the onscreen portion of the current file row,
    // trimmed if necessary
    else {
      if (renderRows[fileRow].length - screenRowColOffset > 0) {
        screenBuffer.write(truncateString(
            renderRows[fileRow].substring(screenRowColOffset),
            editorWindowWidth));
      }
    }

    screenBuffer.write(console.newLine);
  }
  console.write(screenBuffer.toString());
}

void editorDrawStatusBar() {
  console.setTextStyle(inverted: true);

  var leftString =
      '${truncateString(messageId, (editorWindowWidth / 2).ceil())}'
      ' - ${sentenceRows.length} lines';
  if (isSentenceDirty) leftString += ' (modified)';
  final rightString = '${cursorRow + 1}/${sentenceRows.length}';
  final padding = editorWindowWidth - leftString.length - rightString.length;

  console.write('$leftString'
      '${" " * padding}'
      '$rightString');

  console.resetColorAttributes();
  console.writeLine();
}

void editorDrawMessageBar() {
  if (messageTimestamp != null) {
    if (DateTime.now().difference(messageTimestamp!) < Duration(seconds: 5)) {
      console.write(truncateString(messageText, editorWindowWidth)
          .padRight(editorWindowWidth));
    }
  }
}

void editorRefreshScreen() {
  editorScroll();

  console.hideCursor();
  console.clearScreen();

  editorDrawRows();
  editorDrawStatusBar();
  editorDrawMessageBar();

  console.cursorPosition = Coordinate(
      cursorRow - screenFileRowOffset, cursorRenderCol - screenRowColOffset);
  console.showCursor();
}

void editorSetStatusMessage(String message) {
  messageText = message;
  messageTimestamp = DateTime.now();
}

String editorPrompt(String message,
    [Function(String text, Key lastPressed)? callback]) {
  final originalCursorRow = cursorRow;

  editorSetStatusMessage(message);
  editorRefreshScreen();

  console.cursorPosition = Coordinate(console.windowHeight - 1, message.length);

  final response = console.readLine(cancelOnEscape: true, callback: callback);
  cursorRow = originalCursorRow;
  editorSetStatusMessage('');

  return response ?? '';
}

//
// INPUT OPERATIONS
//
void editorMoveCursor(ControlCharacter key) {
  switch (key) {
    case ControlCharacter.arrowLeft:
      if (cursorCol != 0) {
        cursorCol--;
      } else if (cursorRow > editorFirstRow /* 0 */) {
        cursorRow--;
        cursorCol = sentenceRows[cursorRow].length;
      }
      break;
    case ControlCharacter.arrowRight:
      if (cursorRow < sentenceRows.length) {
        if (cursorCol < sentenceRows[cursorRow].length) {
          cursorCol++;
        } else if (cursorCol == sentenceRows[cursorRow].length) {
          cursorCol = 0;
          cursorRow++;
        }
      }
      break;
    case ControlCharacter.arrowUp:
      if (cursorRow > editorFirstRow /* != 0 */) cursorRow--;
      break;
    case ControlCharacter.arrowDown:
      if (cursorRow < sentenceRows.length) cursorRow++;
      break;
    case ControlCharacter.pageUp:
      cursorRow = screenFileRowOffset;
      for (var i = 0; i < editorWindowHeight; i++) {
        editorMoveCursor(ControlCharacter.arrowUp);
      }
      break;
    case ControlCharacter.pageDown:
      cursorRow = screenFileRowOffset + editorWindowHeight - 1;
      for (var i = 0; i < editorWindowHeight; i++) {
        editorMoveCursor(ControlCharacter.arrowDown);
      }
      break;
    case ControlCharacter.home:
      cursorCol = 0;
      break;
    case ControlCharacter.end:
      if (cursorRow < sentenceRows.length) {
        cursorCol = sentenceRows[cursorRow].length;
      }
      break;
    default:
  }

  if (cursorRow < sentenceRows.length) {
    cursorCol = min(cursorCol, sentenceRows[cursorRow].length);
  }
}

bool editorProcessKeypress() {
  var processing = true;
  final key = console.readSystemKey();

  if (key.isControl) {
    switch (key.controlChar) {
      case ControlCharacter.ctrlQ:
        editorQuit();
        processing = false;
        break;
      /* case ControlCharacter.ctrlS:
        editorSave();
        processing = false;
        break; */
      case ControlCharacter.ctrlF:
        editorFind();
        break;
      case ControlCharacter.backspace:
      case ControlCharacter.ctrlH:
        editorBackspaceChar();
        break;
      case ControlCharacter.delete:
        editorMoveCursor(ControlCharacter.arrowRight);
        editorBackspaceChar();
        break;
      case ControlCharacter.enter:
        editorInsertNewline();
        break;
      case ControlCharacter.arrowLeft:
      case ControlCharacter.arrowUp:
      case ControlCharacter.arrowRight:
      case ControlCharacter.arrowDown:
      case ControlCharacter.pageUp:
      case ControlCharacter.pageDown:
      case ControlCharacter.home:
      case ControlCharacter.end:
        editorMoveCursor(key.controlChar);
        break;
      case ControlCharacter.ctrlA:
        editorMoveCursor(ControlCharacter.home);
        break;
      case ControlCharacter.ctrlE:
        editorMoveCursor(ControlCharacter.end);
        break;
      default:
    }
  } else {
    editorInsertChar(key.char);
  }
  return processing;
}

//
// ENTRY POINT
//

/* void main(List<String> arguments) {
  try {
    console.rawMode = true;
    initEditor();
    if (arguments.isNotEmpty) {
      editedFilename = arguments[0];
      editorOpen(editedFilename);
    }

    editorSetStatusMessage(
        'HELP: Ctrl-S = save | Ctrl-Q = quit | Ctrl-F = find');

    while (true) {
      editorRefreshScreen();
      editorProcessKeypress();
    }
  } catch (exception) {
    // Make sure raw mode gets disabled if we hit some unrelated problem
    console.rawMode = false;
    rethrow;
  }
} */
