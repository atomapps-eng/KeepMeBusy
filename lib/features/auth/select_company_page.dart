import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/session/company_session.dart';
import '../../home/home_page.dart';
import '../../main.dart';
import '../../theme/app_theme.dart';
import 'package:flag/flag.dart';

class SelectCompanyPage extends StatelessWidget {
  final List<String> companyIds;

  const SelectCompanyPage({
    super.key,
    required this.companyIds,
  });

  // Data company dengan informasi lengkap termasuk logo
  Map<String, Map<String, dynamic>> get _companyDetails {
  return {
    'indonesia': {
      'flag': '🇮🇩',
      'logo': 'assets/images/logo_indonesia.png',
      'name': 'ATOM INDONESIA', // Tambah spasi
      'city': 'Jakarta',
      'employees': '128 employees',
      'icon': Icons.location_on,
      'color': const Color(0xFFFF6B6B),
    },
    'india': {
      'flag': '🇮🇳',
      'logo': 'assets/images/logo_india.png',
      'name': 'ATOM INDIA', // Tambah spasi
      'city': 'Mumbai',
      'employees': '256 employees',
      'icon': Icons.location_on,
      'color': const Color(0xFFFFA06B),
    },
    'vietnam': {
      'flag': '🇻🇳',
      'logo': 'assets/images/logo_vietnam.png',
      'name': 'ATOM VIETNAM', // Tambah spasi
      'city': 'Ho Chi Minh',
      'employees': '64 employees',
      'icon': Icons.location_on,
      'color': const Color(0xFF6BCBFF),
    },
    // ... dan seterusnya
  };
}

