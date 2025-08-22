class Holdscribe < Formula
  desc "Push-to-talk voice transcription tool. Hold a key, speak, release to transcribe and paste"
  homepage "https://github.com/ishaq1189/holdscribe"
  url "https://github.com/Ishaq1189/holdscribe/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "e59bee4214910df6ddd2b4d53a2e5f7058a3ceb6dde1c0900b4ee511af3eccba"
  license "MIT"

  depends_on "python@3.11"
  depends_on "portaudio"
  depends_on "ffmpeg"

  def install
    # Install using Python's built-in venv and pip
    system "python3.11", "-m", "venv", libexec
    
    # Install dependencies in the virtual environment
    system libexec/"bin/pip", "install", "openai-whisper>=20240930"
    system libexec/"bin/pip", "install", "pyaudio>=0.2.11"
    system libexec/"bin/pip", "install", "pynput>=1.7.6"
    system libexec/"bin/pip", "install", "pyperclip>=1.8.2"
    
    # Copy the main script to the virtual environment
    (libexec/"bin/holdscribe.py").write(File.read("holdscribe.py"))
    
    # Create wrapper script with automatic permission request
    (bin/"holdscribe").write(<<~EOS)
      #!/bin/bash
      
      # Function to check and request accessibility permissions
      check_accessibility() {
        "#{libexec}/bin/python" -c "
import subprocess
import sys
import os

# Check if we have accessibility permissions
try:
    from pynput import keyboard
    # Try to create a listener to test permissions
    listener = keyboard.Listener(on_press=lambda key: None)
    listener.start()
    listener.stop()
    print('✅ Accessibility permissions granted')
except Exception as e:
    if 'not trusted' in str(e).lower():
        print('⚠️  Accessibility permissions required')
        print('Opening System Settings...')
        
        # Get Python executable path
        python_path = '#{Formula["python@3.11"].opt_prefix}/Frameworks/Python.framework/Versions/3.11/Resources/Python.app'
        
        # Open System Settings to Accessibility
        subprocess.run(['open', 'x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility'])
        
        print(f'Please add this application to accessibility:')
        print(f'{python_path}')
        print()
        print('1. Click the lock 🔒 and authenticate')
        print('2. Click + and navigate to the path above')  
        print('3. Enable the checkbox for Python.app')
        print('4. Run this command again')
        sys.exit(1)
    else:
        print(f'Error: {e}')
        sys.exit(1)
"
      }
      
      # Check permissions before running
      check_accessibility || exit 1
      
      # Run HoldScribe
      exec "#{libexec}/bin/python" "#{libexec}/bin/holdscribe.py" "$@"
    EOS
    
    # Make wrapper script executable  
    chmod 0755, bin/"holdscribe"
    
    # Install HoldScribe.app bundle for persistent accessibility permissions
    app_bundle = prefix/"HoldScribe.app"
    app_bundle.mkpath
    (app_bundle/"Contents").mkpath
    (app_bundle/"Contents/MacOS").mkpath
    (app_bundle/"Contents/Resources").mkpath
    
    # Create Info.plist for app bundle
    (app_bundle/"Contents/Info.plist").write(<<~EOS)
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
          <key>CFBundleExecutable</key>
          <string>HoldScribe</string>
          <key>CFBundleIdentifier</key>
          <string>com.holdscribe.app</string>
          <key>CFBundleName</key>
          <string>HoldScribe</string>
          <key>CFBundleDisplayName</key>
          <string>HoldScribe</string>
          <key>CFBundleVersion</key>
          <string>1.0.0</string>
          <key>CFBundleShortVersionString</key>
          <string>1.0.0</string>
          <key>CFBundlePackageType</key>
          <string>APPL</string>
          <key>NSHighResolutionCapable</key>
          <true/>
          <key>NSMicrophoneUsageDescription</key>
          <string>HoldScribe needs microphone access to record audio for transcription.</string>
          <key>NSAppleEventsUsageDescription</key>
          <string>HoldScribe needs accessibility permissions to monitor keyboard input and paste transcribed text.</string>
          <key>LSUIElement</key>
          <true/>
          <key>LSMinimumSystemVersion</key>
          <string>10.15</string>
      </dict>
      </plist>
    EOS
    
    # Create app bundle executable
    (app_bundle/"Contents/MacOS/HoldScribe").write(<<~EOS)
      #!/bin/bash
      # HoldScribe App Bundle Launcher
      exec "#{libexec}/bin/python" "#{libexec}/bin/holdscribe.py" "$@"
    EOS
    chmod 0755, app_bundle/"Contents/MacOS/HoldScribe"
    
    # Copy Python script to app bundle
    (app_bundle/"Contents/Resources/holdscribe.py").write(File.read("holdscribe.py"))
    
    # Create launchd plist for background service
    (prefix/"homebrew.ishaq1189.holdscribe.plist").write(<<~EOS)
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
        <key>Label</key>
        <string>homebrew.ishaq1189.holdscribe</string>
        <key>ProgramArguments</key>
        <array>
          <string>#{prefix}/HoldScribe.app/Contents/MacOS/HoldScribe</string>
        </array>
        <key>RunAtLoad</key>
        <true/>
        <key>KeepAlive</key>
        <true/>
        <key>StandardOutPath</key>
        <string>#{var}/log/holdscribe.log</string>
        <key>StandardErrorPath</key>
        <string>#{var}/log/holdscribe.log</string>
      </dict>
      </plist>
    EOS
  end

  service do
    run [prefix/"HoldScribe.app/Contents/MacOS/HoldScribe"]
    keep_alive true
    log_path var/"log/holdscribe.log"
    error_log_path var/"log/holdscribe.log"
  end

  def caveats
    <<~EOS
      🎤 HoldScribe is ready to use!
      
      SETUP: Grant accessibility permissions to HoldScribe.app:
      
      1. Run HoldScribe.app once to register permissions:
         open "#{prefix}/HoldScribe.app"
         
      2. Grant accessibility permissions when prompted:
         System Settings → Privacy & Security → Accessibility
         Add HoldScribe.app and enable it
      
      3. Start background service:
         brew services start ishaq1189/holdscribe/holdscribe
      
      Usage options:
        holdscribe                    # Command line (Right Alt key)
        holdscribe --key f8          # Use F8 key  
        holdscribe --model tiny      # Faster model
        open "#{prefix}/HoldScribe.app"  # App bundle (persistent permissions)

      Service management:
        brew services stop ishaq1189/holdscribe/holdscribe    # Stop service
        brew services restart ishaq1189/holdscribe/holdscribe # Restart service
        
      If permissions get stuck, reset with:
        tccutil reset Accessibility
        
      Hold the Right Alt key, speak, release to transcribe and paste!
    EOS
  end

  test do
    system "#{bin}/holdscribe", "--help"
  end
end