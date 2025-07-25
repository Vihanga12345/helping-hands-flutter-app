import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../services/admin_data_service.dart';

class AdminUsersHelpeesPage extends StatefulWidget {
  const AdminUsersHelpeesPage({super.key});

  @override
  State<AdminUsersHelpeesPage> createState() => _AdminUsersHelpeesPageState();
}

class _AdminUsersHelpeesPageState extends State<AdminUsersHelpeesPage> {
  final _adminDataService = AdminDataService();
  List<Map<String, dynamic>> _helpees = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadHelpees();
  }

  Future<void> _loadHelpees() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final helpees = await _adminDataService.getAllHelpees();

      if (mounted) {
        setState(() {
          _helpees = helpees;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load helpees: $e';
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filteredHelpees {
    if (_searchQuery.isEmpty) return _helpees;

    return _helpees.where((helpee) {
      final name = (helpee['full_name'] ?? '').toString().toLowerCase();
      final email = (helpee['email'] ?? '').toString().toLowerCase();
      final phone = (helpee['phone'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();

      return name.contains(query) ||
          email.contains(query) ||
          phone.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'All Helpees',
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => context.go('/admin/home'),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: AppColors.primaryGreen,
            padding: const EdgeInsets.all(20),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search helpees by name, email, or phone...',
                  prefixIcon:
                      const Icon(Icons.search, color: AppColors.primaryGreen),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? _buildErrorState()
                    : _buildHelpeesContent(isDesktop),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: TextStyle(
              color: Colors.red.shade700,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadHelpees,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpeesContent(bool isDesktop) {
    final filteredHelpees = _filteredHelpees;

    if (filteredHelpees.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isEmpty ? Icons.people_outline : Icons.search_off,
              size: 64,
              color: AppColors.mediumGrey,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'No helpees found in the system'
                  : 'No helpees match your search',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHelpees,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with count
            Row(
              children: [
                Text(
                  'Found ${filteredHelpees.length} helpees',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadHelpees,
                  color: AppColors.primaryGreen,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Helpees List
            Expanded(
              child: isDesktop
                  ? _buildHelpeesGrid(filteredHelpees)
                  : _buildHelpeesList(filteredHelpees),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpeesGrid(List<Map<String, dynamic>> helpees) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: helpees.length,
      itemBuilder: (context, index) {
        return _buildHelpeeCard(helpees[index], isGrid: true);
      },
    );
  }

  Widget _buildHelpeesList(List<Map<String, dynamic>> helpees) {
    return ListView.builder(
      itemCount: helpees.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildHelpeeCard(helpees[index], isGrid: false),
        );
      },
    );
  }

  Widget _buildHelpeeCard(Map<String, dynamic> helpee, {required bool isGrid}) {
    final String name = helpee['full_name'] ?? 'Unknown';
    final String email = helpee['email'] ?? '';
    final String phone = helpee['phone'] ?? '';
    final String location = helpee['location'] ?? '';
    final String userId = helpee['id'] ?? '';

    return GestureDetector(
      onTap: () => context.go('/admin/users/helpee-profile/$userId'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                  radius: isGrid ? 20 : 24,
                  child: Icon(
                    Icons.person,
                    color: AppColors.primaryBlue,
                    size: isGrid ? 20 : 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: isGrid ? 14 : 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (email.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: TextStyle(
                            fontSize: isGrid ? 12 : 14,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (!isGrid || phone.isNotEmpty || location.isNotEmpty) ...[
              const SizedBox(height: 12),
              if (phone.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(
                      Icons.phone,
                      size: isGrid ? 14 : 16,
                      color: AppColors.primaryGreen,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        phone,
                        style: TextStyle(
                          fontSize: isGrid ? 12 : 14,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (location.isNotEmpty) const SizedBox(height: 8),
              ],
              if (location.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: isGrid ? 14 : 16,
                      color: AppColors.primaryOrange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        location,
                        style: TextStyle(
                          fontSize: isGrid ? 12 : 14,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
