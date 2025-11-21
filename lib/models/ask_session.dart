class AskSession {
  final String id;
  final String userId;
  final DateTime createdAt;
  final String lastQuestion;
  final String persona;
  final String lastAnswer;

  const AskSession({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.lastQuestion,
    required this.persona,
    required this.lastAnswer,
  });

  factory AskSession.fromMap(Map<String, dynamic> map) {
    return AskSession(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      lastQuestion: map['last_question'] as String? ?? '',
      persona: map['persona'] as String? ?? '',
      lastAnswer: map['last_answer'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
      'last_question': lastQuestion,
      'persona': persona,
      'last_answer': lastAnswer,
    };
  }
}

