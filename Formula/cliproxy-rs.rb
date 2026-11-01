require "securerandom"

class CliproxyRs < Formula
  desc "Local proxy for coding assistant APIs"
  homepage "https://github.com/vayungodara/cliproxy-rs"
  license "MIT"

  on_macos do
    on_arm do
      url "https://github.com/vayungodara/cliproxy-rs/releases/download/v0.4.1/cliproxy-0.4.1-aarch64-apple-darwin.tar.gz"
      sha256 "e481d8da65f1f9f75dcb79c14d5b6f344c2fa7fafd4ea4d01c5bcbd65ba76b97"
    end
    on_intel do
      url "https://github.com/vayungodara/cliproxy-rs/releases/download/v0.4.1/cliproxy-0.4.1-x86_64-apple-darwin.tar.gz"
      sha256 "52b541f0ae31907aa203e150942dafb9bbcedc0ebbd9fc5934024e39671e088c"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/vayungodara/cliproxy-rs/releases/download/v0.4.1/cliproxy-0.4.1-aarch64-unknown-linux-gnu.tar.gz"
      sha256 "8cb388c34f70d0080ceeddfe85ee7150cc477858d6db60af372d161158d98fe0"
    end
    on_intel do
      url "https://github.com/vayungodara/cliproxy-rs/releases/download/v0.4.1/cliproxy-0.4.1-x86_64-unknown-linux-gnu.tar.gz"
      sha256 "367e9d70902282179e6024179b61ace8cc3a5346494701346b95b82410b262b6"
    end
  end

  def install
    bin.install "cliproxy"
  end

  # ponytail: support older Homebrew; use post_install_steps when that compatibility is no longer needed.
  def post_install
    config_dir = etc/"cliproxy-rs"
    config = config_dir/"config.yaml"
    return if config.exist?

    config_dir.mkpath
    config_dir.chmod 0700
    (config_dir/"auth").mkpath
    keys_file = config_dir/"keys.env"
    unless keys_file.exist?
      keys_file.write <<~EOS
        CLIPROXY_CLIENT_KEY=#{SecureRandom.hex(24)}
        CLIPROXY_MANAGEMENT_KEY=#{SecureRandom.hex(24)}
      EOS
      keys_file.chmod 0600
    end
    keys = keys_file.read.lines.reject { |line| line.strip.empty? || line.lstrip.start_with?("#") }
                    .to_h { |line| line.strip.split("=", 2) }
    client_key = keys.fetch("CLIPROXY_CLIENT_KEY")
    management_key = keys.fetch("CLIPROXY_MANAGEMENT_KEY")
    unless [client_key, management_key].all? { |key| key.match?(/\A[0-9a-f]{48}\z/) }
      odie "Invalid keys in #{keys_file}; restore the keys or write config.yaml yourself."
    end
    config.write <<~EOS
      server:
        host: "127.0.0.1"
        port: 8317
      access:
        api-keys:
          - "#{client_key}"
      management:
        allow-remote: false
        secret-key: "#{management_key}"
      oauth:
        auth-dir: "#{config_dir}/auth"
    EOS
    config.chmod 0600
  end

  def caveats
    <<~EOS
      Config and sign-in credentials are kept in #{etc}/cliproxy-rs.
      Client and management keys are saved in #{etc}/cliproxy-rs/keys.env.
      The default server listens only on 127.0.0.1:8317.
      Start it with brew services start cliproxy-rs, then open:
        http://127.0.0.1:8317/management.html
      If port 8317 is already in use, change server.port in config.yaml first.
    EOS
  end

  service do
    run [opt_bin/"cliproxy", "--config", etc/"cliproxy-rs/config.yaml"]
    keep_alive true
    log_path var/"log/cliproxy-rs.log"
    error_log_path var/"log/cliproxy-rs.log"
  end

  test do
    assert_match "cliproxy #{version}", shell_output("#{bin}/cliproxy --version")
  end
end
