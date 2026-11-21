require "securerandom"

class CliproxyRs < Formula
  desc "Local proxy for coding assistant APIs"
  homepage "https://github.com/vayungodara/cliproxy-rs"
  license "MIT"

  on_macos do
    on_arm do
      url "https://github.com/vayungodara/cliproxy-rs/releases/download/v0.4.5/cliproxy-0.4.5-aarch64-apple-darwin.tar.gz"
      sha256 "ae6a800735409549ab2126f01e6294c0e0f033222c6d6dfec8cc40a4ddef0b52"
    end
    on_intel do
      url "https://github.com/vayungodara/cliproxy-rs/releases/download/v0.4.5/cliproxy-0.4.5-x86_64-apple-darwin.tar.gz"
      sha256 "94598bfc9dce3d6a1adb607c62df4024a53e0aca6b588c9d8e286bf6c2347f41"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/vayungodara/cliproxy-rs/releases/download/v0.4.5/cliproxy-0.4.5-aarch64-unknown-linux-gnu.tar.gz"
      sha256 "0b317524ef836968c259b6fcb0c1f5a0a34e3420f9a7257037fbde90bb554cff"
    end
    on_intel do
      url "https://github.com/vayungodara/cliproxy-rs/releases/download/v0.4.5/cliproxy-0.4.5-x86_64-unknown-linux-gnu.tar.gz"
      sha256 "683bc012b123c7759ba8f023c91bad63fdedd9e68b06ecc6b676e034ec0bfa7f"
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
