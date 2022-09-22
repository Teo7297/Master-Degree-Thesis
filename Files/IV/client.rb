#!/usr/bin/ruby

require "socket"
require "thread"
require "openssl"
require "set"

ITERATIONS = 1000000
MESSAGE    = "Test message"
HOST       = "127.0.0.1"
PORT       = 44330


def start_ssl_client(host, port)
  socket = TCPSocket.new(host, port)
  ssl_socket = OpenSSL::SSL::SSLSocket.new(socket)
  ssl_socket.sync_close = true
  ssl_socket.connect
  return ssl_socket
end

def extract_cipher_text(hexString)
  rawData = [hexString].pack('H*')
  cipherText = rawData.slice(0, rawData.length - 28)
  return cipherText
end

def count_cipher_texts(rcv)
  cipher_texts = Set[]
  rcv.each{|elem| cipher_texts.add(extract_cipher_text(elem))}
  size = cipher_texts.size
  if size == rcv.size
    puts "The server sent #{size} different cipher texts"
  else
    puts "All the messages encrypted by the server are equal"
  end
end


# Open an SSL connection with the server
socket = start_ssl_client(HOST, PORT)

# Thread receiving server's response
t = Thread.new {
  begin
    received = Array.new
    while (lineIn = socket.gets)
      lineIn = lineIn.chomp
      if lineIn == "END"
        break
      end
      received.push(lineIn)
    end
    count_cipher_texts(received)
  end
}

# Sending messages to the server
for i in 1..ITERATIONS do
  socket.puts MESSAGE
end
socket.puts "END"

# Wait for the thread to receive all the messages
t.join
socket.close