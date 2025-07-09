import 'package:flutter/cupertino.dart';

class IosMessageInput extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onSubmitted;
  final Function() onPickMedia;
  final Function() onPickGif;
  final bool isComposing;

  const IosMessageInput({
    super.key,
    required this.controller,
    required this.onSubmitted,
    required this.onPickMedia,
    required this.onPickGif,
    required this.isComposing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        border: Border(
          top: BorderSide(
            color: CupertinoColors.systemGrey4,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min, // Make the row take minimum space
        children: [
          // Wrap buttons in a row to control their overall size
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                minSize: 30,
                onPressed: onPickMedia,
                child: const Icon(
                  CupertinoIcons.photo_on_rectangle,
                  color: CupertinoColors.activeBlue,
                  size: 20,
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minSize: 30,
                onPressed: onPickGif,
                child: const Text(
                  'GIF',
                  style: TextStyle(
                    color: CupertinoColors.activeBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: CupertinoTextField(
              controller: controller,
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              placeholder: 'Message',
              placeholderStyle: const TextStyle(
                color: CupertinoColors.placeholderText,
              ),
              textCapitalization: TextCapitalization.sentences,
              keyboardType: TextInputType.multiline,
              maxLines: null,
              onSubmitted: onSubmitted,
            ),
          ),
          const SizedBox(width: 5),
          CupertinoButton(
            padding: EdgeInsets.zero,
            minSize: 30,
            onPressed: isComposing
                ? () => onSubmitted(controller.text)
                : null,
            child: Icon(
              CupertinoIcons.arrow_up_circle_fill,
              color: isComposing
                  ? CupertinoColors.activeBlue
                  : CupertinoColors.systemGrey,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}
