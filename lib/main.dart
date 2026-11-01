
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await muatDataLokal();
  } catch (e) {
    debugPrint('Gagal memuat data: $e');
  }

  runApp(const GarduScadaApp());
}

// ============================================================
// MODEL
// ============================================================

class Peralatan {
  String nama;
  String merk;
  String tipe;
  int jumlah;
  String satuan;
  String kondisi;

  Peralatan({
    required this.nama,
    this.merk = '',
    this.tipe = '',
    this.jumlah = 1,
    this.satuan = 'Unit',
    this.kondisi = 'Baik',
  });

  Map<String, dynamic> toJson() => {
        'nama': nama,
        'merk': merk,
        'tipe': tipe,
        'jumlah': jumlah,
        'satuan': satuan,
        'kondisi': kondisi,
      };

  factory Peralatan.fromJson(Map<String, dynamic> json) {
    return Peralatan(
      nama: json['nama'] as String? ?? '',
      merk: json['merk'] as String? ?? '',
      tipe: json['tipe'] as String? ?? '',
      jumlah: (json['jumlah'] as num?)?.toInt() ?? 1,
      satuan: json['satuan'] as String? ?? 'Unit',
      kondisi: json['kondisi'] as String? ?? 'Baik',
    );
  }
}

class Gardu {
  String id;
  String nama;
  String jenis;
  String alamat;
  double lat;
  double lng;
  List<Peralatan> peralatan;

  Gardu({
    required this.id,
    required this.nama,
    required this.jenis,
    required this.alamat,
    required this.lat,
    required this.lng,
    List<Peralatan>? peralatan,
  }) : peralatan = peralatan ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'nama': nama,
        'jenis': jenis,
        'alamat': alamat,
        'lat': lat,
        'lng': lng,
        'peralatan': peralatan.map((p) => p.toJson()).toList(),
      };

  factory Gardu.fromJson(Map<String, dynamic> json) {
    final daftar = json['peralatan'] as List<dynamic>? ?? [];

    return Gardu(
      id: json['id'] as String? ?? '',
      nama: json['nama'] as String? ?? '',
      jenis: json['jenis'] as String? ?? 'GT',
      alamat: json['alamat'] as String? ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 1.0456,
      lng: (json['lng'] as num?)?.toDouble() ?? 103.9905,
      peralatan: daftar
          .map((p) => Peralatan.fromJson(
                Map<String, dynamic>.from(p as Map),
              ))
          .toList(),
    );
  }
}

// ============================================================
// DATA AWAL DEMO
// ============================================================

final List<Gardu> garduList = [
  Gardu(
    id: 'G001',
    nama: 'GT New Century',
    jenis: 'GT',
    alamat: 'Batam, Kepulauan Riau',
    lat: 1.1050,
    lng: 103.9850,
    peralatan: [
      Peralatan(
        nama: 'RTU',
        merk: 'Talus',
        tipe: 'RTU SCADA',
      ),
      Peralatan(
        nama: 'Rectifier',
        merk: 'Enermild',
        tipe: 'DC Power Supply',
      ),
      Peralatan(
        nama: 'CCTV',
        merk: 'Hikvision',
        tipe: 'IP Camera',
      ),
    ],
  ),
  Gardu(
    id: 'G002',
    nama: 'GT Glory Rafles',
    jenis: 'GT',
    alamat: 'Batam, Kepulauan Riau',
    lat: 1.0750,
    lng: 103.9600,
    peralatan: [
      Peralatan(
        nama: 'RTU',
        merk: 'Talus',
        tipe: 'RTU SCADA',
      ),
      Peralatan(
        nama: 'Rectifier',
        merk: 'Enermild',
        tipe: 'DC Power Supply',
        kondisi: 'Perlu Pemeriksaan',
      ),
    ],
  ),
  Gardu(
    id: 'G003',
    nama: 'GH Contoh Batam',
    jenis: 'GH',
    alamat: 'Batam, Kepulauan Riau',
    lat: 1.0456,
    lng: 103.9905,
    peralatan: [
      Peralatan(
        nama: 'RTU',
        merk: 'Talus',
        tipe: 'RTU SCADA',
      ),
      Peralatan(
        nama: 'Kubikel',
        merk: 'Schneider',
        tipe: 'Switchgear',
      ),
    ],
  ),
];

