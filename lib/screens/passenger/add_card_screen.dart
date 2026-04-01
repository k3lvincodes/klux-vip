import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:klux_vip/theme/app_colors.dart';
import 'package:klux_vip/widgets/custom_button.dart';

class AddCardScreen extends StatefulWidget {
  const AddCardScreen({super.key});

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  bool _saveCard = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF0B3), Color(0xFFF3EDEC)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.only(left: 16.0, top: 16.0, right: 16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: AppColors.black),
                      onPressed: () => context.pop(),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Add new card',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.black,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // Padding to center the title
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Big Card Display
              Center(
                child: Container(
                  width: 320,
                  height: 200,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E), // Dark gray/black
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Icon(Icons.memory, color: Colors.white, size: 36),
                          Icon(Icons.credit_card, color: Colors.white, size: 36), // mc placeholder
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        '**** **** **** 1289',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          letterSpacing: 2,
                        ),
                      ),
                      const Expanded(child: SizedBox()),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text(
                            'David Joe',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '09/25',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // Inputs
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  children: [
                    _buildInputLabel('Card number'),
                    const SizedBox(height: 8),
                    _buildInputField('.... .... .... 5252', suffixIcon: Icons.document_scanner_outlined),
                    const SizedBox(height: 16),
                    
                    _buildInputLabel('Cardholder name'),
                    const SizedBox(height: 8),
                    _buildInputField('DAVID JOE'),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInputLabel('Expiry date'),
                              const SizedBox(height: 8),
                              _buildInputField('08 / 27'),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInputLabel('CVV'),
                              const SizedBox(height: 8),
                              _buildInputField('562', suffixIcon: Icons.info_outline),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),
                    
                    // Save card checkbox
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _saveCard = !_saveCard;
                            });
                          },
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: _saveCard ? AppColors.black : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.black),
                            ),
                            child: _saveCard
                                ? const Icon(Icons.check, color: AppColors.white, size: 14)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Save card information.',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    CustomButton(
                      title: 'Add card',
                      onPress: () {},
                      variant: ButtonVariant.primary,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildInputField(String hint, {IconData? suffixIcon}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: AppColors.black,
            fontWeight: FontWeight.w500,
            letterSpacing: 1,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          suffixIcon: suffixIcon != null ? Icon(suffixIcon, color: AppColors.black) : null,
        ),
      ),
    );
  }
}
