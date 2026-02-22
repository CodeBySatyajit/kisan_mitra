import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'store_dashboard_controller.dart';
import 'store_inventory_model.dart';
import '../stock/store_stock_screen.dart';
import '../stock/fertilizer_details_screen.dart';
import '../location/store_location_screen.dart';
import '../profile/store_profile_screen.dart';
import '../../../l10n/app_localizations.dart';

/// Store Dashboard Screen
/// Main dashboard for store owners with inventory management
/// Uses IndexedStack for persistent bottom navigation
class StoreDashboardScreen extends StatefulWidget {
  const StoreDashboardScreen({super.key});

  @override
  State<StoreDashboardScreen> createState() => _StoreDashboardScreenState();
}

class _StoreDashboardScreenState extends State<StoreDashboardScreen> {
  int _selectedIndex = 0;

  // Handle bottom navigation tab changes
  void _onBottomNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StoreDashboardController()..initialize(),
      child: Scaffold(
        backgroundColor: const Color(0xFFE8F5E9), // Light mint green background
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            // Index 0: Dashboard
            const _DashboardTab(),

            // Index 1: Stock
            const StoreStockScreen(),

            // Index 2: Location
            const StoreLocationScreen(),

            // Index 3: Profile
            const StoreProfileScreen(),
          ],
        ),
        bottomNavigationBar: _buildBottomNavigation(),
      ),
    );
  }

  /// Bottom navigation bar
  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: _buildNavItem(
                  icon: Icons.dashboard_outlined,
                  label: AppLocalizations.of(context).dashboard.toUpperCase(),
                  index: 0,
                  isSelected: _selectedIndex == 0,
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  icon: Icons.inventory_2,
                  label: AppLocalizations.of(context).stock.toUpperCase(),
                  index: 1,
                  isSelected: _selectedIndex == 1,
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  icon: Icons.location_on_outlined,
                  label: AppLocalizations.of(context).storeLocation.toUpperCase(),
                  index: 2,
                  isSelected: _selectedIndex == 2,
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  icon: Icons.person_outline,
                  label: AppLocalizations.of(context).profile.toUpperCase(),
                  index: 3,
                  isSelected: _selectedIndex == 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Bottom navigation item
  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => _onBottomNavTap(index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F5E9) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF2E7D32) : Colors.grey,
              size: 20,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 8,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? const Color(0xFF2E7D32) : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Main Dashboard Tab
