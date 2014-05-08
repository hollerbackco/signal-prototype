class String
  def truncate(length, options = {})
    text = self.dup
    options[:omission] ||= "..."

    length_with_room_for_omission = length - options[:omission].mb_chars.length
    chars = text.mb_chars
    stop = options[:separator] ?
      (chars.rindex(options[:separator].mb_chars, length_with_room_for_omission) || length_with_room_for_omission) : length_with_room_for_omission

    (chars.length > length ? chars[0...stop] + options[:omission] : text).to_s
  end
end
