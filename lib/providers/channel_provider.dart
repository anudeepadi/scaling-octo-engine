import 'package:flutter/foundation.dart';

class ChannelProvider with ChangeNotifier {
  String _currentChannel = 'general';
  final List<String> _channels = ['general'];

  String get currentChannel => _currentChannel;
  List<String> get channels => _channels;

  void setCurrentChannel(String channel) {
    if (_channels.contains(channel)) {
      _currentChannel = channel;
      notifyListeners();
    }
  }

  void addChannel(String channel) {
    if (!_channels.contains(channel)) {
      _channels.add(channel);
      notifyListeners();
    }
  }

  void removeChannel(String channel) {
    if (channel != 'general' && _channels.contains(channel)) {
      _channels.remove(channel);
      if (_currentChannel == channel) {
        _currentChannel = 'general';
      }
      notifyListeners();
    }
  }
}
