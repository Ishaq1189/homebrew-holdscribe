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
    # Install Python package
    system "python3.11", "-m", "pip", "install", *std_pip_args, "."
    
    # Install the main script
    bin.install "holdscribe.py" => "holdscribe"
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