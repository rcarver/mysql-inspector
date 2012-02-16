class String
  # Strip left indentation from a string. Call this on a HEREDOC
  # string to unindent it.
  def unindented
    lines = self.split("\n")
    indent_level = (lines[0][/^(\s*)/, 1] || "").size
    lines.map { |line|
      line.sub(/^\s{#{indent_level}}/, '')
    }.join("\n") + "\n"
  end
end


