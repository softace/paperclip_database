
module PaperclipDatabase
  # This function only appears in Rails >= 3.2.1, so define our own copy here
  def self.deconstantize(path)
    if path.respond_to? :deconstantize
      path.deconstantize
    else
      path.to_s[0...(path.rindex('::') || 0)]
    end
  end
end
