import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AskNotesLabController extends GetxController {
  final String? initialPersona;
  final String? initialQuestion;
  final String? initialAnswer;

  final TextEditingController questionController = TextEditingController();
  final RxString persona = ''.obs;
  final RxString answer = ''.obs;

  AskNotesLabController({
    this.initialPersona,
    this.initialQuestion,
    this.initialAnswer,
  });

  @override
  void onInit() {
    super.onInit();
    
    // Apply initial values if provided
    if (initialPersona != null && initialPersona!.isNotEmpty) {
      persona.value = initialPersona!;
    }
    
    if (initialQuestion != null && initialQuestion!.isNotEmpty) {
      questionController.text = initialQuestion!;
    }
    
    if (initialAnswer != null && initialAnswer!.isNotEmpty) {
      answer.value = initialAnswer!;
    }
  }

  @override
  void onClose() {
    questionController.dispose();
    super.onClose();
  }
}

