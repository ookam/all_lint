require "open3"

module AllLint
  class Runner
    def initialize(config, files)
      @config = config
      @files = files
      @verbose = !ENV["ALL_LINT_VERBOSE"].nil?
      @list_files = !ENV["ALL_LINT_LIST_FILES"].nil?
      @color = color_enabled?
    end

    def run
  overall_success = true
  failed_names = []
  results = []
      executed_count = 0
      @config.linters.each do |name, conf|
        targets = resolve_targets(conf["glob"])
        if targets.empty?
          log_skip(name)
          next
        end

        log_targets(name, targets)
        command = conf["command"].to_s.gsub("${filter_files}", shell_join(targets))
        $stdout.puts
        $stdout.puts
        $stdout.puts "==> [#{name}] #{command}"

        executed_count += 1
        start_t = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        status = system(command)
        elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_t
        exit_code = ($?.respond_to?(:exitstatus) ? $?.exitstatus : nil)
        if status
          $stdout.puts(colorize("✅ [#{name}] 成功", :green))
        else
          msg = "❌ [#{name}] 失敗"
          msg += " (exit #{exit_code})" if exit_code
          $stdout.puts(colorize(msg, :red))
          failed_names << name
        end
        results << { name: name, success: !!status, exit_code: exit_code, duration: elapsed }
        overall_success &&= status
      end
      if executed_count > 0
        $stdout.puts
        $stdout.puts
        if overall_success
          $stdout.puts(colorize("✨ 全ての lint が成功！", :green))
        else
          $stdout.puts(colorize("🚨 一部の lint が失敗しました (#{failed_names.size} 件)", :red))
          $stdout.puts(colorize("失敗したリンター:", :red))
          failed_names.each do |n|
            $stdout.puts(colorize("  - #{n}", :red))
          end
        end
        $stdout.puts
        $stdout.puts "実行詳細:"
        results.each do |r|
          icon = r[:success] ? "✅" : "❌"
          color = r[:success] ? :green : :red
          code  = r[:exit_code]
          time  = format_duration(r[:duration])
          line = "#{icon} [#{r[:name]}] exit #{code.nil? ? '-' : code} | #{time}"
          $stdout.puts(colorize(line, color))
        end
        $stdout.puts
      end
      overall_success
    end

    private

    def color_enabled?
      return false if ENV.key?("NO_COLOR") || ENV["ALL_LINT_COLOR"] == "0"
      return true if ENV["ALL_LINT_COLOR"] == "1"
      $stdout.tty? && ENV.fetch("TERM", "") != "dumb"
    end

    def colorize(text, color)
      return text unless @color
      code = case color
      when :green then "\e[32m"
      when :red   then "\e[31m"
      else ""
      end
      reset = code.empty? ? "" : "\e[0m"
      "#{code}#{text}#{reset}"
    end

    def resolve_targets(globs)
      if @files && !@files.empty?
        only_files = @files.select { |f| File.file?(f) }
        included = globs.flat_map { |g| Dir.glob(g) }.uniq
        return only_files.select { |f| included.include?(f) }
      else
        return globs.flat_map { |g| Dir.glob(g) }.uniq
      end
    end

    def shell_join(files)
      files.join(" ")
    end

    def log_skip(name)
      return unless @verbose
      $stdout.puts "⏭️  [#{name}] 対象ファイルなし - スキップ"
    end

    def log_targets(name, targets)
      return unless @verbose
      $stdout.puts "🔍 [#{name}] 対象ファイル: #{targets.size} 件"
      if @list_files && !targets.empty?
        targets.each { |f| $stdout.puts "  - #{f}" }
      end
    end

    def format_duration(sec)
      return "0ms" if sec <= 0
      if sec < 1
        "#{(sec * 1000).round}ms"
      else
        "#{format('%.2f', sec)}s"
      end
    end
  end
end
