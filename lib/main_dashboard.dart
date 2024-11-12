import 'package:flutter/material.dart';
import 'chat_room.dart';
import 'models/server.dart';

class MainDashboard extends StatefulWidget {
  const MainDashboard({Key? key}) : super(key: key);

  @override
  _MainDashboardState createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  List<Server> _servers = [];
  Server? _selectedServer;

  @override
  void initState() {
    super.initState();
    _fetchServers();
  }

  Future<void> _fetchServers() async {
    setState(() {
      _servers = [
        Server(id: 1, name: 'Gaming Hub', icon: 'G'),
        Server(id: 2, name: 'Coding Zone', icon: 'C'),
      ];
    });
  }

  void _selectServer(Server server) {
    setState(() {
      _selectedServer = server;
    });
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatRoom(server: server),
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
          Expanded(
            child: Column(
              children: [
                _buildTopNavBar(),
                Expanded(child: _buildMainContent()),
              ],
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
                return InkWell(
                  onTap: () => _selectServer(server),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: CircleAvatar(
                      backgroundColor: DiscordColors.channelsBg,
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

  Widget _buildTopNavBar() {
    return Container(
      height: 48,
      color: DiscordColors.background,
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            'Friends',
            style: TextStyle(color: DiscordColors.textColor, fontWeight: FontWeight.bold),
          ),
          Spacer(),
          IconButton(
            icon: Icon(Icons.search, color: DiscordColors.textColor),
            onPressed: () {
              // TODO: Implement search
            },
          ),
          IconButton(
            icon: Icon(Icons.settings, color: DiscordColors.textColor),
            onPressed: () {
              // TODO: Implement settings
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        _buildFriendsListTabs(),
        Expanded(
          child: ListView(
            children: [
              _buildFriendListItem('nichaaan.', 'Listening to Spotify'),
              _buildFriendListItem('trin', 'Do Not Disturb'),
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
          _buildTab('Online', true),
          _buildTab('All', false),
          _buildTab('Pending', false),
          _buildTab('Blocked', false),
          Spacer(),
          ElevatedButton(
            child: Text('Add Friend'),
            onPressed: () {
              // TODO: Implement add friend functionality
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
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
        // TODO: Handle tab selection
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

  Widget _buildFriendListItem(String name, String status) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: DiscordColors.accent,
        child: Text(
          name.substring(0, 2).toUpperCase(),
          style: TextStyle(color: Colors.white),
        ),
      ),
      title: Text(
        name,
        style: TextStyle(color: Colors.white),
      ),
      subtitle: Text(
        status,
        style: TextStyle(color: DiscordColors.textColor.withOpacity(0.6)),
      ),
    );
  }
} 