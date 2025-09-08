import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../theme/app_theme.dart';

class ModernMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onTap;
  final Function(String)? onReactionAdd;

  const ModernMessageBubble({
    super.key,
    required this.message,
    this.onTap,
    this.onReactionAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: message.isMe ? 60 : 0,
        right: message.isMe ? 0 : 60,
        bottom: 8,
      ),
      child: Row(
        mainAxisAlignment:
            message.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isMe) _buildAvatar(),
          if (!message.isMe) const SizedBox(width: 8),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              child: Column(
                crossAxisAlignment: message.isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  _buildMessageBubble(context),
                  const SizedBox(height: 2),
                  _buildMessageInfo(),
                ],
              ),
            ),
          ),
          if (message.isMe) const SizedBox(width: 8),
          if (message.isMe) _buildAvatar(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: message.isMe
            ? LinearGradient(
                colors: [AppTheme.quitxtTeal, AppTheme.quitxtPurple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [Colors.grey[400]!, Colors.grey[500]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: message.isMe
          ? const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 16,
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/logos/avatar high rez.jpg',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
              ),
            ),
    );
  }

  Widget _buildMessageBubble(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: message.isMe
              ? LinearGradient(
                  colors: [AppTheme.quitxtTeal, AppTheme.quitxtPurple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: message.isMe ? null : Colors.grey[100],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(message.isMe ? 20 : 4),
            bottomRight: Radius.circular(message.isMe ? 4 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: message.isMe
                  ? AppTheme.quitxtTeal.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMessageContent(),
            if (message.linkPreview != null) ...[
              const SizedBox(height: 8),
              _buildLinkPreview(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent() {
    return Text(
      message.content,
      style: TextStyle(
        color: message.isMe ? Colors.white : Colors.black87,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.4,
      ),
    );
  }

  Widget _buildLinkPreview(BuildContext context) {
    final linkPreview = message.linkPreview!;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: message.isMe
            ? Colors.white.withValues(alpha: 0.15)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: message.isMe
              ? Colors.white.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail image
          if (linkPreview.imageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: Image.network(
                linkPreview.imageUrl!,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 120,
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            message.isMe ? Colors.white : AppTheme.quitxtTeal,
                          ),
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 120,
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: Icon(
                      Icons.image_not_supported,
                      size: 32,
                      color: Colors.grey[400],
                    ),
                  );
                },
              ),
            ),
          // Content section
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title with improved wrapping
                SizedBox(
                  width: double.infinity,
                  child: Text(
                    linkPreview.title,
                    style: TextStyle(
                      color: message.isMe ? Colors.white : AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.start,
                  ),
                ),
                if (linkPreview.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      linkPreview.description,
                      style: TextStyle(
                        color: message.isMe
                            ? Colors.white.withValues(alpha: 0.9)
                            : AppTheme.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.start,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                // URL with icon - improved layout
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 1),
                        child: Icon(
                          Icons.link_rounded,
                          size: 14,
                          color: message.isMe
                              ? Colors.white.withValues(alpha: 0.8)
                              : AppTheme.textTertiary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Site name (if available)
                            if (linkPreview.siteName != null && linkPreview.siteName!.isNotEmpty)
                              Text(
                                linkPreview.siteName!,
                                style: TextStyle(
                                  color: message.isMe
                                      ? Colors.white.withValues(alpha: 0.8)
                                      : AppTheme.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            // URL hostname with better wrapping
                            Text(
                              Uri.parse(linkPreview.url).host,
                              style: TextStyle(
                                color: message.isMe
                                    ? Colors.white.withValues(alpha: 0.7)
                                    : AppTheme.textTertiary,
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              softWrap: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatTime(message.timestamp),
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
          ),
          if (message.isMe) ...[
            const SizedBox(width: 4),
            Icon(
              _getStatusIcon(),
              size: 12,
              color: _getStatusColor(),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'now';
    }
  }

  IconData _getStatusIcon() {
    switch (message.status) {
      case MessageStatus.sending:
        return Icons.access_time;
      case MessageStatus.sent:
        return Icons.check;
      case MessageStatus.delivered:
        return Icons.done_all;
      case MessageStatus.read:
        return Icons.done_all;
      case MessageStatus.failed:
      case MessageStatus.error:
        return Icons.error_outline;
    }
  }

  Color _getStatusColor() {
    switch (message.status) {
      case MessageStatus.sending:
        return Colors.grey;
      case MessageStatus.sent:
        return Colors.grey[600]!;
      case MessageStatus.delivered:
        return AppTheme.quitxtTeal;
      case MessageStatus.read:
        return AppTheme.quitxtTeal;
      case MessageStatus.failed:
      case MessageStatus.error:
        return Colors.red;
    }
  }
}
