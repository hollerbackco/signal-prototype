class Xtea
  attr_reader :key, :key_o

  MASK = 0xFFFFFFFF
  DELTA = 0x9E3779B9

  def initialize(key=rand(2**128), n=32)
    @key_o = key
    @n = n

    if key.class == Bignum
      @key = [key & MASK, key>>32 & MASK, key>>64 & MASK, key>>96 & MASK]
    elsif key.class == String
      @key = []
      @key << key[0,8].hex
      @key << key[8,8].hex
      @key << key[16,8].hex
      @key << key[24,8].hex
    end
  end

  def decrypt(s)
    s.unpack('N*').each_slice(2).to_a.each {|v|
      sum = (DELTA*@n) & MASK
      @n.times {
        v[1] = (v[1] - (((v[0]<<4 ^ v[0]>>5) + v[0]) ^ (sum + @key[sum>>11 & 3]))) & MASK
        sum = (sum - DELTA) & MASK
        v[0] = (v[0] - (((v[1]<<4 ^ v[1]>>5) + v[1]) ^ (sum + @key[sum & 3]))) & MASK
      }
    }.flatten.pack('N*')
  end

  def encrypt(s)
    data = pad(s).unpack('L*')
    data = data.each_slice(2).to_a.each {|v|
      sum = 0
      @n.times {
        v[0] = (v[0] + (((v[1]<<4 ^ v[1]>>5) + v[1]) ^ (sum + @key[sum & 3]))) & MASK
        sum = (sum + DELTA) & MASK
        v[1] = (v[1] + (((v[0]<<4 ^ v[0]>>5) + v[0]) ^ (sum + @key[sum>>11 & 3]))) & MASK
      }
    }
    data.flatten.pack('L*')
  end

  def pad(s)
    padd = (8 - (s.bytesize % 8))
    s << ("\n" * padd) if padd
    s
  end
end
