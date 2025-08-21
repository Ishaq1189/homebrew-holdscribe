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
    
    # Create wrapper script
    (bin/"holdscribe").write(<<~EOS)
      #!/bin/bash
      exec "#{libexec}/bin/python" "#{libexec}/bin/holdscribe.py" "$@"
    EOS
    
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
      HoldScribe requires accessibility permissions to monitor keyboard input.
      
      Grant permissions for background service:
      1. Open System Settings > Privacy & Security > Accessibility
      2. Click '+' and add: #{Formula["python@3.11"].opt_prefix}/Frameworks/Python.framework/Versions/3.11/Resources/Python.app
      3. Enable the checkbox for Python.app
      
      For manual usage, also add your terminal application (Terminal.app, iTerm2, etc.)
      
      To run HoldScribe as a background service:
        brew services start ishaq1189/holdscribe/holdscribe

      To stop the background service:
        brew services stop ishaq1189/holdscribe/holdscribe

      Manual usage:
        holdscribe                    # Use Right Alt key (default)
        holdscribe --key f8          # Use F8 key  
        holdscribe --model tiny      # Use faster model

      Hold the Right Alt key, speak, release to transcribe and paste!
    EOS
  end

  test do
    system "#{bin}/holdscribe", "--help"
  end
end