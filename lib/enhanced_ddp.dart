library enhanced_ddp;

import 'dart:async';
import 'dart:convert';

import 'package:tuple/tuple.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

part 'enhanced_ddp_client.dart';
part 'enhanced_ddp_collection.dart';
part 'enhanced_ddp_messages.dart';
part 'enhanced_ddp_stats.dart';

class _IdManager {
  int _next = 0;

  String next() {
    final next = _next;
    _next++;
    return next.toRadixString(16);
  }
}

class _PingTracker {
  Function(Error) _handler;
  // ignore: unused_field
  Duration _timeout;
  Timer _timer;
}

typedef void OnCallDone(Call call);

class Call {
  String id;
  String serviceMethod;
  dynamic args;
  dynamic reply;
  Error error;
  DdpClient owner;
  List<OnCallDone> _handlers = [];

  void onceDone(OnCallDone fn) {
    this._handlers.add(fn);
  }

  void done() {
    owner._calls.remove(this.id);
    _handlers.forEach((handler) => handler(this));
    _handlers.clear();
  }
}
