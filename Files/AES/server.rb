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

def decrypt(hexString)
  
  # Extracting data from hexString
  rawData = [hexString].pack('H*')
  cipherText = rawData.slice(0, rawData.length - 28)
  iv = rawData.slice(rawData.length - 28, 12)
  authTag = rawData.slice(rawData.length - 16, 16)
  
  # Initialize Cipher object
  cipher = OpenSSL::Cipher.new('aes-256-gcm')
  cipher.decrypt
  
  # Set cipher data
  cipher.iv = iv
  cipher.auth_tag = authTag
  cipher.key = KEY
  
  # Decrypt message
  plainText = cipher.update(cipherText) + cipher.final
  return plainText
end

def server_loop(client)
  while (lineIn = client.gets)
    lineIn = lineIn.chomp
    if(lineIn == "END")
      client.puts "END"
      next
    end
    plainText = decrypt(lineIn)
    puts "Received: => #{lineIn}"
    puts "Decrypted: => #{plainText}"
    client.puts plainText
  end
end

# Start server
sslServer = start_ssl_server()
loop do
  client = sslServer.accept
  Thread.new {server_loop(client)}
end