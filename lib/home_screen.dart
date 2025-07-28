import 'package:flutter/material.dart';
import 'user_screen.dart';
import 'add_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 1;

  final List<Widget> _screens = [AddScreen(), LipoScreen(), UserScreen()];

  final List<String> _titles = const <String>['Add', 'Home', 'User Settings'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_selectedIndex])),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Add'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'User'),
        ],
      ),
    );
  }
}

class LipoScreen extends StatelessWidget {
  const LipoScreen({Key? key}) : super(key: key);

  Future<List<Map<String, dynamic>>> _fetchLipos() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return [];
    final response = await supabase
        .from('lipo')
        .select('id, brand, capacity, cell_count')
        .eq('user_id', user.id);
    if (response is List) {
      return List<Map<String, dynamic>>.from(response);
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchLipos(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: \\${snapshot.error}'));
        }
        final lipos = snapshot.data ?? [];
        if (lipos.isEmpty) {
          return const Center(
            child: Text(
              'Start by adding a new lipo',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: lipos.length,
          itemBuilder: (context, index) {
            final lipo = lipos[index];
            return Card(
              child: ListTile(
                title: Text(lipo['brand'] ?? 'Unknown'),
                subtitle: Text(
                  'Capacity: \\${lipo['capacity']} mAh\nCells: \\${lipo['cell_count']}',
                ),
                trailing: const Icon(Icons.battery_charging_full),
              ),
            );
          },
        );
      },
    );
  }
}
