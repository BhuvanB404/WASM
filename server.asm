format ELF64 executable

    ;; frfom the chromium limux syscall table
SYS_write equ 1
SYS_exit equ 60

SYS_socket equ 41
SYS_accept equ 43
SYS_bind   equ 49
SYS_listen equ 50
SYS_close  equ 3

AF_INET equ 2
SOCK_STREAM equ 1
INADDR_ANY  equ 0

STDOUT equ 1
STDERR equ 2

EXIT_SUCCESS equ 0
EXIT_FAILURE equ 1

MAX_CONN    equ 5

macro write fd, buf, count
{
    mov rax, SYS_write
    mov rdi, fd
    mov rsi, buf
    mov rdx, count
    syscall
    }
    ;; socket int ;; int socket(int domain, int type,int protocol);

macro socket domain, type, protocol
{
    mov rax, SYS_socket
    mov rdi, domain
    mov rsi, type
    mov rdx, protocol
    syscall

    }


macro syscall1 number, a
{

   mov rax, number
   mov rdi, a
   syscall
}

macro syscall2 number, a, b
{

   mov rax, number
   mov rdi, a
   mov rsi, b

   syscall
}


macro syscall3 number, a, b, c
{

   mov rax, number
   mov rdi, a
   mov rsi, b
   mov rdx, c
   syscall
}

macro  bind sockfd, addr, addrlen
{

   syscall3 SYS_bind, sockfd, addr, addrlen

  ; mov rax, SYS_bind
   ;mov rdi, sockfd
   ;mov rsi, addr
   ;mov rdx, addrlen
   ;syscall
}


macro listen sockfd, backlog
{

 syscall2 SYS_listen, sockfd, backlog

}

macro accept sockfd, addr, addrlen
{

 syscall3 SYS_accept, sockfd, addr, addrlen

}

macro close fd
{

  syscall1 SYS_close, fd

}

macro exit code
    {
    mov rax, SYS_exit
    mov rdi, code
    syscall
    }

segment readable executable
entry main
main:
    write STDOUT, start, start_len
    write STDOUT, socket_trace_msg, socket_trace_msg_len
    socket AF_INET, SOCK_STREAM, 0 ; putting 0 because it will be tcp by default becuase single socket
    cmp rax,0
    jl error
    mov qword [sockfd], rax

    write STDOUT, bind_msg, bind_msg_len
    mov  word [servaddr.sin_family], AF_INET
    mov  word [servaddr.sin_port], 14619
    mov  dword [servaddr.sin_addr],  INADDR_ANY
    bind [sockfd], servaddr.sin_family, servaddr.size
    cmp rax,0
    jl error

    write STDOUT, listen_msg, listen_msg_len
    listen [sockfd], MAX_CONN

next_request:

    write STDOUT, accept_msg, accept_msg_len
    accept [sockfd], cliaddr.sin_family, cliaddr_len

    mov qword [connfd], rax

    write [connfd], response, response_len

   jmp next_request ;;this will run a infinite loop that will only stop when error is encpountered


    write STDOUT, ok_msg, ok_msg_len
    close [connfd]
    close [sockfd]
    exit 0

error:
    write STDERR, error_msg, error_msg_len
    close [connfd]
    close [sockfd]
    exit 1

segment readable writeable

struc servaddr_in
{

   .sin_family dw 0
   .sin_port   dw 0
   .sin_addr   dd 0
   .sin_zero   dq 0
   .size = $ - .sin_family

}

sockfd dq -1
connfd dq -1
servaddr servaddr_in
;size_of_servaddr_in = $ - servaddr.sin_family
cliaddr servaddr_in
cliaddr_len dd servaddr.size


response db "HTTP/1.1 200 OK", 13,10 ; 13 is /r
         db "Content-Type: text/html; charset=utf-8",13,10
         db "Connection: close",13,10
         db 13,10
         db "<h1>HELLO HUUMAN</h1>"
response_len = $ - response

hello db "HELLO HUUMANS", 10
hello_len =  $ - hello

start db "INFO: Starting server", 10
start_len = $ - start

socket_trace_msg db "INFO: creating socket", 10
socket_trace_msg_len = $ - socket_trace_msg

ok_msg db "INFO: all ok ", 10
ok_msg_len = $ - ok_msg

bind_msg db "INFO: binding thy socket.....", 10
bind_msg_len = $ - bind_msg

listen_msg db "INFO: listening on thy secrets ouuuuuu....", 10
listen_msg_len = $  - listen_msg

accept_msg db "INFO: waiting for client connections..... ", 10
accept_msg_len = $ - accept_msg


error_msg db "ERROR!", 10
error_msg_len = $ - error_msg
