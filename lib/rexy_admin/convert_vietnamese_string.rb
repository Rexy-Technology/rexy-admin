  class ConvertVietnameseString
    prepend SimpleCommand

    def initialize(str)
      @str = str
    end

    def call
      rs = @str
      vietnamese_chars.each_with_index do |char_group, index|
        char_group.split('').each do |char|
          rs.gsub!(char, english_chars[index])
        end
      end
      rs
    end

    def vietnamese_chars
      @vietnamese_chars ||= [
        'ááàạảãâấầậẩẫăắằặẳẵ',
        'ÁÁÀẠẢÃÂẤẦẬẨẪĂẮẰẶẲẴ',
        'éèẹẻẽêếềệểễ',
        'ÉÈẸẺẼÊẾỀỆỂỄ',
        'óòọỏõôốồộổỗơớờợởỡ',
        'ÓÒỌỎÕÔỐỒỘỔỖƠỚỜỢỞỠ',
        'úùụủũưứừựửữ',
        'ÚÙỤỦŨƯỨỪỰỬỮ',
        'íìịỉĩ',
        'ÍÌỊỈĨİ',
        'đ',
        'Đ',
        'ýỳỵỷỹ',
        'ÝỲỴỶỸ'
      ]
    end

    def english_chars
      @english_chars ||= %w[a A e E o O u U i I d D y Y]
    end
  end
