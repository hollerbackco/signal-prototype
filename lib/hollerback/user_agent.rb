module Signal
  class UserAgent
    module Platform
      Windows       = /windows/i
      Mac           = /macintosh/i
      Linux         = /linux/i
      Wii           = /wii/i
      Playstation   = /playstation/i
      Ipad          = /ipad/i
      Ipod          = /ipod/i
      Iphone        = /iphone/i
      Android       = /android/i
      Blackberry    = /blackberry/i
      WindowsPhone  = /windows (ce|phone|mobile)( os)?/i
      Symbian       = /symbian(os)?/i
      Safari_iPad   = /mozilla\/5\.0 \((ipad)/i
      Safari_iPod   = /mozilla\/5\.0 \((ipod)/i
      Safari_iPhone = /mozilla\/5\.0 \((iphone)/i
    end

    def self.platform(string)
      case string
      when Platform::Android  then :android
      when Platform::Ipad     then :ipad
      when Platform::Ipod     then :ipod
      when Platform::Iphone   then :iphone
      when Platform::Safari_iPad then :ipad
      when Platform::Safari_iPhone then :iphone
      when Platform::Safari_iPod then :ipod
      else
        :other
      end
    end

    attr_accessor :source

    def initialize(source)
      @source = source
    end

    def ios?
      [:iphone, :ipad, :ipod].include?(platform)
    end

    def android?
      platform == :android
    end

    def platform
      @platform ||= self.class.platform(source)
    end
  end
end
