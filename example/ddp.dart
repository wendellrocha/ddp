import 'package:enhanced_ddp/enhanced_ddp.dart';

void main() async {
  DdpClient client =
      DdpClient("meteor", "ws://localhost:3000/websocket", "meteor");
  client.connect();

  client.addStatusListener((status) {
    if (status == ConnectStatus.connected) {
      print('I am connected!');
    }
  });
}
