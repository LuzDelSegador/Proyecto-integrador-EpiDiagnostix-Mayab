import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../anomalies/presentation/pages/anomalies_page.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../map/presentation/pages/mapa_page.dart';
import '../../../services/presentation/pages/servicios_page.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class CasosPage extends StatefulWidget {
  const CasosPage({super.key});

  @override
  State<CasosPage> createState() => _CasosPageState();
}

class _CasosPageState extends State<CasosPage> {
  int _currentNavIndex = 2;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSyncBanner(),
          _buildSearchBar(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              children: [
                _buildCaseCard(
                  name: 'Juan Pérez',
                  caseId: '#C-902341',
                  status: _CaseStatus.confirmed,
                  date: '12 Oct 2023',
                  location: 'Distrito Central, Sector 4',
                  symptoms: const ['Fiebre alta', 'Tos seca', 'Mialgia'],
                ),
                const SizedBox(height: 10),
                _buildCaseCard(
                  name: 'María García',
                  caseId: '#C-902342',
                  status: _CaseStatus.suspicious,
                  date: '14 Oct 2023',
                  location: 'Aldea Las Nubes',
                  symptoms: const ['Cefalea', 'Fatiga'],
                ),
                const SizedBox(height: 10),
                _buildCaseCard(
                  name: 'Roberto Gómez',
                  caseId: '#C-902345',
                  status: _CaseStatus.monitoring,
                  date: '10 Oct 2023',
                  location: 'Villa Norte, Bloque A',
                  symptoms: const ['Asintomático'],
                ),
                const SizedBox(height: 10),
                _buildCaseCard(
                  name: 'Ana Martínez',
                  caseId: '#C-902350',
                  status: _CaseStatus.confirmed,
                  date: '15 Oct 2023',
                  location: 'Casco Urbano',
                  symptoms: const ['Dificultad respiratoria', 'Fiebre'],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      leading: IconButton(
        icon: const Icon(Icons.account_circle_outlined,
            color: AppColors.textPrimary, size: 26),
        onPressed: () {
          context.read<AuthProvider>().resetStatus();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginPage()),
          );
        },
      ),
      title: const Text(
        'Listado de Casos',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.sync_rounded, color: AppColors.primary, size: 24),
          onPressed: () {},
        ),
      ],
    );
  }

  // ── Sync banner ───────────────────────────────────────────────────────────

  Widget _buildSyncBanner() {
    return Container(
      color: const Color(0xFF1B6E52),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      child: Row(
        children: [
          const Icon(Icons.cloud_done_outlined, color: Colors.white70, size: 16),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Visualizando datos locales — Sincronizado hace 2 min',
              style: TextStyle(color: Colors.white, fontSize: 11, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  // ── Search bar ────────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Buscar por nombre o ID',
                  hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  prefixIcon: Icon(Icons.search_rounded,
                      color: AppColors.textMuted, size: 20),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: const Icon(Icons.tune_rounded,
                color: AppColors.textSecondary, size: 20),
          ),
        ],
      ),
    );
  }

  // ── Case card ─────────────────────────────────────────────────────────────

  Widget _buildCaseCard({
    required String name,
    required String caseId,
    required _CaseStatus status,
    required String date,
    required String location,
    required List<String> symptoms,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: name + badge
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ID: $caseId',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(status: status),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),
          // Body: date + location + symptoms
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildInfoField('REGISTRO', date),
                    ),
                    Expanded(
                      child: _buildInfoField('UBICACIÓN', location),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'SÍNTOMAS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: symptoms
                      .map((s) => _SymptomChip(label: s))
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
            height: 1.3,
          ),
        ),
      ],
    );
  }

  // ── Bottom Nav ────────────────────────────────────────────────────────────

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentNavIndex,
      onTap: (i) {
        if (i == 0) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else if (i == 1) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AnomaliesPage()),
          );
        } else if (i == 2) {
          // ya estamos aquí
        } else if (i == 3) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const MapaPage()),
          );
        } else if (i == 4) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ServiciosPage()),
          );
        } else {
          setState(() => _currentNavIndex = i);
        }
      },
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textMuted,
      backgroundColor: Colors.white,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle:
          const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(fontSize: 10),
      elevation: 10,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          activeIcon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.warning_amber_outlined),
          activeIcon: Icon(Icons.warning_amber_rounded),
          label: 'Anomalías',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.folder_outlined),
          activeIcon: Icon(Icons.folder),
          label: 'Casos',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.map_outlined),
          activeIcon: Icon(Icons.map),
          label: 'Mapa',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.medical_services_outlined),
          activeIcon: Icon(Icons.medical_services),
          label: 'Servicios',
        ),
      ],
    );
  }
}

// ── Status enum ───────────────────────────────────────────────────────────────

enum _CaseStatus { confirmed, suspicious, monitoring }

// ── Status badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final _CaseStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (icon, label, bg, fg) = switch (status) {
      _CaseStatus.confirmed => (
          Icons.circle,
          'Confirmado',
          const Color(0xFFFFE4E4),
          const Color(0xFFDC2626),
        ),
      _CaseStatus.suspicious => (
          Icons.warning_amber_rounded,
          'Sospechoso',
          const Color(0xFFFEF3C7),
          const Color(0xFFD97706),
        ),
      _CaseStatus.monitoring => (
          Icons.trending_up_rounded,
          'En Seguimiento',
          const Color(0xFFDCFCE7),
          const Color(0xFF059669),
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: fg, size: 11),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Symptom chip ──────────────────────────────────────────────────────────────

class _SymptomChip extends StatelessWidget {
  final String label;
  const _SymptomChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
