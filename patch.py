import os
import re

files = [
    'lib/classic/ui/classic_screen.dart',
    'lib/arena/ui/arena_screen.dart',
    'lib/power/ui/power_screen.dart',
    'lib/multiplayer/ui/multiplayer_screen.dart'
]

for filepath in files:
    with open(filepath, 'r') as f:
        content = f.read()
    
    # 1. Replace the inner GestureDetector logic with nothing
    pattern_gesture = r'                  GestureDetector\(\s*onPanStart.*?child: Transform\.translate\('
    content = re.sub(pattern_gesture, '                  Transform.translate(', content, flags=re.DOTALL)
    
    # Now we need to remove the extra closing `),`
    content = re.sub(r'                        child: GameBoard\(\n                          engine: _engine,\n                        \),\n                      \),\n                    \),\n                  \),\n                  \),', 
                     r'                        child: GameBoard(\n                          engine: _engine,\n                        ),\n                      ),\n                    ),\n                  ),', content)

    # Remove pan variables
    content = re.sub(r'  double _panStartX = 0;\n  double _panStartY = 0;\n  double _accumulatedPanX = 0;\n  bool _panVerticalTriggered = false;\n\n', '', content)

    # 2. Add import
    if 'game_gesture_detector.dart' not in content:
        content = content.replace("import 'package:cubix_blast/ui/widgets/audio_visualizer_bg.dart';", "import 'package:cubix_blast/ui/widgets/game_gesture_detector.dart';\nimport 'package:cubix_blast/ui/widgets/audio_visualizer_bg.dart';")
        
    # 3. Wrap KeyboardListener with GameGestureDetector
    wrapper = '''GameGestureDetector(
        onMoveLeft: _engine.moveLeft,
        onMoveRight: _engine.moveRight,
        onHardDrop: _engine.hardDrop,
        onHoldPiece: _engine.holdPiece,
        onRotateClockwise: _engine.rotateClockwise,
        child: KeyboardListener('''
    content = content.replace('body: KeyboardListener(', f'body: {wrapper}')
    
    # 4. Add the closing parenthesis for GameGestureDetector at the very end of the Scaffold body.
    content = content.replace('      ),\n    );\n  }\n', '      ),\n      ),\n    );\n  }\n')

    with open(filepath, 'w') as f:
        f.write(content)

print("Done")
