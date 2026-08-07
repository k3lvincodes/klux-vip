import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kenick_vip/repositories/support_repository.dart';
import 'package:kenick_vip/utils/custom_toast.dart';
import 'package:kenick_vip/widgets/buttons/custom_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Support'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('How can we help?',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory.isEmpty ? null : _selectedCategory,
                hint: const Text('Select a category'),
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                items: _categories
                    .map((cat) => DropdownMenuItem(
                          value: cat['value'],
                          child: Text(cat['label']!),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => _selectedCategory = val ?? ''),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _subjectController,
                decoration: const InputDecoration(
                  hintText: 'Subject',
                  prefixIcon: Icon(Icons.subject),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Describe your issue...',
                  alignLabelWithHint: true,
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
}
