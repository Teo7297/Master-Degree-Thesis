require 'openssl'
require 'set'

cipherTextsSet = Set[]
iterations = 1000000

for i in 1..iterations

    # Initialize Cipher
    cipher = OpenSSL::Cipher.new('aes-256-gcm')
    cipher.encrypt

    # Set random IV
    cipher.random_iv
 
    # Set key
    key = "00000000000000000000000000000000"
    cipher.key = key

    # Encrypt message
    message = 'this is a test message'
    cipherText = cipher.update(message) + cipher.final

    
    # Add encrypted text to set
    cipherTextsSet.add(cipherText)

end


puts "==> " + iterations.to_s + " messages have been encrypted."
if cipherTextsSet.size() > 1
    puts "==> Succesfully generated " + cipherTextsSet.size().to_s + " different encrypted texts."
else
    puts "==> The encrypted texts are all identical."
end