class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<StoreDashboardController>(context);

    return SafeArea(
      child: Column(
        children: [
          // Header with title and profile icon
          _buildHeader(context),

          // Scrollable content
          Expanded(
            child: controller.isLoading
                ? const Center(child: CircularProgressIndicator())
                : controller.error != null
                ? Center(
                    child: Text(
                      AppLocalizations.of(
                        context,
                      ).errorPrefix(controller.error!),
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Store Info Card
                        _buildStoreInfoCard(controller.storeInfo!),

                        const SizedBox(height: 20),

                        // Action Buttons
                        _buildActionButtons(context),

                        const SizedBox(height: 24),

                        // Inventory Management Section
                        Builder(
                          builder: (context) => Text(
                            AppLocalizations.of(context).inventoryManagement,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Fertilizer List with StreamBuilder
                        _buildFertilizerList(),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// Header with title, verified badge, and profile icon
  Widget _buildHeader(BuildContext context) {
    final controller = Provider.of<StoreDashboardController>(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Text(
            AppLocalizations.of(context).storeDashboard,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          if (controller.storeInfo?.isVerified == true)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFC8E6C9), // Light green
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.verified,
                    size: 14,
                    color: Color(0xFF2E7D32),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    AppLocalizations.of(context).verified,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
            ),
          const Spacer(),
          IconButton(
            onPressed: () {
              // Navigate to profile tab
              final dashboardState = context
                  .findAncestorStateOfType<_StoreDashboardScreenState>();
              dashboardState?._onBottomNavTap(3);
            },
            icon: const Icon(Icons.person_outline),
            tooltip: AppLocalizations.of(context).profile,
          ),
        ],
      ),
    );
  }

  /// Store Info Card
  Widget _buildStoreInfoCard(StoreInfo storeInfo) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
          // Store Name and Rating
          Row(
            children: [
              Expanded(
                child: Text(
                  storeInfo.storeName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Icon(Icons.star, size: 16, color: Color(0xFFFFA000)),
              const SizedBox(width: 4),
              Text(
                storeInfo.rating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Address
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: Colors.grey,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  storeInfo.address,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Phone
          Row(
            children: [
              const Icon(Icons.phone_outlined, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                storeInfo.phone,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Action Buttons (Update Price & Stock, Store Location)
  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        // Update Price & Stock Button
        Expanded(
          child: _ActionCard(
            icon: Icons.inventory_2_outlined,
            label: AppLocalizations.of(context).updatePriceStock,
            color: const Color(0xFF2E7D32),
            onTap: () {
              // Navigate to Stock tab
              final dashboardState = context
                  .findAncestorStateOfType<_StoreDashboardScreenState>();
              dashboardState?._onBottomNavTap(1);
            },
          ),
        ),

        const SizedBox(width: 16),

        // Store Location Button
        Expanded(
          child: _ActionCard(
            icon: Icons.location_on_outlined,
            label: AppLocalizations.of(context).storeLocation,
            color: const Color(0xFF1976D2),
            onTap: () {
              // Navigate to Location tab
              final dashboardState = context
                  .findAncestorStateOfType<_StoreDashboardScreenState>();
              dashboardState?._onBottomNavTap(2);
            },
          ),
        ),
      ],
    );
  }

  /// Fertilizer List with StreamBuilder
  Widget _buildFertilizerList() {
    return Consumer<StoreDashboardController>(
      builder: (context, controller, _) {
        return StreamBuilder<List<StoreFertilizer>>(
          stream: controller.getStoreFertilizersStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  AppLocalizations.of(
                    context,
                  ).errorPrefix(snapshot.error.toString()),
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            final fertilizers = snapshot.data ?? [];

            if (fertilizers.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    AppLocalizations.of(context).noFertilizersInventory,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              );
            }

            return Column(
              children: fertilizers
                  .map((fertilizer) => _FertilizerCard(fertilizer: fertilizer))
                  .toList(),
            );
          },
        );
      },
    );
  }
}

/// Action Card Widget
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
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
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fertilizer Card with editable price and stock
class _FertilizerCard extends StatefulWidget {
  final StoreFertilizer fertilizer;

  const _FertilizerCard({required this.fertilizer});

  @override
  State<_FertilizerCard> createState() => _FertilizerCardState();
}

class _FertilizerCardState extends State<_FertilizerCard> {
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(
      text: widget.fertilizer.price.toStringAsFixed(0),
    );
    _stockController = TextEditingController(
      text: widget.fertilizer.stock.toString(),
    );
  }

  @override
  void dispose() {
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final controller = Provider.of<StoreDashboardController>(
      context,
      listen: false,
    );

    // Parse input
    final price = double.tryParse(_priceController.text);
    final stock = int.tryParse(_stockController.text);

    if (price == null || stock == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).enterValidNumbers),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final result = await controller.updatePriceAndStock(
      fertilizerId: widget.fertilizer.id,
      price: price,
      stock: stock,
    );

    setState(() {
      _isSaving = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message'] ??
                AppLocalizations.of(context).updatedSuccessfully,
          ),
          backgroundColor: result['success'] == true
              ? Colors.green
              : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine stock status
    final currentStock =
        int.tryParse(_stockController.text) ?? widget.fertilizer.stock;
    final isInStock = currentStock > 0 && widget.fertilizer.isAvailable;
    final isLowStock = currentStock > 0 && currentStock <= 10;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isInStock
              ? (isLowStock ? Colors.orange.shade100 : const Color(0xFFE8F5E9))
              : Colors.red.shade100,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section with Gradient
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFFE8F5E9), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fertilizer Icon with better styling
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.eco, size: 28, color: Colors.white),
                ),

                const SizedBox(width: 14),

                // Fertilizer Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Fertilizer Name with better styling
                      Text(
                        widget.fertilizer.fertilizerName ??
                            AppLocalizations.of(context).loading,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1B5E20),
                          letterSpacing: 0.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 12),

                      // Additional Details Row: NPK, Form, Category, Manufacturer
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          // NPK Badge
                          if (widget.fertilizer.npkComposition != null &&
                              widget.fertilizer.npkComposition!.isNotEmpty)
                            _buildInfoChip(
                              icon: Icons.analytics_outlined,
                              label: widget.fertilizer.npkComposition!,
                              color: const Color(0xFF0288D1),
                            ),

                          // Form Badge (Granular, Liquid, Powder, etc.)
                          if (widget.fertilizer.form != null &&
                              widget.fertilizer.form!.isNotEmpty)
                            _buildInfoChip(
                              icon: Icons.grain_outlined,
                              label: widget.fertilizer.form!,
                              color: const Color(0xFF1976D2),
                            ),

                          // Category Badge
                          if (widget.fertilizer.category != null &&
                              widget.fertilizer.category!.isNotEmpty)
                            _buildInfoChip(
                              icon: Icons.category_outlined,
                              label: widget.fertilizer.category!,
                              color: const Color(0xFF7B1FA2),
                            ),

                          // Manufacturer Badge
                          if (widget.fertilizer.manufacturer != null &&
                              widget.fertilizer.manufacturer!.isNotEmpty)
                            _buildInfoChip(
                              icon: Icons.business_outlined,
                              label: widget.fertilizer.manufacturer!,
                              color: const Color(0xFFE65100),
                            ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Stock Status Badge with animation-ready design
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isInStock
                                ? (isLowStock
                                      ? [
                                          Colors.orange.shade400,
                                          Colors.orange.shade600,
                                        ]
                                      : [
                                          const Color(0xFF1FB327),
                                          const Color(0xFF2E7D32),
                                        ])
                                : [Colors.red.shade400, Colors.red.shade600],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (isInStock
                                          ? (isLowStock
                                                ? Colors.orange.shade300
                                                : const Color(0xFF2E7D32))
                                          : Colors.red.shade300)
                                      .withValues(alpha: 0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isInStock
                                  ? (isLowStock
                                        ? Icons.warning_rounded
                                        : Icons.check_circle_rounded)
                                  : Icons.cancel_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isInStock
                                  ? (isLowStock
                                        ? AppLocalizations.of(context).lowStock
                                        : AppLocalizations.of(context).inStock)
                                  : AppLocalizations.of(context).outOfStock,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Price and Stock Inputs Row with enhanced design
                Row(
                  children: [
                    // Price Input
                    Expanded(
                      child: _buildInputField(
                        controller: _priceController,
                        label: AppLocalizations.of(context).price,
                        icon: Icons.currency_rupee_rounded,
                        color: const Color(0xFF1976D2),
                      ),
                    ),

                    const SizedBox(width: 14),

                    // Stock Input
                    Expanded(
                      child: _buildInputField(
                        controller: _stockController,
                        label: AppLocalizations.of(context).stockBags,
                        icon: Icons.inventory_2_rounded,
                        color: const Color(0xFF388E3C),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Action Buttons Row with better spacing
                Row(
                  children: [
                    // View Details Button
                    Expanded(
                      flex: 5,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FertilizerDetailsScreen(
                                fertilizerId: widget.fertilizer.fertilizerId,
                                fertilizerName:
                                    widget.fertilizer.fertilizerName ??
                                    AppLocalizations.of(context).fertilizer,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.info_outline_rounded, size: 18),
                        label: Text(
                          AppLocalizations.of(
                            context,
                          ).viewDetails.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2E7D32),
                          side: const BorderSide(
                            color: Color(0xFF2E7D32),
                            width: 2,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Save Button with gradient
                    Expanded(
                      flex: 5,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: _isSaving
                              ? null
                              : const LinearGradient(
                                  colors: [
                                    Color(0xFF4CAF50),
                                    Color(0xFF2E7D32),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _isSaving
                              ? null
                              : [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF2E7D32,
                                    ).withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _handleSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isSaving
                                ? Colors.grey.shade300
                                : Colors.transparent,
                            foregroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.save_rounded, size: 18),
                          label: Text(
                            _isSaving
                                ? AppLocalizations.of(context).saving
                                : AppLocalizations.of(
                                    context,
                                  ).save.toUpperCase(),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: _isSaving
                                  ? Colors.grey.shade600
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build consistent input fields
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label with icon
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Input field with enhanced styling
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: color, width: 2.5),
              ),
            ),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  // Helper method to build info chips
  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
