require 'open3'

module Transrate

  class Cmd

    attr_accessor :cmd, :stdout, :stderr, :status

    def initialize cmd
      @cmd = cmd
    end

    def run
      logger.debug 'running command:'
      logger.debug @cmd
      @stdout, @stderr, @status = Open3.capture3 @cmd
    end

    def to_s
      @cmd
    end

  end

end
