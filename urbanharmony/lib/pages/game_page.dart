import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/particles.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flame_network_assets/flame_network_assets.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:screenshot/screenshot.dart';
import 'package:urbanharmony/helper/utils.dart';
import 'package:urbanharmony/models/list_products.dart';
import 'package:urbanharmony/pages/home_page.dart';

Size screenSize = const Size(0, 0);

// First get the FlutterView.
FlutterView view = WidgetsBinding.instance.platformDispatcher.views.first;

// Dimensions in logical pixels (dp)
Size size = view.physicalSize / view.devicePixelRatio;
double width = size.width;
double height = size.height + 10;
String bgImg = '';

class MyGame extends FlameGame with HasGameRef {
  SpriteComponent background = SpriteComponent();

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final String imageUrl = bgImg;
    final spritebg = await FlameNetworkImages().load(imageUrl);

    background
      ..sprite = Sprite(spritebg)
      ..size = Vector2(width, height)
      ..anchor = Anchor.center
      ..position = Vector2(width / 2, height / 2);
    print(screenSize);
    add(background);
    final characters = <Character>[];

    for (int i = 0; i < design.length; i++) {
      final sprite = await FlameNetworkImages().load(design[i]['imageUrl']);
      characters.add(Character()..sprite = Sprite(sprite)
        ..size = Vector2.all(design[i]['size'].toDouble()));
    }
    // Add characters to the game world
    for (final character in characters) {
      add(character);
    }
  }
}

class Character extends SpriteComponent with DragCallbacks {
  Vector2? dragDeltaPosition;

  Character() : super(position: Vector2.zero(), size: Vector2.all(150));

  @override
  void update(double dt) {
    super.update(dt);
    debugColor = isDragged ? Colors.greenAccent : Colors.purple;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    position += event.localDelta;
    priority = 10;
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    print(position);
    priority = 0;
  }

}

class GamePage extends StatefulWidget {
  final FlameGame game;
  final String selectedImageUrl;
  const GamePage(
      {super.key, required this.game, required this.selectedImageUrl});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  final GlobalKey _globalKey = GlobalKey();

  //Create an instance of ScreenshotController
  ScreenshotController screenshotController = ScreenshotController();

  Future<dynamic> ShowCapturedWidget(
      BuildContext context, Uint8List capturedImage) {
    return showDialog(
      useSafeArea: false,
      context: context,
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: const Text('Here the result'),
          leading: IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HomePage(),
                ),
              );
            },
          ),
        ),
        body: RepaintBoundary(
          key: _globalKey,
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Center(
              child: Image.memory(
                capturedImage,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {},
          tooltip: 'Post',
          child: const Icon(Icons.next_plan_sharp),
        ),
      ),
    );
  }

  _saveLocalImage() async {
    RenderRepaintBoundary boundary =
        _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    ui.Image image = await boundary.toImage();
    ByteData? byteData =
        await (image.toByteData(format: ui.ImageByteFormat.png));
    if (byteData != null) {
      final result =
          await ImageGallerySaver.saveImage(byteData.buffer.asUint8List());
      print(result);
    }
    Utils.toast("Image Saved to Gallery");
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    PermissionUtil.requestAll();
    bgImg = widget.selectedImageUrl;
  }

  @override
  void dispose() {
    super.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    screenSize = MediaQuery.of(context).size;
    return Scaffold(
        body: Screenshot(
          controller: screenshotController,
          child: RepaintBoundary(
              key: _globalKey,
              child: Expanded(child: GameWrapper(game: widget.game))),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              FloatingActionButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                tooltip: 'Back',
                child: const Icon(Icons.navigate_before),
              ),
              FloatingActionButton(
                onPressed: _saveLocalImage,
                tooltip: 'Download',
                child: const Icon(Icons.download),
              ),
              // FloatingActionButton(
              //   onPressed: () {
              //     screenshotController
              //         .capture(delay: const Duration(milliseconds: 10))
              //         .then((capturedImage) async {
              //       ShowCapturedWidget(context, capturedImage!);
              //     }).catchError((onError) {
              //       print("THERE ARE ERROR" + onError);
              //     });
              //   },
              //   tooltip: 'Share',
              //   child: const Icon(Icons.next_plan),
              // )
            ],
          ),
        ));
  }
}

class GameWrapper extends StatelessWidget {
  final FlameGame game;

  const GameWrapper({required this.game});

  @override
  Widget build(BuildContext context) {
    return GameWidget(
      game: game,
    );
  }
}
