class Holdscribe < Formula
  desc "Push-to-talk voice transcription tool. Hold a key, speak, release to transcribe and paste"
  homepage "https://github.com/ishaq1189/holdscribe"
  url "https://github.com/ishaq1189/holdscribe/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "0019dfc4b32d63c1392aa264aed2253c1e0c2fb09216f8e2cc269bbfb8bb49b5"
  license "MIT"

  depends_on "python@3.11"
  depends_on "portaudio"
  depends_on "ffmpeg"

  resource "openai-whisper" do
    url "https://files.pythonhosted.org/packages/source/o/openai-whisper/openai-whisper-20240930.tar.gz"
    sha256 "2ba9aaa9b679eda825c5d07b7e6eabd4ab7e76b2b28d5ee2764c2b6e4bb3c95d"
  end

  resource "pyaudio" do
    url "https://files.pythonhosted.org/packages/source/P/PyAudio/PyAudio-0.2.14.tar.gz"
    sha256 "01b80a8f1c8f8fb0b29c7c9b6de62b02c5c7d0d5c3fa08d4d9c45c7e2a6bda5e"
  end

  resource "pynput" do
    url "https://files.pythonhosted.org/packages/source/p/pynput/pynput-1.7.7.tar.gz"
    sha256 "de9b9a1c5067e6b13a1c3c0f7cc65aa83e43c1fd5c7d4e57cc1e354c8b3c37dd"
  end

  resource "pyperclip" do
    url "https://files.pythonhosted.org/packages/source/p/pyperclip/pyperclip-1.9.0.tar.gz"
    sha256 "b7de0142ddc81bfc5c7507eea19da920b92252b548b96186caf94a5e2527d310"
  end

  def install
    virtualenv_install_with_resources

    # Create wrapper script
    (bin/"holdscribe").write_text(<<~EOS)
      #!/bin/bash
      export PYTHONPATH="#{libexec}/lib/python3.11/site-packages:$PYTHONPATH"
      exec "#{libexec}/bin/python3" "#{libexec}/lib/python3.11/site-packages/holdscribe.py" "$@"
    EOS
  end

  def caveats
    <<~EOS
      HoldScribe requires accessibility permissions to monitor keyboard input.
      
      Grant permissions:
      1. Open System Settings > Privacy & Security > Accessibility
      2. Click '+' and add your terminal application (Terminal.app, iTerm2, etc.)
      3. Enable the checkbox for your terminal
      
      Usage:
        holdscribe                    # Use Right Alt key (default)
        holdscribe --key f8          # Use F8 key
        holdscribe --model tiny      # Use faster model
      
      Hold the key, speak, release to transcribe and paste!
    EOS
  end

  test do
    system "#{bin}/holdscribe", "--help"
  end
end