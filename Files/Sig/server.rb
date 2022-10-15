require 'socket'               
require 'openssl'
require_relative '../socketIO'

PORT    = 44330
CERT    = open("cert.pem").read
P_KEY   = OpenSSL::PKey::RSA.new open("key.pem").read
DIGEST  = OpenSSL::Digest::SHA256.new

def server_loop(client)
  while (lineIn = client.gets)
    case lineIn.chomp

    when "HELLO"
      # Send this server's certificate to the client
      socketWrite(client, "CERTIFICATE", CERT)

    when "PUBKEY_ENCRYPTED_TEXT"
      # Receive a document encrypted with this server's public key
      encrypted_txt = socketRead(client).chop

      # Decrypt the document with this server's private key
      decrypted_txt = P_KEY.private_decrypt(encrypted_txt)
      
      # Sign the document with this server's private key
      signed_txt = P_KEY.sign(DIGEST, decrypted_txt)

      # Send the signed document to the client
      socketWrite(client, "SIGNATURE", signed_txt)
    
    when "END"
      # Client is terminating the connection
      # Reply with an ack message and close the socket
      client.puts "END"
      client.flush
      client.close
      break
    
    end
  end
end

# Server setup
server = TCPServer.open(PORT)
loop {
  client = server.accept
  Thread.new {server_loop(client)}
}
