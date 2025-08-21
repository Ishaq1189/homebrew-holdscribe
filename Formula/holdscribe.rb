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
          <string>#{opt_bin}/holdscribe</string>
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
    run [opt_bin/"holdscribe"]
    keep_alive true
    log_path var/"log/holdscribe.log"
    error_log_path var/"log/holdscribe.log"
  end

  def caveats
    <<~EOS
      🎤 HoldScribe is ready to use!
      
      On first run, HoldScribe will automatically:
      • Check accessibility permissions
      • Open System Settings if permissions needed
      • Guide you through the one-time setup
      
      To run as background service (recommended):
        brew services start ishaq1189/holdscribe/holdscribe
        
      To run manually:
        holdscribe                    # Use Right Alt key (default)
        holdscribe --key f8          # Use F8 key  
        holdscribe --model tiny      # Use faster model

      Hold the Right Alt key, speak, release to transcribe and paste!
      
      Service management:
        brew services stop ishaq1189/holdscribe/holdscribe    # Stop service
        brew services restart ishaq1189/holdscribe/holdscribe # Restart service
    EOS
  end

  test do
    system "#{bin}/holdscribe", "--help"
  end
end