import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kenick_vip/theme/app_colors.dart';
import 'package:kenick_vip/widgets/custom_button.dart';
import 'package:kenick_vip/utils/custom_toast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kenick_vip/repositories/support_repository.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = '';
  bool _isLoading = false;
  final SupportRepository _supportRepo = SupportRepository();

  final List<Map<String, String>> _categories = [
    {'value': 'ride_issue', 'label': 'Ride Issue'},
    {'value': 'payment_issue', 'label': 'Payment Issue'},
    {'value': 'safety_concern', 'label': 'Safety Concern'},
    {'value': 'account_issue', 'label': 'Account Issue'},
    {'value': 'other', 'label': 'Other'},
  ];

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_selectedCategory.isEmpty ||
        _subjectController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty) {
      CustomToast.showError(context, 'Please fill all fields');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await _supportRepo.createTicket(
          userId: user.id,
          category: _selectedCategory,
          subject: _subjectController.text.trim(),
          description: _descriptionController.text.trim(),
        );
      }

      if (mounted) {
        CustomToast.showSuccess(context, 'Ticket submitted successfully!');
        context.pop();
      }
    } catch (e) {
      if (mounted) CustomToast.showError(context, 'Failed to submit ticket');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark
            ? AppColors.darkBackground
            : AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? AppColors.white : AppColors.black,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Support',
          style: TextStyle(
            color: isDark ? AppColors.white : AppColors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'How can we help?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? Colors.grey.shade800
                        : const Color(0xFFE5E7EB),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    hint: const Text('Select a category'),
                    value: _selectedCategory.isEmpty ? null : _selectedCategory,
                    items: _categories
                        .map(
                          (cat) => DropdownMenuItem(
                            value: cat['value'],
                            child: Text(cat['label']!),
                          ),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _selectedCategory = val ?? ''),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildInput(
                controller: _subjectController,
                hintText: 'Subject',
                icon: Icons.subject,
              ),
              const SizedBox(height: 20),
              Container(
                height: 150,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? Colors.grey.shade800
                        : const Color(0xFFE5E7EB),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(scrollPadding: const EdgeInsets.only(bottom: 10), 
                  controller: _descriptionController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Describe your issue...',
                    hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              CustomButton(
                title: _isLoading ? 'Submitting...' : 'Submit Ticket',
                onPress: _isLoading ? () {} : _handleSubmit,
                variant: ButtonVariant.primary,
                height: 48,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : const Color(0xFFE5E7EB),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF9CA3AF), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(scrollPadding: const EdgeInsets.only(bottom: 10), 
              controller: controller,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.white : AppColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
