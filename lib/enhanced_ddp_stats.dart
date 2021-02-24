part of enhanced_ddp;

enum LoggingDataType {
  DataByte,
  DataText,
}

class ReaderProxy extends Stream<dynamic> {
  Stream<dynamic> _reader;

  ReaderProxy(this._reader);

  @override
  StreamSubscription listen(
    void Function(dynamic event) onData, {
    Function onError,
    void Function() onDone,
    bool cancelOnError,
  }) {
    return this._reader.listen(
          onData,
          onError: onError,
          onDone: onDone,
          cancelOnError: cancelOnError,
        );
  }

  void setReader(Stream<dynamic> reader) {
    this._reader = reader;
  }
}

class WriterProxy implements StreamSink<dynamic> {
  StreamSink<dynamic> _writer;

  WriterProxy(this._writer);

  @override
  void add(event) {
    print('[DDP] -> $event');
    this._writer.add(event);
  }

  @override
  void addError(Object error, [StackTrace stackTrace]) {
    this._writer.addError(error, stackTrace);
  }

  @override
  Future addStream(Stream stream) {
    return this._writer.addStream(stream);
  }

  @override
  Future close() {
    return this._writer.close();
  }

  @override
  Future get done {
    return this._writer.done;
  }

  void setWriter(WebSocketSink writer) {
    this._writer = writer;
  }
}

typedef void _Logger(Object object);

class LoggerMixin {
  bool active;
  int truncate;
  LoggingDataType _dtype;
  _Logger _logger;

  log(dynamic p, int n) {
    if (this.active) {
      int limit = n;
      bool trancated = false;
      if (this.truncate > 0 && this.truncate < limit) {
        limit = this.truncate;
        trancated = true;
      }
      switch (this._dtype) {
        case LoggingDataType.DataText:
          if (trancated) {
            if (p is List) {
              this._logger('[${n}] ${utf8.decode(p.sublist(0, limit))}...');
            } else if (p.runtimeType == String) {
              this._logger('[${n}] ${p.substring(0, limit)}...');
            }
          } else {
            if (p is List) {
              this._logger('[${n}] ${utf8.decode(p.sublist(0, limit))}');
            } else if (p.runtimeType == String) {
              this._logger('[${n}] ${p.substring(0, limit)}');
            }
          }
          break;
        case LoggingDataType.DataByte:
        default:
        // Don't know what to do? maybe dataByte is not necessary to log?
      }
    }
    return n;
  }
}

class ReaderLogger extends ReaderProxy with LoggerMixin {
  ReaderLogger(Stream reader) : super(reader);

  factory ReaderLogger.text(Stream reader) => ReaderLogger(reader)
    .._logger = ((Object obj) => print('<- $obj'))
    ..active = true
    .._dtype = LoggingDataType.DataText
    ..truncate = 80;

  @override
  StreamSubscription listen(
    void Function(dynamic event) onData, {
    Function onError,
    void Function() onDone,
    bool cancelOnError,
  }) {
    return super.listen(
      (event) {
        this.log(event, event.length);
        onData(event);
      },
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

class WriterLogger extends WriterProxy with LoggerMixin {
  WriterLogger(StreamSink writer) : super(writer);

  factory WriterLogger.text(StreamSink writer) => WriterLogger(writer)
    .._logger = ((Object obj) => print('-> $obj'))
    ..active = true
    .._dtype = LoggingDataType.DataText
    ..truncate = 80;

  @override
  void add(event) {
    this.log(event, event.length);
    super.add(event);
  }
}

class Stats {
  int bytes;
  int ops;
  int errors;
  Duration runtime;
}

class ClientStats {
  Stats reads;
  Stats totalReads;
  Stats writes;
  Stats totalWrites;
  int reconnects;
  int pingsSent;
  int pingsRecv;
}

class CollectionStats {
  String name;
  int count;
}

class StatsTrackerMixin {
  int _bytes;
  int _ops;
  int _errors;
  DateTime _start;

  int op(int n) {
    this._ops++;
    this._bytes += n;

    return n;
  }

  Stats snapshot() {
    return this._snap();
  }

  Stats reset() {
    final stats = this._snap();
    this._bytes = 0;
    this._ops = 0;
    this._errors = 0;
    this._start = DateTime.now();
    return stats;
  }

  Stats _snap() {
    return Stats()
      ..bytes = this._bytes
      ..ops = this._ops
      ..errors = this._errors
      ..runtime = DateTime.now().difference(this._start);
  }
}

class ReaderStats extends ReaderProxy with StatsTrackerMixin {
  ReaderStats(Stream reader) : super(reader) {
    this._bytes = 0;
    this._ops = 0;
    this._errors = 0;
    this._start = DateTime.now();
  }

  @override
  StreamSubscription listen(
    void Function(dynamic event) onData, {
    Function onError,
    void Function() onDone,
    bool cancelOnError,
  }) {
    return super.listen(
      (event) {
        this.op(event.length);
        onData(event);
      },
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

class WriterStats extends WriterProxy with StatsTrackerMixin {
  WriterStats(StreamSink writer) : super(writer) {
    this._bytes = 0;
    this._ops = 0;
    this._errors = 0;
    this._start = DateTime.now();
  }

  @override
  void add(dynamic event) {
    this.op(event.length);
    super.add(event);
  }
}
