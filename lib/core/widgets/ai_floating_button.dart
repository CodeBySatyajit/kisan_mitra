import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/ai_assistant_controller.dart';
import '../localization/locale_provider.dart';
import '../utils/app_theme.dart';

/// Global floating AI assistant button.
/// Expands with animation, shows waveform when listening, displays transcript.
class AiFloatingButton extends StatelessWidget {
  const AiFloatingButton({super.key, this.bottom = 100, this.right = 20});

  final double bottom;
  final double right;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: bottom,
      right: right,
      child: Consumer<AiAssistantController>(
        builder: (context, controller, _) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: controller.isExpanded
                ? MediaQuery.of(context).size.width - 32
                : 60,
            height: controller.isExpanded
                ? MediaQuery.of(context).size.height * 0.5
                : 60,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(
                controller.isExpanded ? 20 : 30,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: controller.isExpanded
                ? _buildExpandedContent(context, controller)
                : _buildCollapsedButton(context, controller),
          );
        },
      ),
    );
  }

  Widget _buildCollapsedButton(
    BuildContext context,
    AiAssistantController controller,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          final localeProvider = context.read<LocaleProvider>();
          controller.toggleListening(
            languageCode: localeProvider.currentLanguageCode,
          );
        },
        borderRadius: BorderRadius.circular(30),
        child: Center(child: _buildWaveformOrIcon(controller, size: 32)),
      ),
    );
  }

  Widget _buildExpandedContent(
    BuildContext context,
    AiAssistantController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildWaveformOrIcon(controller, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    'Kisan Mitra',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: controller.collapse,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(child: _buildChatList(controller)),
          if (controller.errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              controller.errorMessage!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.error,
                fontSize: 11,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChatList(AiAssistantController controller) {
    if (controller.messages.isEmpty &&
        controller.transcript.isEmpty &&
        controller.state != AiAssistantState.processing) {
      return _buildSuggestions(controller);
    }

    return ListView.builder(
      reverse: true,
      itemCount:
          controller.messages.length +
          (controller.transcript.isNotEmpty ? 1 : 0) +
          (controller.state == AiAssistantState.processing ? 1 : 0),
      itemBuilder: (context, index) {
        int i = controller.messages.length - 1 - index;

        // Handle processing indicator at the bottom (index 0 when reversed)
        if (controller.state == AiAssistantState.processing && index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildBubble(
                child: const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                isUser: false,
              ),
            ),
          );
        }

        // Adjust index if processing indicator is present
        if (controller.state == AiAssistantState.processing) {
          i++;
        }

        // Handle current transcript at the bottom
        if (controller.transcript.isNotEmpty) {
          if (index ==
              (controller.state == AiAssistantState.processing ? 1 : 0)) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Align(
                alignment: Alignment.centerRight,
                child: _buildBubble(
                  child: Text(
                    controller.transcript,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontStyle: FontStyle.italic,
                      color: Colors.white,
                    ),
                  ),
                  isUser: true,
                ),
              ),
            );
          }
          i++;
        }

        if (i < 0 || i >= controller.messages.length)
          return const SizedBox.shrink();

        final msg = controller.messages[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Align(
            alignment: msg.isUser
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: _buildBubble(
              child: Text(
                msg.text,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: msg.isUser ? Colors.white : AppColors.textPrimary,
                ),
              ),
              isUser: msg.isUser,
            ),
          ),
        );
      },
    );
  }

  Widget _buildBubble({required Widget child, required bool isUser}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isUser ? AppColors.primary : AppColors.background,
        borderRadius: BorderRadius.circular(16).copyWith(
          bottomRight: isUser
              ? const Radius.circular(0)
              : const Radius.circular(16),
          bottomLeft: !isUser
              ? const Radius.circular(0)
              : const Radius.circular(16),
        ),
        border: isUser ? null : Border.all(color: AppColors.divider),
      ),
      child: child,
    );
  }

  Widget _buildSuggestions(AiAssistantController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Try saying:',
          style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        ...controller.suggestionPrompts
            .take(4)
            .map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• $p',
                  style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                ),
              ),
            ),
      ],
    );
  }

  Widget _buildWaveformOrIcon(
    AiAssistantController controller, {
    required double size,
  }) {
    if (controller.isListening) {
      return _WaveformIndicator(size: size, color: AppColors.primary);
    }
    return Icon(Icons.mic, size: size, color: AppColors.primary);
  }
}

/// Simple waveform animation for listening state.
class _WaveformIndicator extends StatefulWidget {
  const _WaveformIndicator({required this.size, this.color});

  final double size;
  final Color? color;

  @override
  State<_WaveformIndicator> createState() => _WaveformIndicatorState();
}

class _WaveformIndicatorState extends State<_WaveformIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            final delay = i * 0.15;
            final value = (_controller.value + delay) % 1.0;
            final height = 4 + 12 * (0.5 + 0.5 * math.sin(value * math.pi * 2));

            return Container(
              width: 3,
              height: height,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: widget.color ?? AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }
}
