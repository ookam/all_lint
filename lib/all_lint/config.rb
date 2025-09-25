require "yaml"

module AllLint
  class Config
    class Error < StandardError; end

    DEFAULT_PATH = ".all_lint.yml"

  attr_reader :linters, :options

    def initialize(path = DEFAULT_PATH)
      @path = path
      @linters = {}
  @options = {}
    end

    def self.load(path = DEFAULT_PATH)
      new(path).tap(&:load!)
    end

    def load!
      begin
        data = YAML.load_file(@path)
      rescue Errno::ENOENT
        raise Error, "Config file not found: #{@path}"
      rescue Psych::SyntaxError => e
        raise Error, "YAML syntax error: #{e.message}"
      end

      unless data.is_a?(Hash) && data["linters"].is_a?(Hash)
        raise Error, "Invalid config: 'linters' hash is required"
      end

      # options (optional)
      if data.key?("options")
        unless data["options"].is_a?(Hash)
          raise Error, "Invalid config: 'options' must be a Hash"
        end
        @options = data["options"] || {}
      else
        @options = {}
      end
      # Coerce/Default known options
      @options["stop_on_early"] = !!@options["stop_on_early"]

      @linters = data["linters"].map do |name, conf|
        unless conf.is_a?(Hash)
          raise Error, "Invalid linter '#{name}': must be a Hash"
        end
        glob = conf["glob"]
        command = conf["command"]
        if glob.nil? || command.nil?
          raise Error, "Invalid linter '#{name}': 'glob' and 'command' are required"
        end
        globs = glob.is_a?(Array) ? glob : [glob]
        [name.to_s, { "glob" => globs, "command" => command.to_s }]
      end.to_h

      self
    end
  end
end
