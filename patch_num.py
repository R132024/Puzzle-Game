import os

files = [
    'lib/classic/ui/classic_screen.dart',
    'lib/arena/ui/arena_screen.dart',
    'lib/power/ui/power_screen.dart',
    'lib/multiplayer/ui/multiplayer_screen.dart'
]

for fpath in files:
    with open(fpath, 'r') as f:
        content = f.read()
    
    old_str = "final canvasW = (maxH * 0.5).clamp(0.0, min(maxW * 0.5, maxAllowedW));"
    new_str = "final double canvasW = (maxH * 0.5).clamp(0.0, min<double>(maxW * 0.5, maxAllowedW.toDouble())).toDouble();"
    
    content = content.replace(old_str, new_str)
    
    with open(fpath, 'w') as f:
        f.write(content)

print("canvasW cast to double patched")
