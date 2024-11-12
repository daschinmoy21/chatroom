import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'models/server.dart';
import 'models/channel.dart';

class DiscordColors {
  static const background = Color(0xFF2C2F33);
  static const channelsBg = Color(0xFF23272A);
  static const serversBg = Color(0xFF202225);
  static const messageHover = Color(0xFF36393F);
  static const textColor = Color(0xFFB9BBBE);
  static const inputBg = Color(0xFF40444B);
  static const accent = Color(0xFF7289DA);
}

class ChatRoom extends StatefulWidget {
  final Server server;

  const ChatRoom({Key? key, required this.server}) : super(key: key);

  @override
  _ChatRoomState createState() => _ChatRoomState();
}

class _ChatRoomState extends State<ChatRoom> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Message> _messages = [];
  WebSocketChannel? _channel;
  late final String _clientId;
  bool _isComposing = false;
  Set<String> _onlineUsers = {};

  List<Server> _servers = [];
  List<Channel> _channels = [];
  Server? _selectedServer;
  Channel? _selectedChannel;

  bool get _isDesktopWidth => MediaQuery.of(context).size.width > 1200;

  bool _showFriendsList = false;
  String _currentView = 'Online';

  @override
  void initState() {
    super.initState();
    _clientId = 'user_${DateTime.now().millisecondsSinceEpoch}';
    _fetchServers();
  }

  Future<void> _fetchServers() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:8000/servers'));
      if (response.statusCode == 200) {
        final List<dynamic> serversJson = json.decode(response.body);
        setState(() {
          _servers = serversJson.map((json) => Server.fromJson(json)).toList();
          if (_servers.isNotEmpty) {
            _selectServer(_servers[0]);
          }
        });
      }
    } catch (e) {
      print('Error fetching servers: $e');
    }
  }

  void _selectServer(Server server) {
    setState(() {
      _selectedServer = server;
      _channels = [];
      _selectedChannel = null;
      _messages.clear();
    });
    _fetchChannels(server.id);
  }

  void _selectChannel(Channel channel) {
    setState(() {
      _selectedChannel = channel;
      _messages.clear();
    });
    _connectToChannel(channel.id.toString());
  }

  Widget _buildMessageInput() {
    return Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DiscordColors.inputBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.add_circle_outline),
            color: DiscordColors.textColor.withOpacity(0.6),
            onPressed: () {},
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: _selectedChannel != null 
                    ? 'Message #${_selectedChannel!.name}'
                    : 'Select a channel to start chatting',
                hintStyle: TextStyle(
                  color: DiscordColors.textColor.withOpacity(0.4),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (text) {
                setState(() => _isComposing = text.isNotEmpty);
              },
              onSubmitted: (_) => _sendMessage(),
              enabled: _selectedChannel != null,
            ),
          ),
          IconButton(
            icon: Icon(
              _isComposing ? Icons.send : Icons.mic,
              color: _selectedChannel != null 
                  ? DiscordColors.textColor.withOpacity(0.6)
                  : DiscordColors.textColor.withOpacity(0.2),
            ),
            onPressed: _selectedChannel != null && _isComposing ? _sendMessage : null,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DiscordColors.background,
      body: Row(
        children: [
          _buildServersBar(),
          _buildChannelsBar(),
          Expanded(
            child: Column(
              children: [
                _buildTopNavBar(),
                Expanded(
                  child: _showFriendsList ? _buildFriendsList() : _buildChatView(),
                ),
              ],
            ),
          ),
          if (_isDesktopWidth) _buildMembersBar(),
        ],
      ),
    );
  }

  Widget _buildTopNavBar() {
    return Container(
      height: 48,
      color: DiscordColors.background,
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: DiscordColors.channelsBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: Icon(
                _showFriendsList ? Icons.chat_bubble_outline : Icons.people_alt,
                color: DiscordColors.textColor,
              ),
              onPressed: () {
                setState(() {
                  _showFriendsList = !_showFriendsList;
                });
              },
            ),
          ),
          SizedBox(width: 8),
          Text(
            _showFriendsList ? 'Friends' : 'Channels',
            style: TextStyle(color: DiscordColors.textColor, fontWeight: FontWeight.bold),
          ),
          Spacer(),
          IconButton(
            icon: Icon(Icons.chat, color: DiscordColors.textColor),
            onPressed: () {
              // TODO: Implement new group DM
            },
          ),
          IconButton(
            icon: Icon(Icons.inbox, color: DiscordColors.textColor),
            onPressed: () {
              // TODO: Implement inbox
            },
          ),
          IconButton(
            icon: Icon(Icons.help_outline, color: DiscordColors.textColor),
            onPressed: () {
              // TODO: Implement help
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsList() {
    return Column(
      children: [
        _buildFriendsListTabs(),
        Expanded(
          child: ListView(
            children: [
              // Friends list items can be dynamically added here
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFriendsListTabs() {
    return Container(
      height: 48,
      color: DiscordColors.background,
      child: Row(
        children: [
          _buildTab('Online', _currentView == 'Online'),
          _buildTab('All', _currentView == 'All'),
          _buildTab('Pending', _currentView == 'Pending'),
          _buildTab('Blocked', _currentView == 'Blocked'),
          Spacer(),
          ElevatedButton(
            child: Text('Add Friend'),
            onPressed: () {
              // TODO: Implement add friend functionality
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DiscordColors.accent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String title, bool isSelected) {
    return InkWell(
      onTap: () {
        setState(() => _currentView = title);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? DiscordColors.accent : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: isSelected ? DiscordColors.accent : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : DiscordColors.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildChatView() {
    return Container(
      color: DiscordColors.background,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildMessageList()),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: DiscordColors.background,
        border: Border(
          bottom: BorderSide(
            color: Colors.black.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.tag, color: DiscordColors.textColor.withOpacity(0.6)),
          SizedBox(width: 8),
          Text(
            _selectedChannel?.name ?? 'Select a channel',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServersBar() {
    return Container(
      width: 72,
      color: DiscordColors.serversBg,
      child: Column(
        children: [
          IconButton(
            icon: Icon(Icons.add, color: Colors.white),
            onPressed: () {
              // TODO: Implement server creation
            },
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _servers.length,
              itemBuilder: (context, index) {
                final server = _servers[index];
                final isSelected = server.id == _selectedServer?.id;
                return InkWell(
                  onTap: () => _selectServer(server),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: CircleAvatar(
                      backgroundColor: isSelected ? DiscordColors.accent : DiscordColors.channelsBg,
                      child: Text(
                        server.icon,
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelsBar() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.2,
      constraints: BoxConstraints(
        maxWidth: 240,
        minWidth: 200,
      ),
      color: DiscordColors.channelsBg,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.black26,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedServer?.name ?? 'Select a server',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(Icons.expand_more, color: Colors.white),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _channels.length,
              itemBuilder: (context, index) {
                final channel = _channels[index];
                final isSelected = channel.id == _selectedChannel?.id;
                return _buildChannel(channel.name, isSelected);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChannel(String name, bool isSelected) {
    return InkWell(
      onTap: () {
        final channel = _channels.firstWhere((c) => c.name == name);
        _selectChannel(channel);
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? DiscordColors.messageHover : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Text(
              '#',
              style: TextStyle(
                fontSize: 24,
                color: isSelected ? Colors.white : Colors.grey[500],
                fontWeight: FontWeight.w300,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[500],
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessageItem(message);
      },
    );
  }

  Widget _buildMessageItem(Message message) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: message.isMe ? DiscordColors.accent : Colors.grey[700],
            radius: 20,
            child: Text(
              message.clientId.substring(0, 2).toUpperCase(),
              style: TextStyle(color: Colors.white),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      message.clientId,
                      style: TextStyle(
                        color: message.isMe ? DiscordColors.accent : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      _formatTime(message.timestamp),
                      style: TextStyle(
                        color: DiscordColors.textColor.withOpacity(0.4),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  message.message,
                  style: TextStyle(
                    color: DiscordColors.textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildMembersBar() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.2,
      constraints: BoxConstraints(
        maxWidth: 240,
        minWidth: 200,
      ),
      color: DiscordColors.channelsBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'ONLINE — ${_onlineUsers.length}',
              style: TextStyle(
                color: DiscordColors.textColor.withOpacity(0.7),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _onlineUsers.length,
              itemBuilder: (context, index) {
                final userId = _onlineUsers.elementAt(index);
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: DiscordColors.accent,
                    radius: 16,
                    child: Text(
                      userId.substring(0, 2).toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  title: Text(
                    userId,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    'Online',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchChannels(int serverId) async {
    try {
      final response = await http.get(Uri.parse('http://localhost:8000/channels/$serverId'));
      if (response.statusCode == 200) {
        final List<dynamic> channelsJson = json.decode(response.body);
        setState(() {
          _channels = channelsJson.map((json) => Channel.fromJson(json)).toList();
          if (_channels.isNotEmpty) {
            _selectChannel(_channels[0]);
          }
        });
      }
    } catch (e) {
      print('Error fetching channels: $e');
    }
  }

  void _connectToChannel(String channelId) {
    _channel?.sink.close();
    final wsUrl = 'ws://localhost:8000/ws/$channelId/$_clientId';
    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

    _channel!.stream.listen(
      _handleMessage,
      onError: (error) {
        print('WebSocket error: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection error: $error')),
        );
      },
      onDone: () {
        print('WebSocket connection closed');
      },
    );
  }

  void _sendMessage() {
    if (_controller.text.isNotEmpty && _channel != null && _selectedChannel != null) {
      try {
        final message = {
          'client_id': _clientId,
          'message': _controller.text,
          'type': 'chat',
          'channel_id': _selectedChannel!.id,
        };

        _channel!.sink.add(json.encode(message));

        _controller.clear();
        setState(() => _isComposing = false);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });

      } catch (e) {
        print('Error sending message: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    }
  }

  void _handleMessage(dynamic message) {
    try {
      final Map<String, dynamic> data = json.decode(message);
      setState(() {
        if (data['type'] == 'system') {
          if (data['message'] == 'joined the chat') {
            _onlineUsers.add(data['client_id']);
          } else if (data['message'] == 'left the chat') {
            _onlineUsers.remove(data['client_id']);
          }
        }
        _messages.add(Message.fromJson(data, _clientId));
      });

      // Scroll to bottom when a new message arrives
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      print('Error handling message: $e');
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
}

class Message {
  final String clientId;
  final String message;
  final String type;
  final bool isMe;
  final DateTime timestamp;

  Message({
    required this.clientId,
    required this.message,
    required this.type,
    required this.isMe,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory Message.fromJson(Map<String, dynamic> json, String myClientId) {
    return Message(
      clientId: json['client_id'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'chat',
      isMe: json['client_id'] == myClientId,
    );
  }

  Map<String, dynamic> toJson() => {
    'client_id': clientId,
    'message': message,
    'type': type,
  };
} 