#!/usr/bin/ruby

require "socket"
require "thread"
require "openssl"

ITERATIONS = 5
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

def encrypt(message)

  # Initialize Cipher object
  cipher = OpenSSL::Cipher.new('aes-256-gcm')
  cipher.encrypt

  # Set cipher data
  iv = cipher.random_iv
  cipher.key = "00000000000000000000000000000000"

  # Encrypt message
  cipherText = cipher.update(message) + cipher.final
  hexString = (cipherText + iv + cipher.auth_tag).unpack('H*').first

  return hexString
end


# Open an SSL connection with the server
socket = start_ssl_client(HOST, PORT)

# Thread receiving server's response
t = Thread.new {
  begin
    while (lineIn = socket.gets)
      lineIn = lineIn.chomp
      if (lineIn == "END")
        puts "The server decrypted all messages successfully!"
        break
      end
      if(lineIn != MESSAGE)
        puts "ERROR: The server failed to decrypt a message"
        break
      end
    end
  end
}

# Sending messages to the server
for i in 1..ITERATIONS do
  socket.puts encrypt(MESSAGE)
end
socket.puts "END"

# Wait for the thread to receive all the messages
t.join
socket.close