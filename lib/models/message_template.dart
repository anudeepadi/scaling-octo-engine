enum MessagePhase { preQuit, quitDay, postQuit, general }
enum MessageTrigger { scheduled, response, missed, help, stop }
enum ContentType { text, image, gif, video, link }

class MessageTemplate {
  final String id;
  final String templateKey;
  final MessagePhase phase;
  final MessageTrigger trigger;
  final int dayOffset; // Days relative to quit date
  final String timeSlot; // 'morning', 'afternoon', 'evening'
  final Map<String, String> content; // Language code -> content
  final Map<String, String>? mediaUrls; // Language code -> media URL
  final ContentType contentType;
  final List<Map<String, String>>? quickReplies; // [{'en': 'Yes', 'es': 'Sí', 'value': 'yes'}]
  final String? nextTemplateId; // For branching logic
  final Map<String, String>? branchingLogic; // Response value -> next template ID
  final bool isActive;
  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MessageTemplate({
    required this.id,
    required this.templateKey,
    required this.phase,
    required this.trigger,
    required this.dayOffset,
    required this.timeSlot,
    required this.content,
    this.mediaUrls,
    this.contentType = ContentType.text,
    this.quickReplies,
    this.nextTemplateId,
    this.branchingLogic,
    this.isActive = true,
    this.version = 1,
    required this.createdAt,
    required this.updatedAt,
  });

  MessageTemplate copyWith({
    String? id,
    String? templateKey,
    MessagePhase? phase,
    MessageTrigger? trigger,
    int? dayOffset,
    String? timeSlot,
    Map<String, String>? content,
    Map<String, String>? mediaUrls,
    ContentType? contentType,
    List<Map<String, String>>? quickReplies,
    String? nextTemplateId,
    Map<String, String>? branchingLogic,
    bool? isActive,
    int? version,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MessageTemplate(
      id: id ?? this.id,
      templateKey: templateKey ?? this.templateKey,
      phase: phase ?? this.phase,
      trigger: trigger ?? this.trigger,
      dayOffset: dayOffset ?? this.dayOffset,
      timeSlot: timeSlot ?? this.timeSlot,
      content: content ?? this.content,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      contentType: contentType ?? this.contentType,
      quickReplies: quickReplies ?? this.quickReplies,
      nextTemplateId: nextTemplateId ?? this.nextTemplateId,
      branchingLogic: branchingLogic ?? this.branchingLogic,
      isActive: isActive ?? this.isActive,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'templateKey': templateKey,
      'phase': phase.name,
      'trigger': trigger.name,
      'dayOffset': dayOffset,
      'timeSlot': timeSlot,
      'content': content,
      'mediaUrls': mediaUrls,
      'contentType': contentType.name,
      'quickReplies': quickReplies,
      'nextTemplateId': nextTemplateId,
      'branchingLogic': branchingLogic,
      'isActive': isActive,
      'version': version,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory MessageTemplate.fromJson(Map<String, dynamic> json) {
    return MessageTemplate(
      id: json['id'] as String,
      templateKey: json['templateKey'] as String,
      phase: MessagePhase.values.firstWhere((e) => e.name == json['phase']),
      trigger: MessageTrigger.values.firstWhere((e) => e.name == json['trigger']),
      dayOffset: json['dayOffset'] as int,
      timeSlot: json['timeSlot'] as String,
      content: Map<String, String>.from(json['content']),
      mediaUrls: json['mediaUrls'] != null ? Map<String, String>.from(json['mediaUrls']) : null,
      contentType: ContentType.values.firstWhere((e) => e.name == json['contentType']),
      quickReplies: json['quickReplies'] != null 
          ? List<Map<String, String>>.from(
              (json['quickReplies'] as List).map((item) => Map<String, String>.from(item))
            )
          : null,
      nextTemplateId: json['nextTemplateId'] as String?,
      branchingLogic: json['branchingLogic'] != null 
          ? Map<String, String>.from(json['branchingLogic']) 
          : null,
      isActive: json['isActive'] as bool? ?? true,
      version: json['version'] as int? ?? 1,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  String getLocalizedContent(String languageCode) {
    return content[languageCode] ?? content['en'] ?? '';
  }

  String? getLocalizedMediaUrl(String languageCode) {
    if (mediaUrls == null) return null;
    return mediaUrls![languageCode] ?? mediaUrls!['en'];
  }

  List<Map<String, String>>? getLocalizedQuickReplies(String languageCode) {
    if (quickReplies == null) return null;
    
    return quickReplies!.map((reply) {
      return {
        'text': reply[languageCode] ?? reply['en'] ?? '',
        'value': reply['value'] ?? '',
      };
    }).toList();
  }
}

class ScheduledMessage {
  final String id;
  final String userId;
  final String templateId;
  final DateTime scheduledTime;
  final bool isSent;
  final DateTime? sentAt;
  final bool isRead;
  final DateTime? readAt;
  final String? userResponse;
  final DateTime? respondedAt;
  final int retryCount;
  final DateTime? nextRetryAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ScheduledMessage({
    required this.id,
    required this.userId,
    required this.templateId,
    required this.scheduledTime,
    this.isSent = false,
    this.sentAt,
    this.isRead = false,
    this.readAt,
    this.userResponse,
    this.respondedAt,
    this.retryCount = 0,
    this.nextRetryAt,
    required this.createdAt,
    required this.updatedAt,
  });

  ScheduledMessage copyWith({
    String? id,
    String? userId,
    String? templateId,
    DateTime? scheduledTime,
    bool? isSent,
    DateTime? sentAt,
    bool? isRead,
    DateTime? readAt,
    String? userResponse,
    DateTime? respondedAt,
    int? retryCount,
    DateTime? nextRetryAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ScheduledMessage(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      templateId: templateId ?? this.templateId,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      isSent: isSent ?? this.isSent,
      sentAt: sentAt ?? this.sentAt,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      userResponse: userResponse ?? this.userResponse,
      respondedAt: respondedAt ?? this.respondedAt,
      retryCount: retryCount ?? this.retryCount,
      nextRetryAt: nextRetryAt ?? this.nextRetryAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'templateId': templateId,
      'scheduledTime': scheduledTime.toIso8601String(),
      'isSent': isSent,
      'sentAt': sentAt?.toIso8601String(),
      'isRead': isRead,
      'readAt': readAt?.toIso8601String(),
      'userResponse': userResponse,
      'respondedAt': respondedAt?.toIso8601String(),
      'retryCount': retryCount,
      'nextRetryAt': nextRetryAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ScheduledMessage.fromJson(Map<String, dynamic> json) {
    return ScheduledMessage(
      id: json['id'] as String,
      userId: json['userId'] as String,
      templateId: json['templateId'] as String,
      scheduledTime: DateTime.parse(json['scheduledTime']),
      isSent: json['isSent'] as bool? ?? false,
      sentAt: json['sentAt'] != null ? DateTime.parse(json['sentAt']) : null,
      isRead: json['isRead'] as bool? ?? false,
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
      userResponse: json['userResponse'] as String?,
      respondedAt: json['respondedAt'] != null ? DateTime.parse(json['respondedAt']) : null,
      retryCount: json['retryCount'] as int? ?? 0,
      nextRetryAt: json['nextRetryAt'] != null ? DateTime.parse(json['nextRetryAt']) : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  bool get isPending => !isSent && DateTime.now().isBefore(scheduledTime);
  bool get isOverdue => !isSent && DateTime.now().isAfter(scheduledTime);
  bool get needsRetry => isOverdue && retryCount < 3 && (nextRetryAt == null || DateTime.now().isAfter(nextRetryAt!));
} 