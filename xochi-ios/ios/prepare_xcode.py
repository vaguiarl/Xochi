#!/usr/bin/env python3
"""Finalize generated project metadata; never applies a real signing identity."""
from pathlib import Path
import plistlib
import re
import sys

project = Path(sys.argv[1])
app = Path(sys.argv[2])
pbx = project / 'project.pbxproj'
text = pbx.read_text()
text = re.sub(r'DEVELOPMENT_TEAM = "?(UNSIGNED|SIMULATOR)"?;', 'DEVELOPMENT_TEAM = "";', text)
# Automatic archive provisioning uses Apple Development; export re-signs for distribution.
text = text.replace('CODE_SIGN_IDENTITY = "Apple Distribution";', 'CODE_SIGN_IDENTITY = "Apple Development";')
# Godot's recursive search expands DerivedData and old build products on a rebuild.
# Dependencies are explicitly referenced in the Xcode project; a flat inherited path is sufficient.
text = text.replace('"$(PROJECT_DIR)/**"', '"$(PROJECT_DIR)"')
es_id = '58BC40A76FB64CE6A357018D'
if es_id not in text:
    text = text.replace('/* End PBXFileReference section */', f'\t\t{es_id} /* es */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.strings; name = es; path = es.lproj/InfoPlist.strings; sourceTree = "<group>"; }};\n/* End PBXFileReference section */')
    text = re.sub(r'(D0BCFE4418AEBDA2004A7AAE /\* InfoPlist.strings \*/ = \{\s*isa = PBXVariantGroup;\s*children = \()', r'\1\n\t\t\t\t' + es_id + ' /* es */,', text)
    text = text.replace('knownRegions = (', 'knownRegions = (\n\t\t\t\tes,')
pbx.write_text(text)
info = app / f'{app.name}-Info.plist'
with info.open('rb') as stream:
    data = plistlib.load(stream)
data['ITSAppUsesNonExemptEncryption'] = False
data['CFBundleLocalizations'] = ['en', 'es']
with info.open('wb') as stream:
    plistlib.dump(data, stream, sort_keys=False)
# Godot already includes localized InfoPlist strings via variant groups when exported.
# These permission strings are also copied directly into each built app by Xcode.
for locale, mic, speech in [
    ('en', 'Cheer for Xochi to earn Second Wind. Audio stays on your iPhone and is never saved. You can always tap Courage instead.', 'Recognize encouragement for Xochi using on-device speech only. Nothing is sent to a server.'),
    ('es', 'Anima a Xochi para obtener Segundo aliento. El audio se procesa en tu iPhone y nunca se guarda. También puedes tocar Ánimo.', 'Reconoce tus palabras de ánimo con voz local. No se envía nada a un servidor.'),
]:
    folder = app / f'{locale}.lproj'
    folder.mkdir(exist_ok=True)
    target = folder / 'InfoPlist.strings'
    base = target.read_text() if target.exists() else ''
    base = re.sub(r'^"NS(?:MicrophoneUsageDescription|SpeechRecognitionUsageDescription)".*;\n?', '', base, flags=re.M)
    base += f'\n"NSMicrophoneUsageDescription" = "{mic}";\n"NSSpeechRecognitionUsageDescription" = "{speech}";\n'
    target.write_text(base)
