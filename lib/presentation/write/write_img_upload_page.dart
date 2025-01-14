import 'dart:io';
import 'dart:typed_data';
import 'package:diet_fairy/presentation/write/common_widgets/img_container.dart';
import 'package:diet_fairy/presentation/write/common_widgets/write_page_appbar.dart';
import 'package:diet_fairy/presentation/write/write_img_upload_widgets/header.dart';
import 'package:diet_fairy/presentation/write/yolo/yolo_detection.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:yolo_helper/yolo_helper.dart';
import 'package:image/image.dart' as img;

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  List<AssetEntity> images = [];
  List<AssetEntity> selectedImages = [];
  AssetEntity? selectedImage;
  bool multiImageFlag = false;
  bool isPerson = false;

  // yolo
  final YoloDetection model = YoloDetection();
  final ImagePicker picker = ImagePicker();
  List<DetectedObject>? detectedObjects;
  Uint8List? imageBytes;
  int? imageWidth;
  int? imageHeight;

  @override
  void initState() {
    super.initState();
    model.initialize();
    checkPermission();
  }

  // 권한 요청 후 갤러리 접근
  void checkPermission() async {
    final permission = await PhotoManager.requestPermissionExtend();
    if (permission.isAuth) {
      // 권한이 승인되면 갤러리의 이미지를 가져옵니다.
      fetchGalleryImages();
    } else {
      PhotoManager.openSetting(); // 권한 설정 열기
    }
  }

  // 갤러리 이미지 리스트 가져오기
  void fetchGalleryImages() async {
    // 첫 번째 앨범을 가져오기
    final list = await PhotoManager.getAssetPathList(type: RequestType.image);

    // 첫 번째 앨범에서 첫 페이지 100개의 이미지를 가져옴
    final assets =
        await list[0].getAssetListPaged(page: 0, size: 100); // 페이지 번호와 크기 명시
    setState(() {
      images = assets;
    });
  }

  // 단일 이미지 선택
  void selectImage(AssetEntity asset) async {
    final file = await asset.file;
    if (file != null) {
      setState(() {
        selectedImage = asset;
      });
      checkPersonImage(file);
    }
  }

  // 이미지에 사람이 포함되는지 확인하는 메서드
  void checkPersonImage(selectedImage) async {
    bool foundPerson = false;

    if (selectedImage != null) {
      final bytes = await selectedImage.readAsBytes();
      final image = img.decodeImage(bytes)!;
      imageWidth = image.width;
      imageHeight = image.height;

      setState(() {
        imageBytes = bytes;
      });

      detectedObjects = model.runInference(image);
    }

    if (detectedObjects != null) {
      for (var object in detectedObjects!) {
        final label = model.label(object.labelIndex);

        if (label.contains('person')) {
          foundPerson = true;
          break;
        }
      }
      setState(() {
        isPerson = foundPerson;
      });
    }
  }

  //  다중 이미지 선택
  void selectImages(AssetEntity asset) async {
    final file = await asset.file;
    if (file != null) {
      setState(() {
        selectedImages.add(asset); // 이미지를 선택 목록에 추가
      });
    }
  }

  //  다중 이미지 선택 플래그 전환
  void changeMultiImageFlag() async {
    setState(() {
      multiImageFlag = !multiImageFlag;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 화면의 전체 높이 가져오기
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: writePageAppbar(
          context: context,
          appBarFlag: true,
          isPerson: isPerson,
          multiImageFlag: multiImageFlag,
          selectedImage: selectedImage,
          selectedImages: selectedImages),
      body: Column(
        children: [
          // 이미지 미리보기
          Container(
            decoration: const BoxDecoration(color: Colors.white),
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: imgContainer(
                images: images,
                multiImageFlag: multiImageFlag,
                selectedImage: selectedImage,
                selectedImages: selectedImages,
                screenHeight: screenHeight,
              ),
            ),
          ),
          header(
              changeMultiImageFlag: changeMultiImageFlag,
              multiImageFlag: multiImageFlag),
          // 이미지 리스트
          Expanded(
              child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1,
            ),
            itemCount: images.length,
            itemBuilder: (context, index) {
              final asset = images[index];
              return GestureDetector(
                onTap: () async {
                  if (!model.isInitialized) {
                    return;
                  }

                  // 다중 선택 시, 동일한 이미지 선택하는 경우 체크 표시 제거
                  if (multiImageFlag) {
                    selectedImages.contains(asset)
                        ? selectedImages.remove(asset)
                        : selectImages(asset);
                  }

                  selectImage(asset);
                },
                child: FutureBuilder<File?>(
                  future: asset.file, // 파일을 가져옴
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Lottie.asset('assets/loading2.json');
                    }
                    if (snapshot.hasData && snapshot.data != null) {
                      final bool isSelected;

                      // 선택한 이미지인지 여부 확인
                      if (multiImageFlag) {
                        isSelected = selectedImages.isNotEmpty &&
                            selectedImages.contains(asset);
                      } else {
                        isSelected = selectedImage != null &&
                            selectedImage?.id == asset.id;
                      }

                      return isSelected
                          ? Stack(
                              children: [
                                AspectRatio(
                                  aspectRatio: 1,
                                  child: Image.file(
                                    snapshot.data!,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: Container(
                                    decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(100),
                                        color: Theme.of(context).primaryColor),
                                    width: 20,
                                    height: 20,
                                    child: const Center(
                                      child: Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Image.file(
                              snapshot.data!,
                              fit: BoxFit.cover,
                            );
                    }
                    // FutureBuilder에서 파일이 없거나 snapshot.data가 null일 때 아무런 UI를 표시하지 않도록 설정
                    return const SizedBox.shrink();
                  },
                ),
              );
            },
          )),
        ],
      ),
    );
  }
}
