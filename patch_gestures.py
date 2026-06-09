import re
import os

files = [
    'lib/classic/ui/classic_screen.dart',
    'lib/arena/ui/arena_screen.dart',
    'lib/power/ui/power_screen.dart',
    'lib/multiplayer/ui/multiplayer_screen.dart'
]

gesture_regex = re.compile(r'GestureDetector\s*\(\s*onPanStart:\s*\(details\)\s*\{.*?onTap:\s*\(\)\s*=>\s*_engine\.rotateClockwise\(\),\s*child:\s*(Transform\.translate\()', re.DOTALL)

for filepath in files:
    with open(filepath, 'r') as f:
        content = f.read()

    # 1. Add import
    if 'game_gesture_detector.dart' not in content:
        content = content.replace("import 'package:cubix_blast/ui/widgets/audio_visualizer_bg.dart';", "import 'package:cubix_blast/ui/widgets/game_gesture_detector.dart';\nimport 'package:cubix_blast/ui/widgets/audio_visualizer_bg.dart';")

    # 2. Remove pan variables
    content = re.sub(r'  double _panStartX = 0;\n  double _panStartY = 0;\n  double _accumulatedPanX = 0;\n  bool _panVerticalTriggered = false;\n\n', '', content)

    # 3. Wrap Stack with GameGestureDetector
    if 'return GameGestureDetector(' not in content:
        content = content.replace('        return Stack(', '''        return GameGestureDetector(
          onMoveLeft: _engine.moveLeft,
          onMoveRight: _engine.moveRight,
          onHardDrop: _engine.hardDrop,
          onHoldPiece: _engine.holdPiece,
          onRotateClockwise: _engine.rotateClockwise,
          child: Stack(''')

    # 4. Remove old GestureDetector
    content = gesture_regex.sub(r'\1', content)

    with open(filepath, 'w') as f:
        f.write(content)

print("Patch applied to all 4 files.")
