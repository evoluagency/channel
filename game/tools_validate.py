#!/usr/bin/env python3
"""Checks a Godot prototype source tree without claiming engine/runtime validation."""
from pathlib import Path
from collections import Counter
import re, sys, zipfile
root=Path(__file__).resolve().parent
required=['project.godot','export_presets.cfg','scenes/Main.tscn','scripts/main.gd','README.md','docs/ARQUITETURA.md','docs/EXPORTAR_ANDROID.md']
for name in required:
    assert (root/name).is_file(),name
script=(root/'scripts/main.gd').read_text()
checks={
 '3D character movement':'CharacterBody3D.new()' in script and 'move_and_slide()' in script,
 'third-person camera':'Camera3D.new()' in script and 'camera.look_at(' in script,
 'touch controls':'InputEventScreenTouch' in script and 'InputEventScreenDrag' in script,
 'merchant & banker':'"merchant"' in script and '"bank"' in script,
 'local save':'user://channel_save.json' in script and 'FileAccess.open' in script,
 'Valdora spawn':'START_POS := Vector3(0, 0.2, 15)' in script,
 'castle / plaza / market':'_build_valdora()' in script and '_tower(' in script and '_stall(' in script,
 'offline compatible':'Supabase' not in script and 'MultiplayerPeer' not in script,
 'remote updates isolated':(root/'scripts/content_updater.gd').exists(),
 'no Minecraft SDK':'@minecraft' not in script,
 'font file absent':not any(root.rglob('*.ttf')) and not any(root.rglob('*.otf')),
 'no APK artifact misrepresented':not any(root.rglob('*.apk')),
}
for key, value in checks.items():
    print(('OK' if value else 'FAIL'),key)
assert all(checks.values())
# Basic balanced punctuation check outside text/comment strings. Engine parser still required.
pruned=[]
for line in script.splitlines():
    current=''; in_string=False; esc=False
    for ch in line:
        if in_string:
            if esc: esc=False
            elif ch=='\\': esc=True
            elif ch=='"': in_string=False
            continue
        if ch=='"': in_string=True; continue
        if ch=='#': break
        current+=ch
    assert not in_string, 'Unclosed quote: '+line
    pruned.append(current)
stack=[]; pairs={')':'(',']':'[','}':'{'}
for index,ch in enumerate('\n'.join(pruned)):
    if ch in '([{': stack.append(ch)
    elif ch in ')]}':
        assert stack and stack.pop()==pairs[ch], 'Unbalanced bracket near position '+str(index)
assert not stack,'Unclosed bracket(s): '+str(stack)
# Static architectural guardrail: no Godot mono backend or Android signing private key.
assert 'gl_compatibility' in (root/'project.godot').read_text()
# Releases must retain the permanent Android package id across subsequent versions.
assert 'package/unique_name="ink.evolu.valdora"' in (root/'export_presets.cfg').read_text()
print('OK: basic source structural checks passed. Godot runtime NOT tested here.')