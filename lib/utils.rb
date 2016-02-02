class SynchronizedHash
  def initialize
    @hash = Hash.new
    @lock = Mutex.new
  end

  def get(key)
    @lock.synchronize{
      @hash[key]
    }
  end

  def put(key, value)
    @lock.synchronize{
      @hash[key] = value
    }
  end
end


module Utils

  def Utils.synchronized_hash
    SynchronizedHash.new
  end

  def Utils.safe(value, default)
    value == nil ? default:value
  end

end