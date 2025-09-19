require "open3"

module AllLint
  class Runner
    def initialize(config, files)
      @config = config
      @files = files
    end

    def run
      overall_success = true
      @config.linters.each do |name, conf|
        targets = resolve_targets(conf["glob"])
        next if targets.empty?

        command = conf["command"].to_s.gsub("${filter_files}", shell_join(targets))
        $stdout.puts "==> [#{name}] #{command}"

        status = system(command)
        overall_success &&= status
      end
      overall_success
    end

    private

    def resolve_targets(globs)
      if @files && !@files.empty?
        candidates = @files
        included = globs.flat_map { |g| Dir.glob(g) }.uniq
        candidates.select { |f| included.include?(f) }
      else
        globs.flat_map { |g| Dir.glob(g) }.uniq
      end
    end

    def shell_join(files)
      files.join(" ")
    end
  end
end
