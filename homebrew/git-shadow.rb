class GitShadow < Formula
  desc "Shadow branch pattern utilities for Git"
  homepage "https://github.com/filozofer/git-shadow"
  url "https://github.com/filozofer/git-shadow/releases/download/v1.0.1/git-shadow-1.0.1.tar.gz"
  sha256 "0d6e22eea6542cd1afc94888f02792c68a46e9557d34d3994e0cfae104fc990e"
  version "1.0.1"
  license "MIT"

  # No dependencies beyond bash and git (both already required by Homebrew).

  def install
    # Make all shell scripts executable before installing.
    Dir["commands/**/*.sh", "lib/*.sh", "scripts/*.sh"].each do |f|
      chmod 0755, f
    end

    # Install the toolkit directory structure under the Cellar prefix.
    # bin/git-shadow resolves TOOL_ROOT as prefix/ (one level up from bin/).
    prefix.install "commands", "config", "lib", "scripts", "VERSION"
    (prefix/"bin").install "bin/git-shadow"
    chmod 0755, prefix/"bin/git-shadow"

    # Expose the binary via a Homebrew-managed symlink in $(brew --prefix)/bin.
    bin.install_symlink prefix/"bin/git-shadow"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/git-shadow version")
  end
end
