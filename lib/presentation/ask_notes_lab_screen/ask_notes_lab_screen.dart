import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'ask_notes_lab_controller.dart';
import '../../ui/visuals/brand_background.dart';
import '../../ui/app_spacing.dart';
import '../../ui/widgets/svn_scaffold_body.dart';
import '../../theme/app_text_styles.dart';

class AskNotesLabScreen extends StatelessWidget {
  const AskNotesLabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Read route arguments
    final args = Get.arguments;
    String? initialPersona;
    String? initialQuestion;
    String? initialAnswer;

    if (args is Map) {
      initialPersona = args['persona'] as String?;
      initialQuestion = args['question'] as String?;
      initialAnswer = args['answer'] as String?;
    }

    // Initialize controller with route arguments if provided
    if (!Get.isRegistered<AskNotesLabController>()) {
      Get.put(AskNotesLabController(
        initialPersona: initialPersona,
        initialQuestion: initialQuestion,
        initialAnswer: initialAnswer,
      ));
    } else {
      // If controller already exists, update it with new values
      final existingController = Get.find<AskNotesLabController>();
      if (initialQuestion != null && initialQuestion.isNotEmpty) {
        existingController.questionController.text = initialQuestion;
      }
      if (initialPersona != null && initialPersona.isNotEmpty) {
        existingController.persona.value = initialPersona;
      }
      if (initialAnswer != null && initialAnswer.isNotEmpty) {
        existingController.answer.value = initialAnswer;
      }
    }

    final controller = Get.find<AskNotesLabController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ask Your Notes (LAB)'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          const BrandGradientBackground(),
          SafeArea(
            child: SVNScaffoldBody(
              banner: null,
              onRefresh: () async {},
              child: Padding(
                padding: AppSpacing.screenPadding(context),
                child: Obx(() => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Persona display/selector
                    if (controller.persona.value.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Persona: ${controller.persona.value}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),

                    // Question input
                    TextField(
                      controller: controller.questionController,
                      decoration: InputDecoration(
                        labelText: 'Ask a question about your notes',
                        hintText: 'Enter your question here...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      maxLines: 3,
                    ),

                    const SizedBox(height: 16),

                    // Answer display
                    if (controller.answer.value.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Answer:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              controller.answer.value,
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Submit button (placeholder - backend logic not implemented)
                    FilledButton(
                      onPressed: () {
                        // TODO: Implement ask functionality
                        Get.snackbar(
                          'LAB Feature',
                          'Ask functionality coming soon',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      },
                      child: const Text('Ask'),
                    ),
                  ],
                )),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

