require 'timeout'

class Object
  def loop_with_timeout(timeout = 5)
    time = Time.now

    loop do
      if Time.now - time >= timeout
        raise TimeoutError, "Did not succeed within #{timeout} seconds"
      end

      yield
    end
  end
end
