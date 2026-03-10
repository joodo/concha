import 'dart:async';
import 'dart:convert';
import 'dart:io';

enum ShellOutputStream { stdout, stderr }

class ShellOutputLine {
  const ShellOutputLine({required this.stream, required this.line});

  final ShellOutputStream stream;
  final String line;

  String get tag => stream == ShellOutputStream.stdout ? 'stdout' : 'stderr';
}

typedef ShellOutputHandler = void Function(ShellOutputLine output);

class ShellResult {
  const ShellResult({
    required this.command,
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });

  final String command;
  final int exitCode;
  final String stdout;
  final String stderr;

  String get allOutput => '$stdout\n$stderr';
}

class ShellRunner {
  const ShellRunner({this.shellPath = '/bin/zsh'});

  final String shellPath;

  Future<ShellResult> run(
    String command, {
    ShellOutputHandler? onOutput,
  }) async {
    final process = await Process.start(shellPath, ['-lc', command]);
    final stdoutBuffer = StringBuffer();
    final stderrBuffer = StringBuffer();

    final stdoutFuture = process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .forEach((line) {
          stdoutBuffer.writeln(line);
          onOutput?.call(
            ShellOutputLine(stream: ShellOutputStream.stdout, line: line),
          );
        });

    final stderrFuture = process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .forEach((line) {
          stderrBuffer.writeln(line);
          onOutput?.call(
            ShellOutputLine(stream: ShellOutputStream.stderr, line: line),
          );
        });

    final exitCode = await process.exitCode;
    await Future.wait([stdoutFuture, stderrFuture]);

    return ShellResult(
      command: command,
      exitCode: exitCode,
      stdout: stdoutBuffer.toString(),
      stderr: stderrBuffer.toString(),
    );
  }

  Future<bool> existsInPath(String executable) async {
    final result = await run('command -v ${quote(executable)}');
    return result.exitCode == 0;
  }

  static String quote(String input) {
    return "'${input.replaceAll("'", "'\\''")}'";
  }
}