final Map<String, Map<String, String>> users = {
  'admin': {
    'password': 'admin123',
    'role': 'Admin',
  },
  'viewer': {
    'password': 'viewer123',
    'role': 'Viewer',
  },
};

// ============================================================
// PENYIMPANAN LOKAL
// ============================================================

Future<void> simpanDataGardu() async {
  final prefs = await SharedPreferences.getInstance();

  await prefs.setString(
    'gardu_scada_data',
    jsonEncode(garduList.map((g) => g.toJson()).toList()),
  );
}

Future<void> simpanDataPengguna() async {
  final prefs = await SharedPreferences.getInstance();

  await prefs.setString(
    'gardu_scada_users',
    jsonEncode(users),
  );
}

Future<void> muatDataLokal() async {
  final prefs = await SharedPreferences.getInstance();

  final garduJson = prefs.getString('gardu_scada_data');

  if (garduJson != null) {
    final data = jsonDecode(garduJson) as List<dynamic>;

    garduList
      ..clear()
      ..addAll(
        data.map(
          (item) => Gardu.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        ),
      );
  }

  final usersJson = prefs.getString('gardu_scada_users');

  if (usersJson != null) {
    final data = Map<String, dynamic>.from(
      jsonDecode(usersJson) as Map,
    );

    users
      ..clear()
      ..addAll(
        data.map(
          (username, value) => MapEntry(
            username,
            Map<String, String>.from(value as Map),
          ),
        ),
      );
  }

  // Pastikan akun admin demo tetap tersedia.
  // Ini bukan pengganti sistem autentikasi yang aman.
  users.putIfAbsent('admin', () => {
        'password': 'admin123',
        'role': 'Admin',
      });
}

String buatId() => 'G${DateTime.now().millisecondsSinceEpoch}';

Color warnaJenis(String jenis) =>
    jenis.toUpperCase() == 'GT' ? Colors.blue : Colors.deepOrange;

Color warnaKondisi(String kondisi) {
  switch (kondisi) {
    case 'Baik':
      return Colors.green;
    case 'Perlu Pemeriksaan':
      return Colors.orange;
    case 'Rusak':
      return Colors.red;
    default:
      return Colors.grey;
  }
}

void pesan(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}

// ============================================================
// APP
// ============================================================

class GarduScadaApp extends StatelessWidget {
  const GarduScadaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gardu SCADA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FB),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      home: const LoginPage(),
    );
  }
}

