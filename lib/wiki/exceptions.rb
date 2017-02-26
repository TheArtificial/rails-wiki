module Wiki

  # obvious, eh?
  class GitError < StandardError
  end

  # used when a page path is relevent
  class PageError < StandardError
    attr_reader :path
    attr_writer :default_message

    def initialize(message = nil, path = nil)
      @message = message
      @path = path
      @default_message = "Unknown page error"
    end

    def to_s
      @message || @default_message
    end
  end
end
