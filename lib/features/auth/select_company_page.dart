import 'package:flutter/material.dart';
import '../../core/session/company_session.dart';
import '../../home/home_page.dart';

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

            ...companyIds.map((companyId) {
              return _companyCard(context, companyId);
            }),
          ],
        ),
      ),
    );
  }

  Widget _companyCard(BuildContext context, String companyId) {
    final flag = _flagOf(companyId);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () async {
        await CompanySession.setCompany(companyId);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const HomePageAfterLogin(),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            Text(
              flag,
              style: const TextStyle(fontSize: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                companyId.toUpperCase(),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}