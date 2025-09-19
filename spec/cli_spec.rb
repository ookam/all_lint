require "spec_helper"
require "tempfile"

RSpec.describe AllLint::CLI do
  def with_tmp_dir
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) { yield dir }
    end
  end

  it "prints usage and exits 2 for unknown command" do
    status = AllLint::CLI.new(["help"]).run
    expect(status).to eq(2)
  end

  it "runs linters sequentially with banner and ${filter_files}" do
    with_tmp_dir do |dir|
      File.write(".all_lint.yml", <<~YML)
        linters:
          echo:
            glob: ["**/*.rb"]
            command: "bash -lc 'echo RUN ${filter_files}'"
      YML

      File.write("a.rb", "# a")
      File.write("b.txt", "# b")

      config = AllLint::Config.load
      runner = AllLint::Runner.new(config, [])

      expect {
        ok = runner.run
        expect(ok).to be true
      }.to output(/==> \[echo\] .*/).to_stdout
    end
  end

  it "filters by passed files (glob ∩ args)" do
    with_tmp_dir do |dir|
      File.write(".all_lint.yml", <<~YML)
        linters:
          echo:
            glob: ["**/*.rb"]
            command: "bash -lc 'echo RUN ${filter_files}'"
      YML

      File.write("a.rb", "# a")
      File.write("b.rb", "# b")
      File.write("c.txt", "# c")

      config = AllLint::Config.load
      runner = AllLint::Runner.new(config, ["a.rb", "c.txt"]) # => only a.rb matches

      expect {
        ok = runner.run
        expect(ok).to be true
      }.to output(/RUN a.rb/).to_stdout_from_any_process
    end
  end

  it "returns non-zero when any linter fails" do
    with_tmp_dir do |dir|
      File.write(".all_lint.yml", <<~YML)
        linters:
          ok:
            glob: ["*.rb"]
            command: "bash -lc 'exit 0'"
          ng:
            glob: ["*.rb"]
            command: "bash -lc 'exit 3'"
      YML
      File.write("a.rb", "# a")

      config = AllLint::Config.load
      runner = AllLint::Runner.new(config, [])
      ok = runner.run
      expect(ok).to be false
    end
  end

  it "returns code 2 when config invalid" do
    with_tmp_dir do |dir|
      File.write(".all_lint.yml", "invalid: true\n")
      code = AllLint::CLI.new(["run"]).run
      expect(code).to eq(2)
    end
  end

  it "CLI passes args to runner and filters accordingly" do
    with_tmp_dir do |dir|
      File.write(".all_lint.yml", <<~YML)
        linters:
          echo:
            glob: ["**/*.rb"]
            command: "bash -lc 'echo RUN ${filter_files}'"
      YML

      File.write("a.rb", "# a")
      File.write("b.rb", "# b")
      File.write("c.txt", "# c")

      expect {
        code = AllLint::CLI.new(["run", "a.rb", "c.txt"]).run
        expect(code).to eq(0)
      }.to output(/RUN a\.rb/).to_stdout_from_any_process
    end
  end

  it "CLI returns 1 when any linter fails" do
    with_tmp_dir do |dir|
      File.write(".all_lint.yml", <<~YML)
        linters:
          ng:
            glob: ["*.rb"]
            command: "bash -lc 'exit 5'"
      YML
      File.write("a.rb", "# a")

      code = AllLint::CLI.new(["run"]).run
      expect(code).to eq(1)
    end
  end

  it "returns 0 and prints nothing when all linters are skipped" do
    with_tmp_dir do |dir|
      File.write(".all_lint.yml", <<~YML)
        linters:
          echo:
            glob: ["**/*.rb"]
            command: "bash -lc 'echo SHOULD_NOT_RUN'"
      YML
      File.write("a.txt", "# not matching")

      expect {
        code = AllLint::CLI.new(["run"]).run
        expect(code).to eq(0)
      }.not_to output.to_stdout
    end
  end
end
