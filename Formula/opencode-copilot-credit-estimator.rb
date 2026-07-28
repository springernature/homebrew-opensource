class OpencodeCopilotCreditEstimator < Formula
  include Language::Python::Virtualenv

  desc "Terminal UI for estimating GitHub Copilot AI credit usage from opencode logs"
  homepage "https://github.com/springernature/opencode-copilot-credit-estimator"
  # NOTE: this repository is currently private and has no tags/releases, so
  # this formula tracks the `main` branch HEAD rather than a pinned version.
  # Upstream intends to open source it once internal approval is granted;
  # revisit this formula (public URL, version pin, license) at that point.
  license :cannot_represent # no LICENSE file is present upstream yet
  head "ssh://git@github.com/springernature/opencode-copilot-credit-estimator.git", branch: "main"

  depends_on "python@3.14"

  resource "typing-extensions" do
    url "https://files.pythonhosted.org/packages/49/d3/b8441a820a491ddfc024b0b0cf0393375b75ea13866d9c66727e54c2fc80/typing_extensions-4.16.0-py3-none-any.whl"
    sha256 "481caa481374e813c1b176ada14e97f1f67a4539ce9cfeb3f350d78d6370c2e8"
  end

  resource "platformdirs" do
    url "https://files.pythonhosted.org/packages/7d/68/d8d58938dfb1370b266a1a729e6d77a985be23689a0496498ee17b2cbf90/platformdirs-4.11.0-py3-none-any.whl"
    sha256 "360ccded2b7fce0af0ff80cc8f5942a1c5d99b0e856033acb030bfc634709e74"
  end

  resource "pygments" do
    url "https://files.pythonhosted.org/packages/f4/7e/a72dd26f3b0f4f2bf1dd8923c85f7ceb43172af56d63c7383eb62b332364/pygments-2.20.0-py3-none-any.whl"
    sha256 "81a9e26dd42fd28a23a2d169d86d7ac03b46e2f8b59ed4698fb4785f946d0176"
  end

  resource "mdurl" do
    url "https://files.pythonhosted.org/packages/b3/38/89ba8ad64ae25be8de66a6d463314cf1eb366222074cfda9ee839c56a4b4/mdurl-0.1.2-py3-none-any.whl"
    sha256 "84008a41e51615a49fc9966191ff91509e3c40b939176e643fd50a5c2196b8f8"
  end

  resource "uc-micro-py" do
    url "https://files.pythonhosted.org/packages/61/73/d21edf5b204d1467e06500080a50f79d49ef2b997c79123a536d4a17d97c/uc_micro_py-2.0.0-py3-none-any.whl"
    sha256 "3603a3859af53e5a39bc7677713c78ea6589ff188d70f4fee165db88e22b242c"
  end

  resource "linkify-it-py" do
    url "https://files.pythonhosted.org/packages/b4/de/88b3be5c31b22333b3ca2f6ff1de4e863d8fe45aaea7485f591970ec1d3e/linkify_it_py-2.1.0-py3-none-any.whl"
    sha256 "0d252c1594ecba2ecedc444053db5d3a9b7ec1b0dd929c8f1d74dce89f86c05e"
  end

  resource "mdit-py-plugins" do
    url "https://files.pythonhosted.org/packages/a5/69/6da5581c6a7fede7dc261bf4e67d6adca4196f176b43288b55b3db395b6e/mdit_py_plugins-0.6.1-py3-none-any.whl"
    sha256 "214c82fb2ac524472ab6a5bcab1de80f73b50443e187f401bfd77efbc7c6481d"
  end

  resource "markdown-it-py" do
    url "https://files.pythonhosted.org/packages/06/ff/7841249c247aa650a76b9ee4bbaeae59370dc8bfd2f6c01f3630c35eb134/markdown_it_py-4.2.0-py3-none-any.whl"
    sha256 "9f7ebbcd14fe59494226453aed97c1070d83f8d24b6fc3a3bcf9a38092641c4a"
  end

  resource "rich" do
    url "https://files.pythonhosted.org/packages/82/3b/64d4899d73f91ba49a8c18a8ff3f0ea8f1c1d75481760df8c68ef5235bf5/rich-15.0.0-py3-none-any.whl"
    sha256 "33bd4ef74232fb73fe9279a257718407f169c09b78a87ad3d296f548e27de0bb"
  end

  resource "textual" do
    url "https://files.pythonhosted.org/packages/fb/be/35261223d9416a0751cdff1c7b4a6f881387218a12d439fe22fefebc8c04/textual-8.2.8-py3-none-any.whl"
    sha256 "267375fd402dc8d981457212efa71f0e3365fd17bba144ba9bb3ed7563cb374a"
  end

  resource "plotext" do
    url "https://files.pythonhosted.org/packages/f6/1e/12fe7c40cd2099a1f454518754ed229b01beaf3bbb343127f0cc13ce6c22/plotext-5.3.2-py3-none-any.whl"
    sha256 "394362349c1ddbf319548cfac17ca65e6d5dfc03200c40dfdc0503b3e95a2283"
  end

  resource "textual-plotext" do
    url "https://files.pythonhosted.org/packages/35/53/fba7da208f9d3f59254413660fa0aa6599f2aca806f3ae356670455fd4ea/textual_plotext-1.0.1-py3-none-any.whl"
    sha256 "6b6bfd00b29f121ddf216eaaf9bdac9d688ed72f40028484d279a10cbbb169ed"
  end

  def install
    # The project ships a standalone script (estimator.py) with no
    # setup.py/[build-system], so it can't be pip-installed directly. Build a
    # virtualenv containing just its dependencies, then wire up a wrapper
    # script that runs estimator.py with that venv's interpreter.
    venv = virtualenv_create(libexec, "python3.14")
    venv.pip_install resources

    libexec.install "estimator.py"

    (bin/"opencode-copilot-credit-estimator").write <<~SH
      #!/bin/bash
      exec "#{libexec}/bin/python3" "#{libexec}/estimator.py" "$@"
    SH
    (bin/"opencode-copilot-credit-estimator").chmod 0755
  end

  test do
    assert_match "usage:", shell_output("#{bin}/opencode-copilot-credit-estimator --help")
  end
end