// ============================================================
// LOGIN
// ============================================================

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  bool passwordTersembunyi = true;

  void login() {
    final username = usernameController.text.trim();
    final password = passwordController.text;
    final user = users[username];

    if (username.isEmpty || password.isEmpty) {
      pesan(context, 'Username dan password wajib diisi.');
      return;
    }

    if (user == null || user['password'] != password) {
      pesan(context, 'Username atau password salah.');
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => user['role'] == 'Admin'
            ? const AdminPage()
            : const ViewerPage(),
      ),
    );
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const CircleAvatar(
                      radius: 36,
                      backgroundColor: Color(0xFFE3F2FD),
                      child: Icon(
                        Icons.electrical_services,
                        size: 40,
                        color: Color(0xFF1565C0),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Gardu SCADA',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Sistem Informasi dan Monitoring Gardu',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    TextField(
                      controller: usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      onSubmitted: (_) => login(),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passwordController,
                      obscureText: passwordTersembunyi,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                            () => passwordTersembunyi =
                                !passwordTersembunyi,
                          ),
                          icon: Icon(
                            passwordTersembunyi
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                        ),
                      ),
                      onSubmitted: (_) => login(),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: login,
                        icon: const Icon(Icons.login),
                        label: const Text('Masuk'),
                      ),
                    ),
                    const Divider(height: 32),
                    const Text(
                      'Akun demo',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text('Admin: admin / admin123'),
                    const Text('Viewer: viewer / viewer123'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// WIDGET UMUM
// ============================================================

class JudulBagian extends StatelessWidget {
  final String judul;
  final String? deskripsi;

  const JudulBagian({
    super.key,
    required this.judul,
    this.deskripsi,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          judul,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (deskripsi != null) ...[
          const SizedBox(height: 4),
          Text(
            deskripsi!,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ],
    );
  }
}

class KartuStatistik extends StatelessWidget {
  final String judul;
  final String angka;
  final IconData ikon;
  final Color warna;

  const KartuStatistik({
    super.key,
    required this.judul,
    required this.angka,
    required this.ikon,
    required this.warna,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(ikon, color: warna, size: 26),
            const SizedBox(height: 8),
            Text(
              angka,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              judul,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class LabelJenis extends StatelessWidget {
  final String jenis;

  const LabelJenis({super.key, required this.jenis});

  @override
  Widget build(BuildContext context) {
    final warna = warnaJenis(jenis);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: warna.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        jenis,
        style: TextStyle(
          color: warna,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

// ============================================================
// ADMIN: NAVIGASI DAN DASHBOARD
// ============================================================

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  int halaman = 0;

  final judulHalaman = [
    'Dashboard',
    'Data Gardu',
    'Manajemen Pengguna',
  ];

  void logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardAdmin(
        onLihatGardu: () => setState(() => halaman = 1),
      ),
      DataGarduPage(onChanged: () => setState(() {})),
      ManajemenPenggunaPage(
        role: 'Admin',
        onChanged: () => setState(() {}),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 850;

        return Scaffold(
          appBar: AppBar(
            title: Text(judulHalaman[halaman]),
            actions: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Center(child: LabelJenis(jenis: 'ADMIN')),
              ),
              IconButton(
                tooltip: 'Keluar',
                onPressed: logout,
                icon: const Icon(Icons.logout),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Row(
            children: [
              if (desktop)
                NavigationRail(
                  selectedIndex: halaman,
                  onDestinationSelected: (v) {
                    setState(() => halaman = v);
                  },
                  labelType: NavigationRailLabelType.all,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard),
                      label: Text('Dashboard'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.electrical_services_outlined),
                      selectedIcon: Icon(Icons.electrical_services),
                      label: Text('Data Gardu'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.people_outline),
                      selectedIcon: Icon(Icons.people),
                      label: Text('Pengguna'),
                    ),
                  ],
                ),
              Expanded(
                child: IndexedStack(
                  index: halaman,
                  children: pages,
                ),
              ),
            ],
          ),
          bottomNavigationBar: desktop
              ? null
              : NavigationBar(
                  selectedIndex: halaman,
                  onDestinationSelected: (v) {
                    setState(() => halaman = v);
                  },
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      label: 'Dashboard',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.electrical_services),
                      label: 'Gardu',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.people_outline),
                      label: 'Pengguna',
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class DashboardAdmin extends StatelessWidget {
  final VoidCallback onLihatGardu;

  const DashboardAdmin({
    super.key,
    required this.onLihatGardu,
  });

  @override
  Widget build(BuildContext context) {
    final totalGT = garduList.where((g) => g.jenis == 'GT').length;
    final totalGH = garduList.where((g) => g.jenis == 'GH').length;
    final totalPeralatan = garduList.fold<int>(
      0,
      (sum, g) => sum + g.peralatan.length,
    );

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const JudulBagian(
          judul: 'Ringkasan Monitoring',
          deskripsi: 'Ringkasan data gardu dan peralatan SCADA.',
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 900 ? 4 : 2;

            return GridView.count(
              crossAxisCount: columns,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.35,
              children: [
                KartuStatistik(
                  judul: 'Total Gardu',
                  angka: '${garduList.length}',
                  ikon: Icons.electrical_services,
                  warna: Colors.blue,
                ),
                KartuStatistik(
                  judul: 'Gardu GT',
                  angka: '$totalGT',
                  ikon: Icons.bolt,
                  warna: Colors.indigo,
                ),
                KartuStatistik(
                  judul: 'Gardu GH',
                  angka: '$totalGH',
                  ikon: Icons.hub,
                  warna: Colors.deepOrange,
                ),
                KartuStatistik(
                  judul: 'Total Peralatan',
                  angka: '$totalPeralatan',
                  ikon: Icons.settings,
                  warna: Colors.green,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.map_outlined,
                  size: 34,
                  color: Colors.blue,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Data Gardu SCADA',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Kelola lokasi gardu, koordinat, dan peralatan.',
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onLihatGardu,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Kelola Data Gardu'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// DATA GARDU: CARI, FILTER, TAMBAH, EDIT, HAPUS
// ============================================================

class DataGarduPage extends StatefulWidget {
  final VoidCallback onChanged;

  const DataGarduPage({super.key, required this.onChanged});

  @override
  State<DataGarduPage> createState() => _DataGarduPageState();
}

class _DataGarduPageState extends State<DataGarduPage> {
  final cariController = TextEditingController();
  String filterJenis = 'Semua';

  List<Gardu> get hasilFilter {
    final q = cariController.text.toLowerCase();

    return garduList.where((g) {
      final cocokCari = g.nama.toLowerCase().contains(q) ||
          g.id.toLowerCase().contains(q) ||
          g.alamat.toLowerCase().contains(q);

      return cocokCari &&
          (filterJenis == 'Semua' || g.jenis == filterJenis);
    }).toList();
  }

  @override
  void dispose() {
    cariController.dispose();
    super.dispose();
  }

  Future<void> bukaForm({Gardu? gardu}) async {
    final hasil = await showDialog<Gardu>(
      context: context,
      builder: (_) => FormGarduDialog(gardu: gardu),
    );

    if (hasil == null) return;

    setState(() {
      if (gardu == null) {
        garduList.add(hasil);
      } else {
        final index = garduList.indexWhere((g) => g.id == gardu.id);
        if (index != -1) garduList[index] = hasil;
      }
    });

    try {
      await simpanDataGardu();
      widget.onChanged();
      if (mounted) pesan(context, 'Data gardu berhasil disimpan.');
    } catch (e) {
      if (mounted) pesan(context, 'Gagal menyimpan data: $e');
    }
  }

  Future<void> hapusGardu(Gardu gardu) async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus gardu?'),
        content: Text('Hapus ${gardu.nama}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (yakin != true) return;

    final index = garduList.indexWhere((g) => g.id == gardu.id);
    if (index == -1) return;

    final dihapus = garduList.removeAt(index);

    try {
      await simpanDataGardu();
      if (mounted) {
        setState(() {});
        widget.onChanged();
        pesan(context, 'Gardu berhasil dihapus.');
      }
    } catch (e) {
      garduList.insert(index, dihapus);
      if (mounted) pesan(context, 'Gagal menyimpan penghapusan: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final daftar = hasilFilter;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            const Expanded(
              child: JudulBagian(
                judul: 'Data Gardu',
                deskripsi: 'Daftar gardu GT dan GH.',
              ),
            ),
            IconButton.filled(
              tooltip: 'Tambah gardu',
              onPressed: () => bukaForm(),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: cariController,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'Cari nama, ID, atau alamat...',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: filterJenis,
          decoration: const InputDecoration(labelText: 'Jenis gardu'),
          items: const [
            DropdownMenuItem(value: 'Semua', child: Text('Semua jenis')),
            DropdownMenuItem(value: 'GT', child: Text('GT')),
            DropdownMenuItem(value: 'GH', child: Text('GH')),
          ],
          onChanged: (v) {
            if (v != null) setState(() => filterJenis = v);
          },
        ),
        const SizedBox(height: 16),
        Text('${daftar.length} gardu ditemukan'),
        const SizedBox(height: 8),
        if (daftar.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Tidak ada data gardu.'),
            ),
          ),
        ...daftar.map(
          (g) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: warnaJenis(g.jenis).withAlpha(25),
                        child: Icon(
                          Icons.electrical_services,
                          color: warnaJenis(g.jenis),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              g.nama,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${g.id} • ${g.alamat}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      LabelJenis(jenis: g.jenis),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Peralatan: ${g.peralatan.length}'),
                  Text('Koordinat: ${g.lat}, ${g.lng}'),
                  const Divider(height: 24),
                  Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => bukaForm(gardu: g),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => hapusGardu(g),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Hapus'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// FORM GARDU
// ============================================================

class FormGarduDialog extends StatefulWidget {
  final Gardu? gardu;

  const FormGarduDialog({super.key, this.gardu});

  @override
  State<FormGarduDialog> createState() => _FormGarduDialogState();
}

class _FormGarduDialogState extends State<FormGarduDialog> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController namaController;
  late final TextEditingController alamatController;
  late final TextEditingController latController;
  late final TextEditingController lngController;

  String jenis = 'GT';
  late List<Peralatan> peralatan;

  @override
  void initState() {
    super.initState();
    final g = widget.gardu;

    namaController = TextEditingController(text: g?.nama ?? '');
    alamatController = TextEditingController(text: g?.alamat ?? '');
    latController = TextEditingController(
      text: g?.lat.toString() ?? '1.0456',
    );
    lngController = TextEditingController(
      text: g?.lng.toString() ?? '103.9905',
    );

    jenis = g?.jenis ?? 'GT';
    peralatan = g?.peralatan
            .map(
              (p) => Peralatan(
                nama: p.nama,
                merk: p.merk,
                tipe: p.tipe,
                jumlah: p.jumlah,
                satuan: p.satuan,
                kondisi: p.kondisi,
              ),
            )
            .toList() ??
        [];
  }

  @override
  void dispose() {
    namaController.dispose();
    alamatController.dispose();
    latController.dispose();
    lngController.dispose();
    super.dispose();
  }

  Future<void> tambahPeralatan() async {
    final hasil = await showDialog<Peralatan>(
      context: context,
      builder: (_) => const FormPeralatanDialog(),
    );

    if (hasil != null && mounted) {
      setState(() => peralatan.add(hasil));
    }
  }

  void simpan() {
    if (!formKey.currentState!.validate()) return;

    final lat = double.tryParse(latController.text.trim());
    final lng = double.tryParse(lngController.text.trim());

    if (lat == null ||
        lng == null ||
        !lat.isFinite ||
        !lng.isFinite ||
        lat < -90 ||
        lat > 90 ||
        lng < -180 ||
        lng > 180) {
      pesan(context, 'Koordinat tidak valid.');
      return;
    }

    Navigator.pop(
      context,
      Gardu(
        id: widget.gardu?.id ?? buatId(),
        nama: namaController.text.trim(),
        jenis: jenis,
        alamat: alamatController.text.trim(),
        lat: lat,
        lng: lng,
        peralatan: peralatan,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.gardu == null ? 'Tambah Gardu' : 'Edit Gardu'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: namaController,
                  decoration: const InputDecoration(labelText: 'Nama gardu'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: jenis,
                  decoration: const InputDecoration(labelText: 'Jenis gardu'),
                  items: const [
                    DropdownMenuItem(value: 'GT', child: Text('GT')),
                    DropdownMenuItem(value: 'GH', child: Text('GH')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => jenis = v);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: alamatController,
                  decoration: const InputDecoration(labelText: 'Alamat'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: latController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Latitude'),
                  validator: (v) =>
                      double.tryParse(v?.trim() ?? '') == null
                          ? 'Masukkan angka yang valid'
                          : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: lngController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Longitude'),
                  validator: (v) =>
                      double.tryParse(v?.trim() ?? '') == null
                          ? 'Masukkan angka yang valid'
                          : null,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Peralatan SCADA',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      onPressed: tambahPeralatan,
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
                if (peralatan.isEmpty)
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Belum ada peralatan.'),
                  ),
                ...peralatan.asMap().entries.map((entry) {
                  final i = entry.key;
                  final p = entry.value;

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(p.nama),
                    subtitle: Text(
                      '${p.merk} ${p.tipe} • ${p.jumlah} ${p.satuan}',
                    ),
                    trailing: IconButton(
                      onPressed: () {
                        setState(() => peralatan.removeAt(i));
                      },
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: simpan,
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}

// ============================================================
// FORM PERALATAN
// ============================================================

class FormPeralatanDialog extends StatefulWidget {
  const FormPeralatanDialog({super.key});

  @override
  State<FormPeralatanDialog> createState() => _FormPeralatanDialogState();
}

class _FormPeralatanDialogState extends State<FormPeralatanDialog> {
  final formKey = GlobalKey<FormState>();
  final namaController = TextEditingController();
  final merkController = TextEditingController();
  final tipeController = TextEditingController();
  final jumlahController = TextEditingController(text: '1');

  String satuan = 'Unit';
  String kondisi = 'Baik';

  @override
  void dispose() {
    namaController.dispose();
    merkController.dispose();
    tipeController.dispose();
    jumlahController.dispose();
    super.dispose();
  }

  void simpan() {
    if (!formKey.currentState!.validate()) return;

    Navigator.pop(
      context,
      Peralatan(
        nama: namaController.text.trim(),
        merk: merkController.text.trim(),
        tipe: tipeController.text.trim(),
        jumlah: int.parse(jumlahController.text.trim()),
        satuan: satuan,
        kondisi: kondisi,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah Peralatan'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: namaController,
                  decoration: const InputDecoration(
                    labelText: 'Nama peralatan',
                    hintText: 'Contoh: RTU',
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: merkController,
                  decoration: const InputDecoration(labelText: 'Merek'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: tipeController,
                  decoration: const InputDecoration(labelText: 'Tipe'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: jumlahController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Jumlah'),
                  validator: (v) {
                    final n = int.tryParse(v?.trim() ?? '');
                    return n == null || n < 1
                        ? 'Jumlah minimal 1'
                        : null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: satuan,
                  decoration: const InputDecoration(labelText: 'Satuan'),
                  items: const [
                    DropdownMenuItem(value: 'Unit', child: Text('Unit')),
                    DropdownMenuItem(value: 'Set', child: Text('Set')),
                    DropdownMenuItem(value: 'Buah', child: Text('Buah')),
                    DropdownMenuItem(value: 'Meter', child: Text('Meter')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => satuan = v);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: kondisi,
                  decoration: const InputDecoration(labelText: 'Kondisi'),
                  items: const [
                    DropdownMenuItem(value: 'Baik', child: Text('Baik')),
                    DropdownMenuItem(
                      value: 'Perlu Pemeriksaan',
                      child: Text('Perlu Pemeriksaan'),
                    ),
                    DropdownMenuItem(value: 'Rusak', child: Text('Rusak')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => kondisi = v);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: simpan,
          child: const Text('Tambah'),
        ),
      ],
    );
  }
}
class TambahPenggunaDialog extends StatefulWidget {
  const TambahPenggunaDialog({super.key});

  @override
  State<TambahPenggunaDialog> createState() =>
      _TambahPenggunaDialogState();
}

class _TambahPenggunaDialogState
    extends State<TambahPenggunaDialog> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah Akun Viewer'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                ),
                validator: (v) {
                  final name = v?.trim() ?? '';
                  if (name.isEmpty) {
                    return 'Username wajib diisi';
                  }
                  if (users.containsKey(name)) {
                    return 'Username sudah digunakan';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                ),
                validator: (v) => (v ?? '').length < 6
                    ? 'Password minimal 6 karakter'
                    : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () {
            if (formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'username': usernameController.text.trim(),
                'password': passwordController.text,
              });
            }
          },
          child: const Text('Tambah'),
        ),
      ],
    );
  }
}
// ============================================================
// MANAJEMEN PENGGUNA
// ============================================================

class ManajemenPenggunaPage extends StatefulWidget {
  final VoidCallback onChanged;
  final String role;

  const ManajemenPenggunaPage({
    super.key,
    required this.onChanged,
    required this.role,
  });

  @override
  State<ManajemenPenggunaPage> createState() =>
      _ManajemenPenggunaPageState();
}

class _ManajemenPenggunaPageState
    extends State<ManajemenPenggunaPage> {
  Future<void> tambahPengguna() async {
    // Pemeriksaan tambahan di sisi klien; bukan pengganti otorisasi backend.
    if (widget.role != 'Admin') {
      pesan(context, 'Akses ditolak.');
      return;
    }

    final data = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => const TambahPenggunaDialog(),
    );

    if (data == null || !mounted) return;

    final username = data['username']!;

    if (users.containsKey(username)) {
      pesan(context, 'Username sudah digunakan.');
      return;
    }

    users[username] = {
      'password': data['password']!,
      'role': 'Viewer',
    };

    try {
      await simpanDataPengguna();

      if (!mounted) return;

      setState(() {});
      widget.onChanged();
      pesan(context, 'Akun Viewer berhasil ditambahkan.');
    } catch (e) {
      users.remove(username);

      if (mounted) {
        pesan(context, 'Gagal menyimpan akun: $e');
      }
    }
  }

  Future<void> hapusPengguna(String username) async {
    // Pemeriksaan tambahan di sisi klien; bukan pengganti otorisasi backend.
    if (widget.role != 'Admin') {
      pesan(context, 'Akses ditolak.');
      return;
    }

    final yakin = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus pengguna?'),
        content: Text('Hapus akun $username?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (yakin != true) return;

    final lama = users.remove(username);
    if (lama == null) return;

    try {
      await simpanDataPengguna();
      if (mounted) {
        setState(() {});
        widget.onChanged();
        pesan(context, 'Akun berhasil dihapus.');
      }
    } catch (e) {
      users[username] = lama;
      if (mounted) pesan(context, 'Gagal menyimpan penghapusan: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final daftar = users.entries.toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            const Expanded(
              child: JudulBagian(
                judul: 'Manajemen Pengguna',
                deskripsi: 'Kelola akun demo lokal.',
              ),
            ),
            IconButton.filled(
              tooltip: 'Tambah Viewer',
              onPressed: tambahPengguna,
              icon: const Icon(Icons.person_add_alt_1),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...daftar.map((entry) {
          final username = entry.key;
          final role = entry.value['role'] ?? 'Viewer';

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: CircleAvatar(
                child: Icon(
                  role == 'Admin'
                      ? Icons.admin_panel_settings
                      : Icons.person,
                ),
              ),
              title: Text(username),
              subtitle: Text('Role: $role'),
              trailing: role == 'Admin'
                  ? const Chip(label: Text('Admin'))
                  : IconButton(
                      tooltip: 'Hapus akun',
                      onPressed: () => hapusPengguna(username),
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                      ),
                    ),
            ),
          );
        }),
        const SizedBox(height: 8),
        const Text(
          'Akun dan password demo disimpan lokal. '
          'Jangan gunakan password asli.',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }
}

// ============================================================
// PETA INTERAKTIF BATAM
// ============================================================

class InteractiveGarduMap extends StatelessWidget {
  final List<Gardu> garduList;

  const InteractiveGarduMap({
    super.key,
    required this.garduList,
  });

  Future<void> bukaGoogleMaps(Gardu gardu) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${gardu.lat},${gardu.lng}',
    );

    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }

  void tampilkanDetail(BuildContext context, Gardu gardu) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gardu.nama,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    LabelJenis(jenis: gardu.jenis),
                    Chip(label: Text(gardu.id)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Alamat: ${gardu.alamat}'),
                Text('Latitude: ${gardu.lat}'),
                Text('Longitude: ${gardu.lng}'),
                const SizedBox(height: 16),
                const Text(
                  'Peralatan SCADA',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                if (gardu.peralatan.isEmpty)
                  const Text('Belum ada data peralatan.'),
                ...gardu.peralatan.map(
                  (p) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.settings_outlined),
                      title: Text(p.nama),
                      subtitle: Text(
                        '${p.merk} ${p.tipe}\n'
                        'Jumlah: ${p.jumlah} ${p.satuan}',
                      ),
                      isThreeLine: true,
                      trailing: Text(
                        p.kondisi,
                        style: TextStyle(
                          color: warnaKondisi(p.kondisi),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => bukaGoogleMaps(gardu),
                    icon: const Icon(Icons.directions),
                    label: const Text('Petunjuk Arah Google Maps'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final valid = garduList.where((g) =>
        g.lat.isFinite &&
        g.lng.isFinite &&
        g.lat >= -90 &&
        g.lat <= 90 &&
        g.lng >= -180 &&
        g.lng <= 180);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: FlutterMap(
        options: MapOptions(
          initialCenter: const LatLng(1.0456, 103.9905),
          initialZoom: 12,
          minZoom: 11,
          maxZoom: 18,
          cameraConstraint: CameraConstraint.contain(
            bounds: LatLngBounds(
              const LatLng(0.80, 103.70),
              const LatLng(1.30, 104.20),
            ),
          ),
        ),
        children: [
          TileLayer(
            urlTemplate:
                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.todolist',
          ),
          MarkerLayer(
            markers: valid.map((g) {
              final warna = warnaJenis(g.jenis);

              return Marker(
                point: LatLng(g.lat, g.lng),
                width: 90,
                height: 66,
                child: Tooltip(
                  message: g.nama,
                  child: InkWell(
                    onTap: () => tampilkanDetail(context, g),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_on,
                          color: warna,
                          size: 36,
                        ),
                        Container(
                          constraints: const BoxConstraints(maxWidth: 88),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(5),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 3,
                              ),
                            ],
                          ),
                          child: Text(
                            g.nama,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9,
                              color: warna,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          RichAttributionWidget(
            attributions: [
              TextSourceAttribution(
                'OpenStreetMap contributors',
                onTap: () {
                  launchUrl(
                    Uri.parse('https://www.openstreetmap.org/copyright'),
                    mode: LaunchMode.externalApplication,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// VIEWER
// ============================================================

class ViewerPage extends StatefulWidget {
  const ViewerPage({super.key});

  @override
  State<ViewerPage> createState() => _ViewerPageState();
}

class _ViewerPageState extends State<ViewerPage> {
  final cariController = TextEditingController();
  String filterJenis = 'Semua';

  List<Gardu> get hasilFilter {
    final q = cariController.text.toLowerCase();

    return garduList.where((g) {
      final cocokCari = g.nama.toLowerCase().contains(q) ||
          g.id.toLowerCase().contains(q) ||
          g.alamat.toLowerCase().contains(q);

      return cocokCari &&
          (filterJenis == 'Semua' || g.jenis == filterJenis);
    }).toList();
  }

  void logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  @override
  void dispose() {
    cariController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final daftar = hasilFilter;
    final totalPeralatan = garduList.fold<int>(
      0,
      (sum, g) => sum + g.peralatan.length,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gardu SCADA'),
        actions: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Center(child: LabelJenis(jenis: 'VIEWER')),
          ),
          IconButton(
            tooltip: 'Keluar',
            onPressed: logout,
            icon: const Icon(Icons.logout),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const JudulBagian(
            judul: 'Monitoring Gardu',
            deskripsi: 'Peta lokasi dan informasi peralatan SCADA.',
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) => GridView.count(
              crossAxisCount: constraints.maxWidth >= 800 ? 3 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.5,
              children: [
                KartuStatistik(
                  judul: 'Total Gardu',
                  angka: '${garduList.length}',
                  ikon: Icons.electrical_services,
                  warna: Colors.blue,
                ),
                KartuStatistik(
                  judul: 'Gardu GT',
                  angka: '${garduList.where((g) => g.jenis == 'GT').length}',
                  ikon: Icons.bolt,
                  warna: Colors.indigo,
                ),
                KartuStatistik(
                  judul: 'Total Peralatan',
                  angka: '$totalPeralatan',
                  ikon: Icons.settings,
                  warna: Colors.green,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Peta Lokasi Gardu',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 360,
            width: double.infinity,
            child: InteractiveGarduMap(garduList: daftar),
          ),
          const SizedBox(height: 12),
          const Wrap(
            spacing: 16,
            children: [
              _LegendaPeta(warna: Colors.blue, label: 'GT'),
              _LegendaPeta(warna: Colors.deepOrange, label: 'GH'),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Daftar Gardu',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: cariController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Cari nama atau ID gardu...',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: filterJenis,
            decoration: const InputDecoration(labelText: 'Filter jenis'),
            items: const [
              DropdownMenuItem(value: 'Semua', child: Text('Semua jenis')),
              DropdownMenuItem(value: 'GT', child: Text('GT')),
              DropdownMenuItem(value: 'GH', child: Text('GH')),
            ],
            onChanged: (v) {
              if (v != null) setState(() => filterJenis = v);
            },
          ),
          const SizedBox(height: 12),
          Text('${daftar.length} gardu ditemukan'),
          const SizedBox(height: 8),
          if (daftar.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('Gardu tidak ditemukan.'),
              ),
            ),
          ...daftar.map(
            (g) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: warnaJenis(g.jenis).withAlpha(25),
                  child: Icon(
                    Icons.location_on,
                    color: warnaJenis(g.jenis),
                  ),
                ),
                title: Text(
                  g.nama,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${g.id}\n${g.alamat}\n${g.peralatan.length} peralatan',
                ),
                isThreeLine: true,
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // Gunakan detail yang sama dengan marker peta.
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    showDragHandle: true,
                    builder: (context) => SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                g.nama,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              LabelJenis(jenis: g.jenis),
                              const SizedBox(height: 12),
                              Text('Alamat: ${g.alamat}'),
                              Text('Koordinat: ${g.lat}, ${g.lng}'),
                              const SizedBox(height: 12),
                              const Text(
                                'Peralatan',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              ...g.peralatan.map(
                                (p) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(p.nama),
                                  subtitle: Text(
                                    '${p.merk} ${p.tipe} • '
                                    '${p.jumlah} ${p.satuan}',
                                  ),
                                  trailing: Text(
                                    p.kondisi,
                                    style: TextStyle(
                                      color: warnaKondisi(p.kondisi),
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: () {
                                    final uri = Uri.parse(
                                      'https://www.google.com/maps/dir/?api=1'
                                      '&destination=${g.lat},${g.lng}',
                                    );
                                    launchUrl(
                                      uri,
                                      mode: LaunchMode.externalApplication,
                                    );
                                  },
                                  icon: const Icon(Icons.directions),
                                  label: const Text(
                                    'Petunjuk Arah Google Maps',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendaPeta extends StatelessWidget {
  final Color warna;
  final String label;

  const _LegendaPeta({
    required this.warna,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.location_on, color: warna, size: 20),
        Text('Gardu $label'),
      ],
    );
  }
}