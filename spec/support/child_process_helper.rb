# frozen_string_literal: true

autoload :ChildProcess, 'childprocess'
autoload :Tempfile, 'tempfile'

module ChildProcessHelper
  class SpawnError < StandardError; end

  extend self

  def get_output(cmd, env: nil, cwd: nil)
    process = ChildProcess.new(*cmd)
    process.io.inherit!
    process.cwd = cwd if cwd
    env&.each { |k, v| process.environment[k.to_s] = v }

    output = ''
    r, w = IO.pipe

    begin
      process.io.stdout = w
      process.start
      w.close

      thread = Thread.new do
        loop do
          output << r.readpartial(16384)
        end
      rescue EOFError
      end

      process.wait
      thread.join
    ensure
      r.close
    end

    [process, output]
  end

  def check_output(*args)
    process, output = get_output(*args)
    raise SpawnError.new("Failed to execute: #{args}") unless process.exit_code == 0

    output
  end

  def call(cmd, env: nil, cwd: nil)
    process = ChildProcess.new(*cmd)
    process.io.inherit!
    process.cwd = cwd if cwd
    env&.each { |k, v| process.environment[k.to_s] = v }
    process.start
    process.wait
    process
  end

  def check_call(cmd, env: nil, cwd: nil)
    process = call(cmd, env: env, cwd: cwd)
    return if process.exit_code == 0

    raise SpawnError.new("Failed to execute: #{cmd}")
  end
end