  String _getUserDisplayName() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'User';
    
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      return user.displayName!.split(' ').first;
    }
    
    if (user.email != null) {
      return user.email!.split('@').first;
    }
    
    return 'User';
  }

  Stream<DocumentSnapshot> _getUserDataStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();
    
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final userName = _getUserDisplayName();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pilih Perusahaan',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.backgroundColor,
                Colors.white,
              ],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.logout, color: AppTheme.primaryColor),
              onPressed: () => globalLogout(context),
              tooltip: 'Logout',
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.backgroundColor,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header dengan logo perusahaan (TANPA LINGKARAN)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo perusahaan - LANGSUNG TANPA LINGKARAN
                    Container(
                      width: 60,
                      height: 60,
                      child: Image.asset(
                        'assets/images/Atom.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 60,
                            height: 60,
                            color: Colors.transparent,
                            child: const Center(
                              child: Text(
                                'KMB',
                                style: TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Teks selamat datang dengan username
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selamat datang,',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        StreamBuilder<DocumentSnapshot>(
                          stream: _getUserDataStream(),
                          builder: (context, snapshot) {
                            String displayName = userName;
                            
                            if (snapshot.hasData && snapshot.data!.exists) {
                              final data = snapshot.data!.data() as Map<String, dynamic>;
                              if (data['name'] != null) {
                                displayName = data['name'].toString().split(' ').first;
                              } else if (data['displayName'] != null) {
                                displayName = data['displayName'].toString().split(' ').first;
                              }
                            }
                            
                            return Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Subtitle
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Pilih perusahaan untuk melanjutkan',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              
              // List perusahaan
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: companyIds.length,
                  itemBuilder: (context, index) {
                    final companyId = companyIds[index];
                    final details = _companyDetails[companyId.toLowerCase()] 
                        ?? _defaultCompany(companyId);
                    
                    return _buildCompanyCard(context, companyId, details);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

 Map<String, dynamic> _defaultCompany(String companyId) {
  // Format nama dengan benar
  final rawName = companyId.toUpperCase();
  String displayName;
  
  if (rawName.contains('ATOM')) {
    final withoutAtom = rawName.replaceAll('ATOM', '').trim();
    displayName = withoutAtom.isEmpty ? 'ATOM' : 'ATOM $withoutAtom';
  } else {
    displayName = 'ATOM $rawName';
  }
  
  return {
    'flag': _getFlagEmoji(companyId), // Gunakan fungsi untuk dapat flag yang benar
    'name': displayName,
    'city': 'Sentul City, Bogor',
    'employees': '0 employees',
    'color': AppTheme.primaryColor,
  };
}

 // Di bagian _companyCard
Widget _buildCompanyCard(
  BuildContext context, 
  String companyId, 
  Map<String, dynamic> details
) {
  final companyColor = details['color'] ?? AppTheme.primaryColor;
  
  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          await CompanySession.setCompany(companyId);
          if (context.mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => const HomePageAfterLogin(),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                companyColor.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: companyColor.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // FLAG SECTION - PILIH SALAH SATU:
                
                // OPSI 2: Flag Package (uncomment jika pakai package flag)
                
                // Bagian flag
Container(
  width: 70,
  height: 70,
  decoration: BoxDecoration(
    color: companyColor.withOpacity(0.1),
    borderRadius: BorderRadius.circular(16),
  ),
  child: Center(
    child: Text(
      details['flag'] ?? _getFlagEmoji(companyId), // Fallback ke fungsi jika details tidak punya flag
      style: const TextStyle(fontSize: 40),
    ),
  ),
),
                
                
                const SizedBox(width: 20),
                
                // Company Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        details['name'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: companyColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            details['city'],
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Arrow icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: companyColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: companyColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

// Fungsi pendukung
// Fungsi untuk mendapatkan emoji flag berdasarkan companyId
String _getFlagEmoji(String companyId) {
  switch (companyId.toLowerCase()) {
    case 'indonesia':
    case 'atomindonesia':
    case 'indonesia atom':
      return '🇮🇩';
      
    case 'india':
    case 'atomindia':
    case 'india atom':
      return '🇮🇳';
      
    case 'vietnam':
    case 'atomvietnam':
    case 'vietnam atom':
      return '🇻🇳';
      
    case 'singapore':
    case 'atomsingapore':
    case 'singapore atom':
      return '🇸🇬';
      
    case 'malaysia':
    case 'atommalaysia':
    case 'malaysia atom':
      return '🇲🇾';
      
    case 'thailand':
    case 'atomthailand':
    case 'thailand atom':
      return '🇹🇭';
      
    case 'jepang':
    case 'atomjepang':
    case 'jepang atom':
      return '🇯🇵';
      
    case 'korea':
    case 'atomkorea':
    case 'korea atom':
      return '🇰🇷';
      
    case 'china':
    case 'atomchina':
    case 'china atom':
      return '🇨🇳';
      
    case 'amerika':
    case 'atomamerika':
    case 'amerika atom':
      return '🇺🇸';
      
    case 'inggris':
    case 'atominggris':
    case 'inggris atom':
      return '🇬🇧';
      
    default:
      // Coba cek apakah companyId mengandung nama negara
      final lowerId = companyId.toLowerCase();
      if (lowerId.contains('indonesia')) return '🇮🇩';
      if (lowerId.contains('india')) return '🇮🇳';
      if (lowerId.contains('vietnam')) return '🇻🇳';
      if (lowerId.contains('singapore')) return '🇸🇬';
      if (lowerId.contains('malaysia')) return '🇲🇾';
      if (lowerId.contains('thailand')) return '🇹🇭';
      if (lowerId.contains('jepang')) return '🇯🇵';
      if (lowerId.contains('korea')) return '🇰🇷';
      if (lowerId.contains('china')) return '🇨🇳';
      if (lowerId.contains('amerika')) return '🇺🇸';
      if (lowerId.contains('inggris')) return '🇬🇧';
      
      // Fallback ke gedung
      return '🏢';
  }
}

// Disimpan untuk referensi jika nanti mau pakai flag package

String _getCountryCode(String companyId) {
  switch (companyId.toLowerCase()) {
    case 'indonesia': return 'ID';
    case 'india': return 'IN';
    case 'vietnam': return 'VN';
    case 'singapore': return 'SG';
    case 'malaysia': return 'MY';
    case 'thailand': return 'TH';
    default: return 'UN';
  }
}
}