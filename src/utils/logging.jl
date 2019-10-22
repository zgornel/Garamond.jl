"""
    build_logger(logging_stream, log_level)

Builds a logger using the stream `logging_stream`and `log_level` provided.

# Arguments
  * `logging_stream::String` is the output stream and can take the values:
  `"null"` logs to `/dev/null`, `"stdout"` (default) logs to standard output,
  `"/path/to/existing/file"` logs to an existing file and
  `"/path/to/non-existing/file"` creates the log file. If no valid option
  is provided, the default stream is the standard output.
  * `log_level::String` is the log level can take the values `"debug"`,
  `"info"`, `"error"` and defaults to `"info"` if no valid option is provided.
"""
function build_logger(logging_stream="stdout", log_level="info")
    # Quickly return null logger if the case
    logging_stream == "null" && return NullLogger()
    # Build stream logger
    logger_type = ConsoleLogger
    # Handle logging stream option
    if logging_stream == "stdout"
        _stream = stdout
    elseif isfile(logging_stream)
        _stream = logging_stream
    else
        # Create a default log file
        logdir = abspath(dirname(logging_stream))
        !isdir(logdir) && mkpath(logdir)
        _stream = joinpath(logdir, ".garamond.log")
    end
    # Logging
    if log_level == "debug"
        _level = Logging.Debug
    elseif log_level == "info"
        _level = Logging.Info
    elseif log_level == "error"
        _level = Logging.Error
    else
        @warn "Wrong logging level, defaulting to $DEFAULT_LOG_LEVEL."
        _level = DEFAULT_LOG_LEVEL
    end
    # Output logger
    return logger_type(_stream,
                       _level,
                       meta_formatter=garamond_log_formatter,
                       show_limited=true,
                       right_justify=0)
end



"""
    garamond_log_formatter(level, _module, group, id, file, line)

Garamond -specific log message formatter. Takes a fixed set of input arguments
and returns the color, prefix and suffix for the log message.
"""
function garamond_log_formatter(level, _module, group, id, file, line)
    color = :normal
    _file = split(file, "/")[end]  # take only the file name, not full path
    prefix = "[$(Dates.format(Dates.now(), "yyyy-mm-yy HH:MM:SS"))]" *
             "[$(uppercase(string(level)))][$_file:$line]"
    suffix=""
    return color, prefix, suffix  # fixed signature
end
