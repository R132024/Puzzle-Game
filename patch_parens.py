import os

files = [
    'lib/classic/ui/classic_screen.dart',
    'lib/arena/ui/arena_screen.dart',
    'lib/power/ui/power_screen.dart',
    'lib/multiplayer/ui/multiplayer_screen.dart'
]

for filepath in files:
    with open(filepath, 'r') as f:
        content = f.read()

    # Find the end of the Stack inside LayoutBuilder
    # It ends with:
    #       ],
    #     );
    #   },
    # );
    
    content = content.replace("      ],\n    );\n  },\n);", "      ],\n    ),\n    );\n  },\n);")
    
    with open(filepath, 'w') as f:
        f.write(content)

print("Parens fixed!")
