import 'package:flutter/material.dart';
import '../../core/session/company_session.dart';
import '../../home/home_page.dart';
import 'package:firebase_auth/firebase_auth.dart'; 

class SelectCompanyPage extends StatelessWidget {
  final List<String> companyIds;

  const SelectCompanyPage({
    super.key,
    required this.companyIds,
  });

  String _flagOf(String companyId) {
    switch (companyId.toLowerCase()) {
      case 'indonesia':
        return '🇮🇩';
      case 'india':
        return '🇮🇳';
      case 'vietnam':
        return '🇻🇳';
      default:
        return '🏢';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Company"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // Clear session dan logout
              await CompanySession.clear();
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Choose Your Company",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: companyIds.length,
                itemBuilder: (context, index) {
                  return _companyCard(context, companyIds[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _companyCard(BuildContext context, String companyId) {
    final flag = _flagOf(companyId);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Text(
          flag,
          style: const TextStyle(fontSize: 26),
        ),
        title: Text(
          companyId.toUpperCase(),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          await CompanySession.setCompany(companyId);
          
          if (context.mounted) {
            // Gunakan pushAndRemoveUntil untuk reset navigator
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => const HomePageAfterLogin(),
              ),
              (route) => false, // Remove all previous routes
            );
          }
        },
      ),
    );
  }
}