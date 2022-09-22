require 'socket'
require 'openssl'
require_relative '../socketIO'

HOST     = '127.0.0.1'
PORT     = 44330
DOCUMENT = open("document.txt").read
DIGEST   = OpenSSL::Digest::SHA256.new

server_public_key = ""

# Connecting to the server and sending an HELLO message
socket = TCPSocket.open(HOST, PORT)
socket.puts "HELLO"
socket.flush

while (lineIn = socket.gets)
    case lineIn.chomp
    
    when "CERTIFICATE"
        # Receive the server's certificate
        certificate = OpenSSL::X509::Certificate.new socketRead(socket)

        # Extract the server's public key
        server_public_key = certificate.public_key
        
        # Encrypt a document with the public key
        encrypted_txt = server_public_key.public_encrypt(DOCUMENT)

        # Send the encrypted text to the server
        socketWrite(socket, "PUBKEY_ENCRYPTED_TEXT", encrypted_txt)
        
    when "SIGNATURE" 
        # Receive the plain text signed with the server's private key
        signed_document = socketRead(socket).chop

        # Verify the signature with the server's public key
        if server_public_key.verify(DIGEST, signed_document, DOCUMENT)
            puts "The server's signature is authentic"
        else
            puts "The server's signature is compromised"
        end
        
        # Alert the server that the connection is terminating
        socket.puts "END" 
        socket.flush

    when "END"
        # The server acknowledged the end of the connection, closing
        socket.close
        break  
    end
end


