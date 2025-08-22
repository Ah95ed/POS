import 'package:flutter/material.dart';

/// Widget الفلاتر السريعة
class QuickFiltersWidget extends StatelessWidget {
  final String selectedFilter;
  final Function(String) onFilterChanged;

  const QuickFiltersWidget({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip('الكل', 'all', Icons.inventory_2),
          const SizedBox(width: 8),
          _buildFilterChip('نشط', 'active', Icons.check_circle),
          const SizedBox(width: 8),
          _buildFilterChip('نافد', 'out_of_stock', Icons.error),
          const SizedBox(width: 8),
          _buildFilterChip('منخفض', 'low_stock', Icons.warning),
          const SizedBox(width: 8),
          _buildFilterChip('منتهي', 'expired', Icons.dangerous),
          const SizedBox(width: 8),
          _buildFilterChip('قريب الانتهاء', 'near_expiry', Icons.schedule),
          const SizedBox(width: 8),
          _buildFilterChip('مؤرشف', 'archived', Icons.archive),
        ],
      ),
    );
  }

  /// بناء رقاقة الفلتر
  Widget _buildFilterChip(String label, String value, IconData icon) {
    final isSelected = selectedFilter == value;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? Colors.white : Colors.grey[600],
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[700],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) => onFilterChanged(value),
      backgroundColor: Colors.grey[100],
      selectedColor: _getFilterColor(value),
      checkmarkColor: Colors.white,
      elevation: isSelected ? 2 : 0,
      pressElevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? _getFilterColor(value) : Colors.grey[300]!,
          width: 1,
        ),
      ),
    );
  }

  /// الحصول على لون الفلتر
  Color _getFilterColor(String filter) {
    switch (filter) {
      case 'all':
        return Colors.blue[700]!;
      case 'active':
        return Colors.green[700]!;
      case 'out_of_stock':
        return Colors.red[700]!;
      case 'low_stock':
        return Colors.orange[700]!;
      case 'expired':
        return Colors.red[800]!;
      case 'near_expiry':
        return Colors.yellow[700]!;
      case 'archived':
        return Colors.grey[700]!;
      default:
        return Colors.blue[700]!;
    }
  }
}
