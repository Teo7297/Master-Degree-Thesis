# require 'socket'

def socketWrite(socket, header, message)
    socket.puts header << "\n" << message << "\nEOF"
    socket.flush
end

def socketRead(socket)
    res = ""
    while(line = socket.gets)
        if(line.chomp == "EOF")
            break
        end
        res << line
    end
    return res
end