import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kenick_vip/models/support_ticket.dart';
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
  bool _showForm = false;
  final SupportRepository _supportRepo = SupportRepository();
  List<SupportTicket> _tickets = [];
  bool _loadingTickets = true;

  final List<Map<String, String>> _categories = [
    {'value': 'ride_issue', 'label': 'Ride Issue'},
    {'value': 'payment_issue', 'label': 'Payment Issue'},
    {'value': 'safety_concern', 'label': 'Safety Concern'},
    {'value': 'account_issue', 'label': 'Account Issue'},
    {'value': 'other', 'label': 'Other'},
  ];

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadTickets() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final tickets = await _supportRepo.getUserTickets(user.id);
        if (mounted) {
          setState(() {
            _tickets = tickets;
            _loadingTickets = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _loadingTickets = false);
    }
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
        _subjectController.clear();
        _descriptionController.clear();
        setState(() {
          _selectedCategory = '';
          _showForm = false;
        });
        _loadTickets();
      }
    } catch (e) {
      if (mounted) CustomToast.showError(context, 'Failed to submit ticket');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'open': return 'Open';
      case 'in_progress': return 'In Progress';
      case 'resolved': return 'Resolved';
      case 'closed': return 'Closed';
      default: return status;
    }
  }

  Color _statusColor(String status, bool isDark) {
    switch (status) {
      case 'open': return isDark ? const Color(0xFFEF4444) : Colors.red;
      case 'in_progress': return isDark ? const Color(0xFFEAB308) : Colors.orange;
      case 'resolved': return isDark ? const Color(0xFF22C55E) : Colors.green;
      case 'closed': return isDark ? const Color(0xFF71717A) : Colors.grey;
      default: return isDark ? const Color(0xFFA1A1AA) : Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Support'),
        actions: [
          IconButton(
            icon: Icon(_showForm ? Icons.list : Icons.add),
            onPressed: () => setState(() => _showForm = !_showForm),
          ),
        ],
      ),
      body: _showForm ? _buildForm(isDark) : _buildTicketList(isDark),
    );
  }

  Widget _buildTicketList(bool isDark) {
    if (_loadingTickets) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_tickets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.support_agent, size: 48, color: isDark ? Colors.grey.shade600 : Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('No tickets yet', style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 16)),
            const SizedBox(height: 8),
            Text('Tap + to create a support ticket', style: TextStyle(color: isDark ? Colors.grey.shade600 : Colors.grey.shade400, fontSize: 13)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTickets,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _tickets.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final ticket = _tickets[index];
          return Card(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              title: Text(
                ticket.subject,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _statusColor(ticket.status, isDark).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _statusLabel(ticket.status),
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _statusColor(ticket.status, isDark)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(ticket.createdAt),
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade500 : Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              trailing: Icon(Icons.chevron_right, color: isDark ? Colors.grey.shade500 : Colors.grey.shade400),
              onTap: () {
                context.push(
                  '/support/ticket/${ticket.id}',
                  extra: {'subject': ticket.subject, 'status': ticket.status},
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.month}/${date.day}/${date.year}';
  }

  Widget _buildForm(bool isDark) {
    return SingleChildScrollView(
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
    );
  }
}
