import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TaniSmartApp());
}

const green = Color(0xFF176B3A);
const paleGreen = Color(0xFFEAF5ED);

class TaniSmartApp extends StatelessWidget {
  const TaniSmartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TANI SMART',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: green),
        scaffoldBackgroundColor: const Color(0xFFF7FAF7),
        appBarTheme: const AppBarTheme(
          backgroundColor: green,
          foregroundColor: Colors.white,
          centerTitle: false,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class Crop {
  String name;
  String type;
  String area;
  String stage;
  Crop(this.name, this.type, this.area, this.stage);
  Map<String, dynamic> toJson() =>
      {'name': name, 'type': type, 'area': area, 'stage': stage};
  factory Crop.fromJson(Map<String, dynamic> j) =>
      Crop(j['name'] ?? '', j['type'] ?? 'Tanaman', j['area'] ?? '0', j['stage'] ?? 'Pertumbuhan');
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int index = 0;
  bool loading = true;
  bool irrigation = false;
  List<Crop> crops = [
    Crop('Cabai Merah', 'Sayuran', '500', 'Pertumbuhan'),
    Crop('Padi', 'Pangan', '1000', 'Vegetatif'),
    Crop('Tomat', 'Sayuran', '250', 'Berbunga'),
  ];
  List<String> tasks = [
    'Periksa kelembapan tanah',
    'Periksa hama dan penyakit',
    'Jadwalkan pemupukan',
  ];
  List<bool> taskDone = [false, false, false];
  final expenseController = TextEditingController(text: '500000');
  final incomeController = TextEditingController(text: '2500000');
  final noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString('crops');
    if (raw != null) {
      crops = (jsonDecode(raw) as List)
          .map((e) => Crop.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    irrigation = p.getBool('irrigation') ?? false;
    final savedTasks = p.getStringList('taskDone');
    if (savedTasks != null && savedTasks.length == tasks.length) {
      taskDone = savedTasks.map((e) => e == '1').toList();
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> saveData() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('crops', jsonEncode(crops.map((e) => e.toJson()).toList()));
    await p.setBool('irrigation', irrigation);
    await p.setStringList('taskDone', taskDone.map((e) => e ? '1' : '0').toList());
  }

  @override
  void dispose() {
    expenseController.dispose();
    incomeController.dispose();
    noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      dashboard(), cropPage(), activityPage(), financePage(), marketPage()
    ];
    return Scaffold(
      appBar: AppBar(
        title: Row(children: const [
          Icon(Icons.eco, size: 27),
          SizedBox(width: 9),
          Text('TANI SMART', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
        ]),
        actions: [
          IconButton(
            tooltip: 'Tentang aplikasi',
            onPressed: () => showAboutDialog(
              context: context,
              applicationName: 'TANI SMART',
              applicationVersion: '1.0.0',
              applicationLegalese: 'Asisten pengelolaan pertanian modern.',
            ),
            icon: const Icon(Icons.info_outline),
          )
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(child: IndexedStack(index: index, children: pages)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (v) => setState(() => index = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Beranda'),
          NavigationDestination(icon: Icon(Icons.grass_outlined), selectedIcon: Icon(Icons.grass), label: 'Tanaman'),
          NavigationDestination(icon: Icon(Icons.event_note_outlined), selectedIcon: Icon(Icons.event_note), label: 'Aktivitas'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: 'Keuangan'),
          NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront), label: 'Pasar'),
        ],
      ),
    );
  }

  Widget pagePadding(Widget child) => SingleChildScrollView(
    padding: const EdgeInsets.all(16), child: child);

  Widget sectionTitle(String title, {String? subtitle}) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
      if (subtitle != null) ...[
        const SizedBox(height: 4),
        Text(subtitle, style: TextStyle(color: Colors.grey.shade700)),
      ]
    ]),
  );

  Widget statCard(String label, String value, IconData icon, Color color) =>
    Card(elevation: 0, color: Colors.white, child: Padding(
      padding: const EdgeInsets.all(15),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 27),
        const SizedBox(height: 12),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
      ]),
    ));

  Widget dashboard() => pagePadding(Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF14532D), Color(0xFF279653)]),
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Selamat datang di', style: TextStyle(color: Colors.white70)),
          SizedBox(height: 4),
          Text('Pertanian Lebih Cerdas 🌱', style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Kelola lahan, tanaman, aktivitas, dan keuangan dalam satu aplikasi.', style: TextStyle(color: Colors.white)),
        ]),
      ),
      const SizedBox(height: 18),
      sectionTitle('Ringkasan kebun'),
      GridView.count(
        crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.55, crossAxisSpacing: 10, mainAxisSpacing: 10,
        children: [
          statCard('Jenis tanaman', '${crops.length}', Icons.grass, green),
          statCard('Tugas selesai', '${taskDone.where((e) => e).length}/${tasks.length}', Icons.task_alt, Colors.blue),
          statCard('Luas tercatat', '${crops.fold<int>(0, (s, c) => s + (int.tryParse(c.area) ?? 0))} m²', Icons.landscape, Colors.brown),
          statCard('Irigasi simulasi', irrigation ? 'Aktif' : 'Mati', Icons.water_drop, Colors.lightBlue),
        ],
      ),
      const SizedBox(height: 16),
      Card(elevation: 0, child: SwitchListTile(
        secondary: const Icon(Icons.water_drop, color: Colors.blue),
        title: const Text('Kontrol irigasi'),
        subtitle: const Text('Saklar simulasi — belum terhubung ke pompa fisik'),
        value: irrigation,
        onChanged: (v) { setState(() => irrigation = v); saveData(); },
      )),
      const SizedBox(height: 8),
      Card(elevation: 0, child: const ListTile(
        leading: Icon(Icons.info_outline, color: green),
        title: Text('Informasi penting'),
        subtitle: Text('Data cuaca, sensor, dan harga pasar belum terhubung ke layanan langsung.'),
      )),
    ],
  ));

  Widget cropPage() => pagePadding(Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      sectionTitle('Manajemen tanaman', subtitle: 'Catat semua jenis tanaman dan luas lahannya.'),
      FilledButton.icon(
        onPressed: addCrop,
        icon: const Icon(Icons.add),
        label: const Text('Tambah tanaman'),
      ),
      const SizedBox(height: 12),
      if (crops.isEmpty) const Center(child: Padding(
        padding: EdgeInsets.all(24), child: Text('Belum ada tanaman. Tekan Tambah tanaman.'))),
      ...crops.asMap().entries.map((entry) {
        final i = entry.key; final c = entry.value;
        return Card(elevation: 0, margin: const EdgeInsets.only(bottom: 9), child: ListTile(
          leading: CircleAvatar(backgroundColor: paleGreen, child: const Icon(Icons.spa, color: green)),
          title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('${c.type} • ${c.area} m² • ${c.stage}'),
          trailing: IconButton(
            tooltip: 'Hapus tanaman',
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () {
              setState(() => crops.removeAt(i)); saveData();
            },
          ),
        ));
      }),
    ],
  ));

  Future<void> addCrop() async {
    final name = TextEditingController();
    final type = TextEditingController(text: 'Sayuran');
    final area = TextEditingController(text: '100');
    final stage = TextEditingController(text: 'Pertumbuhan');
    final result = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Tambah tanaman'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Nama tanaman')),
        const SizedBox(height: 10),
        TextField(controller: type, decoration: const InputDecoration(labelText: 'Kategori')),
        const SizedBox(height: 10),
        TextField(controller: area, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Luas lahan (m²)')),
        const SizedBox(height: 10),
        TextField(controller: stage, decoration: const InputDecoration(labelText: 'Tahap pertumbuhan')),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Simpan')),
      ],
    ));
    if (result == true && name.text.trim().isNotEmpty) {
      setState(() => crops.add(Crop(name.text.trim(), type.text.trim(), area.text.trim(), stage.text.trim())));
      await saveData();
    }
    name.dispose(); type.dispose(); area.dispose(); stage.dispose();
  }

  Widget activityPage() => pagePadding(Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      sectionTitle('Aktivitas pertanian', subtitle: 'Centang pekerjaan yang sudah dilakukan.'),
      Card(elevation: 0, child: Column(children: List.generate(tasks.length, (i) =>
        CheckboxListTile(
          value: taskDone[i],
          title: Text(tasks[i]),
          controlAffinity: ListTileControlAffinity.leading,
          onChanged: (v) { setState(() => taskDone[i] = v ?? false); saveData(); },
        )))),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: () => setState(() { taskDone = List.filled(tasks.length, false); saveData(); }),
        icon: const Icon(Icons.refresh), label: const Text('Reset checklist'),
      ),
      const SizedBox(height: 18),
      sectionTitle('Catatan kegiatan'),
      TextField(controller: noteController, maxLines: 5,
        decoration: const InputDecoration(hintText: 'Contoh: Cabai dipupuk hari ini...')),
      const SizedBox(height: 10),
      FilledButton.icon(
        onPressed: () {
          if (noteController.text.trim().isEmpty) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Catatan tersedia selama aplikasi terbuka.')));
        },
        icon: const Icon(Icons.save), label: const Text('Simpan catatan (sementara)'),
      ),
    ],
  ));

  Widget financePage() {
    final expense = int.tryParse(expenseController.text) ?? 0;
    final income = int.tryParse(incomeController.text) ?? 0;
    final profit = income - expense;
    String rupiah(int n) => 'Rp ${n.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
    return pagePadding(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      sectionTitle('Keuangan pertanian', subtitle: 'Hitung sederhana biaya dan pendapatan usaha tani.'),
      TextField(controller: expenseController, keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Biaya produksi (Rp)'),
        onChanged: (_) => setState(() {})),
      const SizedBox(height: 12),
      TextField(controller: incomeController, keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Pendapatan panen (Rp)'),
        onChanged: (_) => setState(() {})),
      const SizedBox(height: 16),
      Card(color: paleGreen, elevation: 0, child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Perkiraan laba / rugi'),
          const SizedBox(height: 6),
          Text(rupiah(profit), style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold, color: profit >= 0 ? green : Colors.red)),
          Text(profit >= 0 ? 'Surplus' : 'Defisit', style: TextStyle(color: profit >= 0 ? green : Colors.red)),
        ]),
      )),
      const SizedBox(height: 10),
      const Text('Catatan: masukkan semua biaya agar perhitungan lebih akurat. Data keuangan pada versi ini tersimpan di perangkat setelah fitur penyimpanan dikembangkan.'),
    ]));
  }

  Widget marketPage() => pagePadding(Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      sectionTitle('Pasar pertanian', subtitle: 'Contoh etalase jual beli hasil pertanian.'),
      marketItem('Beras premium', 'Contoh harga: Rp15.000/kg', Icons.grain, 'Jual'),
      marketItem('Cabai merah', 'Contoh harga: Rp35.000/kg', Icons.local_fire_department, 'Jual'),
      marketItem('Benih sayuran', 'Contoh harga: Rp25.000/kemasan', Icons.eco, 'Beli'),
      marketItem('Pupuk organik', 'Contoh harga: Rp50.000/karung', Icons.compost, 'Beli'),
      const SizedBox(height: 8),
      const Text('Harga di atas hanya ilustrasi, bukan harga pasar terkini. Marketplace dan pembayaran belum aktif.'),
    ],
  ));

  Widget marketItem(String name, String price, IconData icon, String label) =>
    Card(elevation: 0, margin: const EdgeInsets.only(bottom: 9), child: ListTile(
      leading: CircleAvatar(backgroundColor: paleGreen, child: Icon(icon, color: green)),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(price),
      trailing: Chip(label: Text(label)),
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$name — fitur transaksi akan ditambahkan pada versi berikutnya.'))),
    ));
}
