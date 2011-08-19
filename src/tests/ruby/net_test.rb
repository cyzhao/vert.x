# Copyright 2002-2011 the original author or authors.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not use
# this file except in compliance with the License. You may obtain a copy of the
# License at http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed
# under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
# CONDITIONS OF ANY KIND, either express or implied. See the License for the
# specific language governing permissions and limitations under the License.

require 'test/unit'
require 'core/nodex'
require 'core/net'
require 'utils'
include Net

class NetTest < Test::Unit::TestCase

  def setup
  end

  def teardown
  end

  def test_echo

    latch = Utils::Latch.new 1

    Nodex::go{
      server = Server.new { |socket|
        socket.data_handler { |data|
          socket.write_buffer(data)      # Just echo it back
        }
      }.listen(8080)

      client = Client.new.connect(8080, "localhost") { |socket|

        sends = 10
        size = 100

        sent = Buffer.create(0)
        received = Buffer.create(0)

        socket.data_handler { |data|

          received.append_buffer(data)

          if received.length == sends * size
            assert(Utils::buffers_equal(sent, received))

            server.close{
              client.close
              latch.countdown
            }
          end
        }

        socket.drain_handler{
          puts "drained\n"
        }

        socket.end_handler{
          puts "end\n"
        }

        (1..sends).each { |i|
          data = Utils::gen_buffer(size)
          sent.append_buffer(data)
          socket.write_buffer(data)
          puts "sent data"
        }
      }
    }

    assert(latch.await(5))
  end

  # Basically we just need to touch all methods, the real testing occurs in the Java tests
  def test_methods
    latch = Utils::Latch.new 1

    Nodex::go{
      server = Server.new

      server.ssl=true
      server.key_store_path="foo.jks"
      server.key_store_password="blah"
      server.trust_store_path="bar.jks"
      server.trust_store_password="blah"
      server.send_buffer_size=123123
      server.receive_buffer_size=218123
      server.keep_alive=true
      server.reuse_address=true
      server.so_linger = true
      server.traffic_class=123

      server.connect_handler{ |sock| }

      server.close

      client = Client.new

      client.ssl=true
      client.key_store_path="foo.jks"
      client.key_store_password="blah"
      client.trust_store_path="bar.jks"
      client.trust_store_password="blah"
      client.trust_all=true
      client.send_buffer_size=123123
      client.receive_buffer_size=218123
      client.keep_alive=true
      client.reuse_address=true
      client.so_linger = true
      client.traffic_class=123

      client.close

      latch.countdown
    }

    assert(latch.await(5))
  end


end