import 'package:flutter/cupertino.dart';
import 'package:smart_iraq/src/core/theme/app_theme.dart';

class FilterOptions {
  final String? category;
  final String? condition;
  final String? sortBy;
  final bool? sortAscending;

  FilterOptions({this.category, this.condition, this.sortBy, this.sortAscending});
}

class FilterModal extends StatefulWidget {
  final FilterOptions initialFilters;

  const FilterModal({Key? key, required this.initialFilters}) : super(key: key);

  @override
  _FilterModalState createState() => _FilterModalState();
}

class _FilterModalState extends State<FilterModal> {
  String? _selectedCategory;
  String? _selectedCondition;
  String? _selectedSortBy;
  bool? _sortAscending;

  // Hardcoded categories for now
  final List<String> _categories = [
    'Electronics',
    'Food & Beverage',
    'Construction Materials',
    'Automotive Parts',
    'Textiles & Apparel',
    'Office Supplies',
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialFilters.category;
    _selectedCondition = widget.initialFilters.condition;
    _selectedSortBy = widget.initialFilters.sortBy;
    _sortAscending = widget.initialFilters.sortAscending;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      padding: const EdgeInsets.all(20.0),
      decoration: const BoxDecoration(
        color: AppTheme.charcoalBackground,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Category'),
          _buildCategorySelector(),
          const SizedBox(height: 20),

          _buildSectionTitle('Condition'),
          _buildConditionSelector(),
          const SizedBox(height: 20),

          _buildSectionTitle('Sort By'),
          _buildSortSelector(),
          const Spacer(),

          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: CupertinoTheme.of(context).textTheme.navTitleTextStyle.copyWith(fontSize: 18));
  }

  Widget _buildCategorySelector() {
    // A dropdown-like button for categories
    return CupertinoButton(
      child: Text(_selectedCategory ?? 'Select Category'),
      onPressed: () => _showPicker(_categories, _selectedCategory, (newValue) {
        setState(() => _selectedCategory = newValue);
      }),
    );
  }

  Widget _buildConditionSelector() {
    return CupertinoSegmentedControl<String>(
      groupValue: _selectedCondition,
      children: const {
        'new': Text('New'),
        'used': Text('Used'),
      },
      onValueChanged: (value) {
        setState(() => _selectedCondition = value);
      },
    );
  }

  Widget _buildSortSelector() {
    return Row(
      children: [
        Expanded(
          child: CupertinoSegmentedControl<String>(
            groupValue: _selectedSortBy,
            children: const {
              'created_at': Text('Date'),
              'price': Text('Price'),
            },
            onValueChanged: (value) {
              setState(() => _selectedSortBy = value);
            },
          ),
        ),
        const SizedBox(width: 10),
        CupertinoSegmentedControl<bool>(
          groupValue: _sortAscending,
          children: const {
            false: Icon(CupertinoIcons.arrow_down),
            true: Icon(CupertinoIcons.arrow_up),
          },
          onValueChanged: (value) {
            setState(() => _sortAscending = value);
          },
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: CupertinoButton(
            child: const Text('Clear All'),
            onPressed: () {
              setState(() {
                _selectedCategory = null;
                _selectedCondition = null;
                _selectedSortBy = null;
                _sortAscending = null;
              });
            },
          ),
        ),
        Expanded(
          child: CupertinoButton.filled(
            child: const Text('Apply Filters'),
            onPressed: () {
              final newFilters = FilterOptions(
                category: _selectedCategory,
                condition: _selectedCondition,
                sortBy: _selectedSortBy,
                sortAscending: _sortAscending,
              );
              Navigator.of(context).pop(newFilters);
            },
          ),
        ),
      ],
    );
  }

  void _showPicker(List<String> items, String? currentValue, ValueChanged<String> onSelectedItemChanged) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => Container(
        height: 250,
        color: AppTheme.darkSurface,
        child: CupertinoPicker(
          itemExtent: 32.0,
          onSelectedItemChanged: (int index) {
            onSelectedItemChanged(items[index]);
          },
          scrollController: FixedExtentScrollController(
            initialItem: currentValue != null ? items.indexOf(currentValue) : 0,
          ),
          children: items.map((String value) => Center(child: Text(value, style: const TextStyle(color: AppTheme.lightTextColor)))).toList(),
        ),
      ),
    );
  }
}
