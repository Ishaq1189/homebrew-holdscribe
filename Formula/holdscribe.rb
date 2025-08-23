class Holdscribe < Formula
  desc "Push-to-talk voice transcription tool. Hold a key, speak, release to transcribe and paste"
  homepage "https://github.com/ishaq1189/holdscribe"
  url "https://github.com/Ishaq1189/holdscribe/archive/refs/tags/v1.3.6.tar.gz"
  sha256 "398aa42afbe5138b08cd505f55d9408b74993cd3ff9b062b9323092998bbc4d7"
  license "MIT"
  version "1.3.6"

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
    # Note: permissions will be fixed by wrapper script if needed
    
    # Create wrapper script with automatic permission request
    (bin/"holdscribe").write(<<~EOS)
      #!/bin/bash
      
      # Self-fix permissions if needed (solves permission denied issues)
      if [[ ! -x "$0" ]]; then
          chmod +x "$0" 2>/dev/null || {
              echo "❌ Permission denied: Cannot execute holdscribe"
              echo "Run this command to fix: chmod +x $(which holdscribe)"
              echo "Or reinstall with: brew reinstall holdscribe"
              exit 1
          }
          echo "✅ Fixed script permissions automatically"
      fi
      
      # Check Python script permissions  
      if [[ ! -x "#{libexec}/bin/holdscribe.py" ]]; then
          chmod +x "#{libexec}/bin/holdscribe.py" 2>/dev/null || {
              echo "❌ Installation error: Cannot fix Python script permissions"
              echo "Please reinstall with: brew reinstall holdscribe"
              exit 1
          }
      fi
      
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
    
    # Use install command which should set permissions correctly
    system "chmod", "755", bin/"holdscribe"  
    system "install", "-m", "755", bin/"holdscribe", bin/"holdscribe.tmp"
    system "mv", bin/"holdscribe.tmp", bin/"holdscribe"
    
    # Verify and show clear message during installation
    unless File.executable?(bin/"holdscribe")
      ohai "❌ IMPORTANT: Execute permissions could not be set automatically"
      ohai "After installation completes, run this command:"
      ohai "    chmod +x $(brew --prefix)/bin/holdscribe"
      ohai "Then run: holdscribe"
      ohai ""
      ohai "This is a known issue we're working to resolve."
    else
      ohai "✅ Execute permissions set successfully"
    end
    
    # Create backup script with guaranteed permissions
    (bin/"holdscribe.sh").write((bin/"holdscribe").read)
    system "chmod", "755", bin/"holdscribe.sh"
    
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
          <string>1.3.6</string>
          <key>CFBundleShortVersionString</key>
          <string>1.3.6</string>
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
          <string>#{opt_prefix}/HoldScribe.app/Contents/MacOS/HoldScribe</string>
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
    run [opt_prefix/"HoldScribe.app/Contents/MacOS/HoldScribe"]
    keep_alive true
    log_path var/"log/holdscribe.log"
    error_log_path var/"log/holdscribe.log"
  end

  def caveats
    <<~EOS
      🎤 #{Tty.bold}#{Tty.green}HoldScribe is ready to use!#{Tty.reset}
      
      #{Tty.bold}#{Tty.red}⚠️  IMPORTANT:#{Tty.reset} If you get 'permission denied' error:
      #{Tty.bold}#{Tty.yellow}   chmod +x $(brew --prefix)/bin/holdscribe#{Tty.reset}
      #{Tty.bold}#{Tty.yellow}   holdscribe#{Tty.reset}
      
      #{Tty.bold}#{Tty.blue}QUICK START:#{Tty.reset}
      #{Tty.green}1.#{Tty.reset} Run HoldScribe (automatic permission setup):
         #{Tty.cyan}holdscribe#{Tty.reset}
         
         #{Tty.dim}Alternatives if needed:#{Tty.reset}
         #{Tty.cyan}holdscribe.sh#{Tty.reset} (backup script)
         #{Tty.cyan}$(brew --prefix)/bin/holdscribe#{Tty.reset} (direct path)
      
      #{Tty.green}2.#{Tty.reset} Grant accessibility permissions when prompted
      
      #{Tty.green}3.#{Tty.reset} #{Tty.bold}Run in background (keeps running):#{Tty.reset}
         #{Tty.yellow}holdscribe --background#{Tty.reset}
         # Disables ESC exit, runs continuously
      
      #{Tty.bold}#{Tty.blue}USAGE:#{Tty.reset}
        #{Tty.cyan}holdscribe#{Tty.reset}                         # Interactive mode (Right Alt key)
        #{Tty.cyan}holdscribe --version#{Tty.reset}              # Show current version
        #{Tty.cyan}holdscribe --key f8#{Tty.reset}               # Use F8 key instead
        #{Tty.cyan}holdscribe --model tiny#{Tty.reset}           # Faster/smaller AI model
        #{Tty.cyan}holdscribe --background#{Tty.reset}           # #{Tty.bold}Background mode (no crashes!)#{Tty.reset}
        #{Tty.cyan}holdscribe --daemon#{Tty.reset}               # #{Tty.bold}True daemon mode#{Tty.reset}
        #{Tty.cyan}holdscribe --prompt-permissions#{Tty.reset}   # #{Tty.bold}Enhanced security mode#{Tty.reset}
      
      #{Tty.bold}#{Tty.green}🚀 BACKGROUND MODES:#{Tty.reset}
        #{Tty.yellow}--background#{Tty.reset}: Properly detached background process (no more crashes!)
        #{Tty.yellow}--daemon#{Tty.reset}:     True daemon - completely detaches from terminal
      
      #{Tty.bold}#{Tty.red}🔐 ENHANCED SECURITY MODE:#{Tty.reset}
        The #{Tty.yellow}--prompt-permissions#{Tty.reset} flag provides extra security by asking
        for your consent before each recording session. Perfect for
        shared systems or security-conscious users.
      
      #{Tty.bold}#{Tty.magenta}💡 PRO TIP:#{Tty.reset} Add to your shell profile:
         echo "alias hs='holdscribe --background'" >> ~/.zshrc
         echo "alias hsd='holdscribe --daemon'" >> ~/.zshrc
         echo "alias hss='holdscribe --prompt-permissions'" >> ~/.zshrc
         # Then: hs (background), hsd (daemon), hss (secure mode)
      
      #{Tty.red}Hold the Right Alt key, speak, release to transcribe and paste!#{Tty.reset}
      
      #{Tty.bold}Stop background/daemon:#{Tty.reset} pkill -f holdscribe (or killall Python)
    EOS
  end

  test do
    system "#{bin}/holdscribe", "--help"
  end
end