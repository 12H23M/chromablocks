Build an Android APK for the ChromaBlocks Godot project.

## Steps

1. Run the Godot export command to build a debug APK:

```
"/Users/elfguy/Downloads/Godot.app/Contents/MacOS/Godot" --headless --export-debug "Android" chromablocks.apk
```

2. After the build completes, verify the APK was created and report its file size.

3. If the build fails, analyze the error output and suggest fixes.

## Notes

- The export preset "Android" is defined in `export_presets.cfg`
- Debug keystore is used for signing
- Architecture: arm64-v8a
- Package: com.alba.chromablocks
- Output file: `chromablocks.apk` in the project root
