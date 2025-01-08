import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:diet_fairy/presentation/write/write_page.dart';
import 'package:photo_manager/photo_manager.dart';

AppBar writePageAppbar({
  required BuildContext context,
  required bool appBarFlag,
  bool multiImageFlag = false,
  AssetEntity? selectedImage,
  List<AssetEntity>? selectedImages,
}) {
  return AppBar(
    title: const Align(
      alignment: Alignment.centerLeft,
      child: Text(
        "새 게시물",
      ),
    ),
    leading: IconButton(
      onPressed: () {
        Navigator.pop(context);
      },
      icon: Icon(
        appBarFlag ? Icons.close : Icons.arrow_back,
        size: 40, // 아이콘 크기
      ),
      constraints: const BoxConstraints(
        minWidth: 50, // 가로 크기
        minHeight: 50, // 세로 크기
      ),
    ),
    actions: [
      GestureDetector(
        onTap: () {
          if ((selectedImage == null) &&
              (selectedImages == null || selectedImages.isEmpty)) {
            showCupertinoDialog(
                context: context,
                builder: (context) {
                  return CupertinoAlertDialog(
                    title: const Text('이미지를 선택해주세요'),
                    content: const Text('총 1개 이상의 이미지가 필요합니다'),
                    actions: [
                      CupertinoDialogAction(
                          isDefaultAction: true,
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('확인'))
                    ],
                  );
                });
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WritePage(
                    multiImageFlag: multiImageFlag,
                    selectedImage: selectedImage,
                    selectedImages: selectedImages),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.only(right: 20, top: 10),
          child: Text(
            "다음",
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Theme.of(context).colorScheme.primary),
          ),
        ),
      ),
    ],
  );
}
