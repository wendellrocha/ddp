# ENHANCED DDP
Carefully extended [DDP](https://github.com/haoguo/ddp) package to interact with the DDP.
This is a [DPP](https://github.com/meteor/meteor/blob/devel/packages/ddp/DDP.md) protocol implementation for Flutter/Dart.

### Connection
```dart
import 'package:ddp/ddp.dart';

DdpClient client = DdpClient("meteor", "ws://localhost:3000/websocket", "meteor");
client.connect();

client.addStatusListener((status) {
  if (status == ConnectStatus.connected) {
    print('I am connected!');
  }
});
```

### Subscribe
```dart
void myListener(String collectionName, String message, String docId, Map map) {
  // Do something great
}

client.addStatusListener((status) {
  if (status == ConnectStatus.connected) {
    client.subscribe("subscribe_name", (done) {
      Collection collection = done.owner.collectionByName("collection_name");
      collection.addUpdateListener(myListener);
    }, []);
  }
});
```

### Call method
```dart
List tasks = [];

client.addStatusListener((status) async {
  if (status == ConnectStatus.connected) {
    var data = await client.call('getTasks', []);
    data.reply.forEach((map) => tasks.add(map));
  }
});
```