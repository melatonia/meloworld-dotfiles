import os
import re

def process_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    new_content = content

    # Replace durations
    new_content = re.sub(r'\bduration:\s*150\b', 'duration: PanelColors.animFast', new_content)
    new_content = re.sub(r'\bduration:\s*250\b', 'duration: PanelColors.animNormal', new_content)
    new_content = re.sub(r'\bduration:\s*600\b', 'duration: PanelColors.animSlow', new_content)

    # Replace opacities
    new_content = re.sub(r'\bopacity:\s*0\.3\b', 'opacity: PanelColors.opacityMuted', new_content)
    new_content = re.sub(r'\bopacity:\s*0\.6\b', 'opacity: PanelColors.opacityDim', new_content)
    new_content = re.sub(r'\bopacity:\s*0\.85\b', 'opacity: PanelColors.opacitySubtle', new_content)

    if new_content != content:
        with open(filepath, 'w') as f:
            f.write(new_content)
        print(f"Updated {filepath}")

for root, dirs, files in os.walk('/home/melatonia/Projects/rice/meloworld-dotfiles/quickshell'):
    for file in files:
        if file.endswith('.qml'):
            process_file(os.path.join(root, file))
