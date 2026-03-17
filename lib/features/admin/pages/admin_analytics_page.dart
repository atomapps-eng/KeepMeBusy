// lib/features/admin/pages/admin_analytics_page.dart
import 'dart:developer';
import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../models/read_tracker_service.dart';
import '../../../theme/app_theme.dart';
import '../../../models/analytics_data.dart';
import 'dart:async';

class AdminAnalyticsPage extends StatefulWidget {
  const AdminAnalyticsPage({super.key});

  @override
  State<AdminAnalyticsPage> createState() => _AdminAnalyticsPageState();
}

class _AdminAnalyticsPageState extends State<AdminAnalyticsPage> {
  final ReadTrackerService _tracker = ReadTrackerService();
  bool _isTracking = false;
  String _selectedView = 'overview';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: BoxDecoration(
  gradient: AppTheme.backgroundGradient,
),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(),
                
                // Control Bar
                _buildControlBar(),
                
                // Content
                Expanded(
                  child: _buildContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(30),
        bottomRight: Radius.circular(30),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            border: Border.all(color: Colors.white.withOpacity(0.4)),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.analytics,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Admin Analytics',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlBar() {
    final data = _tracker.getAnalytics();
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildTrackingButton(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildExportButton(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Reads Recorded:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '${data.totalReads}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildViewChip('Overview', 'overview'),
              const SizedBox(width: 8),
              _buildViewChip('By Page', 'by_page'),
              const SizedBox(width: 8),
              _buildViewChip('By Collection', 'by_collection'),
              const SizedBox(width: 8),
              _buildViewChip('Recent', 'recent'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingButton() {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: _isTracking ? Colors.red : Colors.green,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      icon: Icon(_isTracking ? Icons.stop : Icons.play_arrow),
      label: Text(_isTracking ? 'Stop Tracking' : 'Start Tracking'),
      onPressed: () {
        setState(() {
          if (_isTracking) {
            _tracker.stopTracking();
          } else {
            _tracker.startTracking();
          }
          _isTracking = !_isTracking;
        });
      },
    );
  }

  Widget _buildExportButton() {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      icon: const Icon(Icons.download),
      label: const Text('Export Data'),
      onPressed: () {
        final data = _tracker.exportData();
        log('📊 EXPORT: $data');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data exported to console'),
            backgroundColor: Colors.green,
          ),
        );
      },
    );
  }

  Widget _buildViewChip(String label, String value) {
    final isSelected = _selectedView == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedView = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : Colors.grey.shade400,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? Colors.white : Colors.grey.shade700,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final data = _tracker.getAnalytics();

    if (data.totalReads == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No data yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Click "Start Tracking" to begin monitoring reads',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    switch (_selectedView) {
      case 'overview':
        return _buildOverview(data);
      case 'by_page':
        return _buildByPage(data);
      case 'by_collection':
        return _buildByCollection(data);
      case 'recent':
        return _buildRecent(data);
      default:
        return _buildOverview(data);
    }
  }

  Widget _buildOverview(AnalyticsData data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Summary Cards
          _buildSummaryCard(
            'Total Reads',
            data.totalReads.toString(),
            Icons.remove_red_eye,
            Colors.blue,
          ),
          const SizedBox(height: 16),
          
          // Top Pages
          _buildSectionCard(
            title: 'Top Pages',
            icon: Icons.web,
            color: Colors.green,
            child: Column(
              children: data.readsByPage.entries
                  .map((entry) => _buildStatRow(
                        entry.key,
                        entry.value,
                        data.totalReads,
                        Colors.green,
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          
          // Top Collections
          _buildSectionCard(
            title: 'Top Collections',
            icon: Icons.storage,
            color: Colors.orange,
            child: Column(
              children: data.readsByCollection.entries
                  .map((entry) => _buildStatRow(
                        entry.key,
                        entry.value,
                        data.totalReads,
                        Colors.orange,
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildByPage(AnalyticsData data) {
    final sortedPages = data.readsByPage.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _buildListCard(
      title: 'Reads by Page',
      icon: Icons.web,
      data: sortedPages,
    );
  }

  Widget _buildByCollection(AnalyticsData data) {
    final sortedCollections = data.readsByCollection.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _buildListCard(
      title: 'Reads by Collection',
      icon: Icons.storage,
      data: sortedCollections,
    );
  }

  Widget _buildRecent(AnalyticsData data) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: data.recentReads.length,
      itemBuilder: (context, index) {
        final read = data.recentReads[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.4)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getOperationColor(read.operation).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.remove_red_eye,
                  size: 16,
                  color: _getOperationColor(read.operation),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      read.page,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${read.collection} • ${read.documentsCount} docs',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${read.timestamp.hour}:${read.timestamp.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.2),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, int value, int total, Color color) {
    final percentage = (value / total * 100).toStringAsFixed(1);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value / total,
                backgroundColor: color.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$value ($percentage%)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListCard({
    required String title,
    required IconData icon,
    required List<MapEntry<String, int>> data,
  }) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final entry = data[index];
        final percentage = (entry.value / data.fold(0, (sum, e) => sum + e.value) * 100).toStringAsFixed(1);
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.4)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getRandomColor(index).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: _getRandomColor(index)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: entry.value / data.first.value,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(_getRandomColor(index)),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${entry.value}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '$percentage%',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getOperationColor(String operation) {
    switch (operation) {
      case 'get':
        return Colors.blue;
      case 'getMany':
        return Colors.green;
      case 'stream':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getRandomColor(int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
    ];
    return colors[index % colors.length];
  }
  // Di admin_analytics_page.dart, tambahkan auto-refresh
@override
void initState() {
  super.initState();
  _isTracking = _tracker.isTracking;
  
  // Auto refresh setiap 2 detik
  Timer.periodic(const Duration(seconds: 2), (timer) {
    if (mounted) {
      setState(() {}); // Refresh UI dengan data terbaru
    }
  });
}
}