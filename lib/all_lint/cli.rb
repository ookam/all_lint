require "optparse"

module AllLint
  class CLI
    def initialize(argv)
      @argv = argv.dup
    end

    def run
      cmd = @argv.shift
      case cmd
      when "run"
        files = @argv
        config = Config.load
        runner = Runner.new(config, files)
        success = runner.run
        return success ? 0 : 1
      else
        $stderr.puts "Usage: all_lint run [<file>...]"
        return 2
      end
    rescue Config::Error => e
      $stderr.puts e.message
      2
    end
  end
end
