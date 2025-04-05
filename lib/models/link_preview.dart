class LinkPreview {
  final String url;
  final String title;
  final String description;
  final String? imageUrl;
  final String? siteName;

  LinkPreview({
    required this.url,
    required this.title,
    required this.description,
    this.imageUrl,
    this.siteName,
  });

  factory LinkPreview.fromJson(Map<String, dynamic> json) {
    return LinkPreview(
      url: json['url'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String?,
      siteName: json['siteName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'siteName': siteName,
    };
  }

  LinkPreview copyWith({
    String? url,
    String? title,
    String? description,
    String? imageUrl,
    String? siteName,
  }) {
    return LinkPreview(
      url: url ?? this.url,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      siteName: siteName ?? this.siteName,
    );
  }
} 