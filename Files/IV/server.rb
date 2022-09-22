#!/usr/bin/ruby

require "socket"
require "openssl"
require "thread"

PORT = 44330
KEY  = "00000000000000000000000000000000"

def start_ssl_server()
  server = TCPServer.new(PORT)
  sslContext = OpenSSL::SSL::SSLContext.new
  sslContext.cert = OpenSSL::X509::Certificate.new(File.open("cert.pem"))
  sslContext.key = OpenSSL::PKey::RSA.new(File.open("key.pem"))
  sslServer = OpenSSL::SSL::SSLServer.new(server, sslContext)
  puts "Listening on port #{PORT}"
  return sslServer
end

def encrypt(message)

  # Initialize Cipher object
  cipher = OpenSSL::Cipher.new('aes-256-gcm')
  cipher.encrypt

  # Set cipher data
  iv = cipher.random_iv
  cipher.key = KEY

  # Encrypt message
  cipherText = cipher.update(message) + cipher.final
  hexString = (cipherText + iv + cipher.auth_tag).unpack('H*').first
  return hexString
end

def server_loop(client)
  count = 0
  while (lineIn = client.gets)
    lineIn = lineIn.chomp
    if(lineIn == "END")
      client.puts "END"
      next
    end
    hexString = encrypt(lineIn)
    client.puts hexString
    count += 1
  end
  puts "Received, encrypted and sent #{count.to_s} messages"
end

# Start server
sslServer = start_ssl_server()
loop do
  client = sslServer.accept
  Thread.new {server_loop(client)}
end